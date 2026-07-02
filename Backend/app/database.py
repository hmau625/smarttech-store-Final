import os
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")
if not DATABASE_URL:
    raise RuntimeError(
        "Falta DATABASE_URL en las variables de entorno. "
        "Crea un archivo .env (ver .env.example) o configuralo en Railway."
    )

print(f"🔌 DATABASE_URL: {DATABASE_URL}")  # Debug

try:
    engine = create_engine(
        DATABASE_URL,
        echo=False,
        pool_pre_ping=True,  # Verifica conexión antes de usar
        pool_recycle=3600,   # Recicla conexiones cada hora
    )
    
    # Prueba la conexión
    with engine.connect() as conn:
        print("✅ Conexión a BD exitosa")
except Exception as e:
    print(f"❌ Error de conexión: {e}")
    raise

SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine
)

Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()