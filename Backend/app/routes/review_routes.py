from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional
from app.database import SessionLocal
from app.models.review import Review
from app.models.user import User
from app.routes.auth_routes import get_current_user

router = APIRouter(prefix="/reviews", tags=["Reviews"])

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# ── Schemas ──────────────────────────────────────────────────────────

class ReviewCreate(BaseModel):
    product_id: int
    rating: float        # 0.5, 1.0, 1.5 ... 5.0
    comment: Optional[str] = None

class ReplyCreate(BaseModel):
    comment: str

# ── Helpers ──────────────────────────────────────────────────────────

def review_to_dict(r, db):
    user = db.query(User).filter(User.id == r.user_id).first()
    replies = db.query(Review).filter(Review.parent_id == r.id).order_by(Review.fecha.asc()).all()
    return {
        "id":         r.id,
        "product_id": r.product_id,
        "user_id":    r.user_id,
        "user_name":  user.nombre if user else "Usuario",
        "user_image": user.imagen if user else None,
        "rating":     r.rating,
        "comment":    r.comment or "",
        "parent_id":  r.parent_id,
        "fecha":      r.fecha.isoformat() if r.fecha else None,
        "replies":    [review_to_dict(reply, db) for reply in replies],
    }

# ── GET /reviews/{product_id} ────────────────────────────────────────

@router.get("/{product_id}")
def get_reviews(product_id: int, db: Session = Depends(get_db)):
    reviews = db.query(Review).filter(
        Review.product_id == product_id,
        Review.parent_id == None
    ).order_by(Review.fecha.desc()).all()

    return [review_to_dict(r, db) for r in reviews]

# ── POST /reviews/ ───────────────────────────────────────────────────

@router.post("/")
def create_review(
    data: ReviewCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Validar rating: 0.5 a 5.0, en pasos de 0.5
    if data.rating < 0.5 or data.rating > 5.0:
        raise HTTPException(status_code=400, detail="Rating debe ser entre 0.5 y 5.0")
    if (data.rating * 2) != int(data.rating * 2):
        raise HTTPException(status_code=400, detail="Rating debe ser en pasos de 0.5")

    # Sin restricción de 1 reseña — el usuario puede dejar varias

    review = Review(
        product_id=data.product_id,
        user_id=current_user.id,
        rating=data.rating,
        comment=data.comment,
    )
    db.add(review)
    db.commit()
    db.refresh(review)

    return review_to_dict(review, db)

# ── POST /reviews/{id}/reply ─────────────────────────────────────────

@router.post("/{review_id}/reply")
def reply_review(
    review_id: int,
    data: ReplyCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    parent = db.query(Review).filter(Review.id == review_id).first()
    if not parent:
        raise HTTPException(status_code=404, detail="Reseña no encontrada")

    reply = Review(
        product_id=parent.product_id,
        user_id=current_user.id,
        rating=0,
        comment=data.comment,
        parent_id=review_id,
    )
    db.add(reply)
    db.commit()
    db.refresh(reply)

    return review_to_dict(reply, db)

# ── DELETE /reviews/{id} ─────────────────────────────────────────────

@router.delete("/{review_id}")
def delete_review(
    review_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    review = db.query(Review).filter(Review.id == review_id).first()
    if not review:
        raise HTTPException(status_code=404, detail="Reseña no encontrada")

    if current_user.rol != "admin" and review.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="No tienes permiso")

    db.delete(review)
    db.commit()

    return {"message": "Reseña eliminada"}