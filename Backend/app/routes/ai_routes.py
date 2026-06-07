import os
import json
import httpx
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import List, Optional
from app.database import SessionLocal
from app.models.product import Product
from app.routes.auth_routes import get_current_user
from app.models.user import User

from app.models.review import Review
from sqlalchemy import func as sql_func

router = APIRouter(prefix="/ai", tags=["AI Assistant"])

# ═══════════════════════════════════════════════════════════════════
AI_PROVIDER = os.getenv("AI_PROVIDER", "groq")
AI_API_KEY  = os.getenv("AI_API_KEY")
# ═══════════════════════════════════════════════════════════════════

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

class ChatMessage(BaseModel):
    message: str
    history: Optional[List[dict]] = None

def build_product_context(db: Session) -> str:
    products = db.query(Product).filter(Product.stock > 0).all()
    catalog = []
    for p in products:
        specs_str = ""
        if p.specs:
            try:
                specs = p.specs if isinstance(p.specs, dict) else json.loads(p.specs)
                specs_str = ", ".join(f"{k}: {v}" for k, v in specs.items())
            except:
                specs_str = str(p.specs)
        # Reviews info
        review_data = db.query(
            sql_func.avg(Review.rating).label("avg"),
            sql_func.count(Review.id).label("cnt")
        ).filter(Review.product_id == p.id, Review.parent_id == None).first()

        avg_rating = round(review_data.avg, 1) if review_data.avg else 0
        num_reviews = review_data.cnt or 0
        review_str = f"Rating: {avg_rating}/5 ({num_reviews} reseñas)" if num_reviews > 0 else "Sin reseñas"

        catalog.append(
            f"- ID:{p.id} | {p.name} | {p.category} | {p.brand} | "
            f"${p.price:,.0f} COP | Stock:{p.stock} | {review_str} | Specs: {specs_str}"
        )
    return "\n".join(catalog)

SYSTEM_PROMPT = """Eres Nathalia, asistente virtual de SmartTech Store (tienda de tecnología y componentes de PC).

PERSONALIDAD:
- Habla como una asesora tech joven y natural, no fuerces jerga colombiana. Sé tú misma: amable, directa, con buen humor.
- Si el usuario te habla informal ("ñero", "parce", "q onda"), responde igual de casual. Si te habla formal, responde formal.
- Adapta tu tono al del usuario. Espejea su energía.

CAPACIDADES:
1. RECOMENDAR productos según presupuesto y uso (gaming, trabajo, estudio, diseño)
2. COMPARAR dos o más productos con pros/contras claros
3. ASESORAR en compatibilidad de componentes y relación calidad/precio
4. ARMAR builds completos de PC según presupuesto

REGLAS:
- SIEMPRE recomienda del catálogo real de abajo. No inventes productos.
- Precios en pesos colombianos. Ej: $2.850.000 COP
- Si no hay algo que sirva en el catálogo, dilo honestamente
- Si preguntan algo fuera de tech, diles amablemente que solo asesoras en tecnología
- Respuestas cortas y útiles. No te extiendas innecesariamente.
- Entiende mensajes con errores de escritura, abreviaciones, spanglish. El usuario puede escribir "q gpu me recomeinads" y tú entiendes "qué GPU me recomiendas".
- Usa emojis solo cuando fluyan natural, no los fuerces
- TOMA EN CUENTA LAS RESEÑAS: si un producto tiene buenas reseñas (4+), menciónalo. Si tiene malas, advierte.
- Cuando recomiendes un producto, SIEMPRE incluye al final del nombre el formato [ID:numero]. Ejemplo: "Te recomiendo la NVIDIA RTX 4090 24GB [ID:3] por $7.800.000 COP". Esto permite que el usuario lo agregue al carrito directo.
- Si el usuario dice "agrégalo", "sí", "dale", "añádelo" después de una recomendación, responde con el texto EXACTO: "CART_ADD:ID" donde ID es el número del producto. Ejemplo: "CART_ADD:3". Puedes añadir texto después.
- Si el usuario te pregunta por un producto específico, da detalles de specs, precio, reviews y opinión honesta

CATÁLOGO ACTUAL DE LA TIENDA:
{catalog}
"""

async def call_groq(system: str, messages: list) -> str:
    msgs = [{"role": "system", "content": system}] + messages
    async with httpx.AsyncClient(timeout=30) as client:
        res = await client.post(
            "https://api.groq.com/openai/v1/chat/completions",
            headers={
                "Authorization": f"Bearer {AI_API_KEY}",
                "Content-Type": "application/json",
            },
            json={
                "model": "llama-3.3-70b-versatile",
                "max_tokens": 1024,
                "messages": msgs,
            },
        )
    if res.status_code != 200:
        print(f"GROQ ERROR {res.status_code}: {res.text}")
        raise HTTPException(status_code=502, detail=f"Error IA: {res.text}")
    data = res.json()
    return data["choices"][0]["message"]["content"]

async def call_gemini(system: str, messages: list) -> str:
    contents = []
    for m in messages:
        role = "user" if m["role"] == "user" else "model"
        contents.append({"role": role, "parts": [{"text": m["content"]}]})

    async with httpx.AsyncClient(timeout=30) as client:
        res = await client.post(
            f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-lite:generateContent?key={AI_API_KEY}",
            headers={"Content-Type": "application/json"},
            json={
                "system_instruction": {"parts": [{"text": system}]},
                "contents": contents,
            },
        )
    if res.status_code != 200:
        print(f"GEMINI ERROR {res.status_code}: {res.text}")
        raise HTTPException(status_code=502, detail=f"Error IA: {res.text}")
    data = res.json()
    return data["candidates"][0]["content"]["parts"][0]["text"]

@router.post("/chat")
async def chat(
    data: ChatMessage,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    catalog = build_product_context(db)
    system = SYSTEM_PROMPT.replace("{catalog}", catalog)

    messages = []
    if data.history:
        for h in data.history:
            if h.get("role") in ("user", "assistant"):
                messages.append({
                    "role": h["role"] if h["role"] == "user" else "assistant",
                    "content": h["content"]
                })

    messages.append({"role": "user", "content": data.message})

    response = await call_groq(system, messages) if AI_PROVIDER == "groq" else await call_gemini(system, messages)

    return {
        "response": response,
        "user_name": current_user.nombre,
    }