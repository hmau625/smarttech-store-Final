# 🛒 SmartTech Store

**SmartTech Store** es una tienda electrónica desarrollada con **arquitectura de 3 capas**, que permite a los usuarios explorar, seleccionar y comprar productos tecnológicos. Incluye un sistema de recomendaciones con IA que sugiere productos o configuraciones de PC según el presupuesto del usuario.

## 🏗 Arquitectura

- **Frontend:** Flutter  
- **Backend:** FastAPI (Python)  
- **Base de datos:** MySQL  

Esta estructura permite escalabilidad, separación de responsabilidades y facilidad de mantenimiento.

## ⚡ Funcionalidades principales

- Visualización de productos electrónicos por categorías.  
- Búsqueda y filtrado de productos.  
- Sistema de recomendación basado en IA.  
- Gestión de usuarios y autenticación.  
- Carrito de compras y resumen de pedidos.  
- Conexión segura con la base de datos MySQL.  

## 💻 Cómo ejecutar

### 1️⃣ Backend
1. Ir al directorio del backend:
```bash
cd backend
Instalar dependencias:
pip install -r requirements.txt
Ejecutar el servidor:
uvicorn app.main:app --reload

El backend estará disponible en http://127.0.0.1:8000.

2️⃣ Frontend
Ir al directorio del frontend:
cd frontend
Instalar dependencias:
flutter pub get
Ejecutar la aplicación:
<<<<<<< HEAD
flutter run
=======
flutter run
>>>>>>> 0b32588 (Actualizo del README)
