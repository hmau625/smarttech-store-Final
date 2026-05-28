# schemas/checkout.py

from pydantic import BaseModel, Field
from typing import Optional

class CheckoutRequest(BaseModel):
    token: str
    metodo_pago: str

    nombre: str = Field(min_length=3)
    apellido: str = Field(min_length=3)

    tipo_documento: str
    documento: str

    pais: str
    departamento: str
    ciudad: str
    direccion: str = Field(min_length=5)

    fecha_entrega: str

    referencia_pago: Optional[str] = None
    numero_contacto: str