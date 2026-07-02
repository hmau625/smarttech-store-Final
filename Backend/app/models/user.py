from sqlalchemy import Column, Integer, String, Boolean, Enum
from app.database import Base

class User(Base):
    __tablename__ = "usuarios"

    id = Column(Integer, primary_key=True, index=True)
    nombre = Column(String(100), nullable=False)
    correo = Column(String(100), unique=True, nullable=False)
    contraseña = Column(String(255), nullable=False)
    rol = Column(Enum("admin", "cliente"), default="cliente")
    activo = Column(Boolean, default=True)
    imagen = Column(String(255), nullable=True)