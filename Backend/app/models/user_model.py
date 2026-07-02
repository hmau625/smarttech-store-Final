from sqlalchemy import Column, Integer, String
from app.database import Base

class User(Base):
    __tablename__ = "usuarios"

    id = Column(Integer, primary_key=True, index=True)
    nombre = Column(String(100))
    correo = Column(String(100), unique=True, index=True)
    contraseña = Column(String(255))
    rol = Column(String(20))
    imagen = Column(String(255), nullable=True)