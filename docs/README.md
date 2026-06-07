<div align="center">

# ⚡ SmartTech Store

### *Tecnología inteligente, al alcance de todos.*

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com)
[![MySQL](https://img.shields.io/badge/MySQL-4479A1?style=for-the-badge&logo=mysql&logoColor=white)](https://www.mysql.com)
[![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://www.python.org)
[![Groq](https://img.shields.io/badge/Groq_AI-F55036?style=for-the-badge&logo=groq&logoColor=white)](https://groq.com)
[![JWT](https://img.shields.io/badge/JWT-000000?style=for-the-badge&logo=jsonwebtokens&logoColor=white)](https://jwt.io)

<br/>

> **SmartTech Store** no es solo una tienda. Es una plataforma de comercio electrónico empresarial construida con tecnología de punta, diseñada para escalar, segura por defecto y potenciada por inteligencia artificial real.

</div>

---

## 📖 Tabla de contenidos

- [¿Qué es SmartTech Store?](#-qué-es-smarttech-store)
- [Arquitectura del sistema](#-arquitectura-del-sistema)
- [Funcionalidades](#-funcionalidades)
- [Nathalia — Asistente IA](#-nathalia--asistente-ia)
- [Autenticación y seguridad](#-autenticación-y-seguridad)
- [API Reference](#-api-reference)
- [Instalación](#-instalación-y-puesta-en-marcha)
- [Estructura del proyecto](#-estructura-del-proyecto)
- [Licencia](#-licencia)

---

## 🌐 ¿Qué es SmartTech Store?

**SmartTech Store** es una plataforma de comercio electrónico especializada en productos tecnológicos, construida sobre una arquitectura moderna de 3 capas con separación total de responsabilidades. Cada decisión técnica fue tomada pensando en rendimiento, seguridad y escalabilidad real.

La plataforma integra un asistente de inteligencia artificial propio — **Nathalia** — capaz de asesorar a los usuarios en tiempo real, recomendar builds completos de PC, comparar componentes y agregar productos al carrito directamente desde una conversación natural. No es un chatbot genérico. Nathalia conoce el catálogo completo, los precios actuales y las reseñas de cada producto.

Más que una tienda, SmartTech Store es un ecosistema digital pensado para crecer.

---

## 🏗️ Arquitectura del sistema

```
┌─────────────────────────────────────────────────────────────┐
│                        CLIENTE                              │
│              Flutter (Web / Mobile / Desktop)               │
└─────────────────────────┬───────────────────────────────────┘
                          │  HTTP REST + JWT
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                    BACKEND — FastAPI                        │
│                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌────────────────────┐  │
│  │   Routes    │  │  Services   │  │      Models        │  │
│  │  (Endpoints)│→ │ (Lógica de  │→ │   (SQLAlchemy      │  │
│  │             │  │  negocio)   │  │      ORM)          │  │
│  └─────────────┘  └─────────────┘  └────────────────────┘  │
│                          │                                  │
│                    ┌─────▼──────┐                           │
│                    │  Groq API  │ ← LLaMA 3.3 70B           │
│                    └────────────┘                           │
└─────────────────────────┬───────────────────────────────────┘
                          │  SQLAlchemy ORM
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                   BASE DE DATOS — MySQL                     │
│  usuarios · productos · pedidos · cart · favoritos · reviews│
└─────────────────────────────────────────────────────────────┘
```

| Capa | Tecnología | Rol |
|------|-----------|-----|
| 🎨 Presentación | Flutter | Interfaz multiplataforma (Web, Android, iOS, Desktop) |
| ⚙️ Lógica de negocio | FastAPI (Python) | API REST de alto rendimiento con autenticación JWT |
| 🗄️ Persistencia | MySQL + SQLAlchemy | Base de datos relacional con ORM y migraciones |
| 🤖 Inteligencia Artificial | Groq + LLaMA 3.3 70B | Asistente conversacional con contexto del catálogo |

---

## 🚀 Funcionalidades

### Para el usuario final
- 🛍️ Catálogo de productos con filtros por categoría, marca y precio
- 🔍 Búsqueda avanzada en tiempo real
- 🛒 Carrito de compras con gestión de cantidades
- 💳 Flujo de checkout completo con resumen de orden
- ⭐ Sistema de reseñas y calificaciones anidadas por producto
- ❤️ Lista de favoritos personalizada
- 👤 Perfil de usuario con gestión de datos e imagen
- 🤖 Chat con Nathalia, asistente IA de la tienda

### Para el administrador
- 📦 Gestión completa de inventario y productos (CRUD)
- 📋 Administración y seguimiento de órdenes en tiempo real
- 📊 Panel de control con métricas del negocio
- 🔐 Control de acceso por roles (`cliente` / `admin`)
- 📧 Sistema de notificaciones por correo electrónico

---

## 🤖 Nathalia — Asistente IA

Nathalia es el corazón diferenciador de SmartTech Store. No es un chatbot pregrabado — es un agente conversacional impulsado por **LLaMA 3.3 70B** ejecutado sobre la infraestructura de [Groq](https://groq.com), una de las plataformas de inferencia más rápidas del mundo.

### ¿Cómo funciona por dentro?

```
Usuario escribe mensaje
        │
        ▼
Flutter envía → POST /ai/chat
  { message, history[] }
        │
        ▼
Backend construye contexto dinámico:
  · Consulta productos en stock desde MySQL
  · Incluye precio, stock, specs y rating promedio de reseñas
  · Inyecta el catálogo completo en el system prompt
        │
        ▼
Se envía a Groq API:
  modelo: llama-3.3-70b-versatile
  historial completo de conversación
  system prompt con personalidad + catálogo
        │
        ▼
Nathalia responde con:
  · Recomendación con ID del producto → [ID:3]
  · O comando de carrito → CART_ADD:3
        │
        ▼
Flutter interpreta la respuesta:
  · Muestra el mensaje
  · Si detecta CART_ADD:X → agrega automáticamente al carrito
```

### Capacidades de Nathalia
| Capacidad | Descripción |
|-----------|-------------|
| 🎯 Recomendación | Sugiere productos por presupuesto, uso y preferencias |
| 🖥️ Builds de PC | Arma configuraciones completas compatibles entre sí |
| ⚖️ Comparación | Compara componentes con análisis de pros y contras |
| 🛒 Carrito directo | Agrega productos al carrito desde el chat |
| ⭐ Contexto de reseñas | Considera el rating real de cada producto al recomendar |
| 🌐 Lenguaje natural | Entiende errores de escritura, spanglish y lenguaje informal |

---

## 🔐 Autenticación y seguridad

SmartTech Store implementa un sistema de autenticación basado en **JSON Web Tokens (JWT)** con control de acceso por roles.

### Flujo de autenticación

```
1. Usuario envía credenciales → POST /auth/login
         │
         ▼
2. Backend valida correo y contraseña (bcrypt hash)
         │
         ▼
3. Si es válido → genera JWT firmado con SECRET_KEY
   payload: { sub: correo, role: "cliente" | "admin" }
         │
         ▼
4. Frontend almacena el token
         │
         ▼
5. Cada request protegido incluye:
   Authorization: Bearer <token>
         │
         ▼
6. Backend decodifica y valida el token en cada endpoint
   → Si es inválido o expirado → 401 Unauthorized
   → Si el rol no tiene permiso → 403 Forbidden
```

### Rutas protegidas por rol
| Ruta | Rol requerido |
|------|--------------|
| `/admin/*` | admin |
| `/ai/chat` | cliente / admin |
| `/checkout/*` | cliente / admin |
| `/favorites/*` | cliente / admin |
| `/products/` GET | público |

---

## 📡 API Reference

Base URL: `http://127.0.0.1:8000`  
Documentación interactiva: `http://127.0.0.1:8000/docs`

### Auth
| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `POST` | `/auth/register` | Registro de nuevo usuario |
| `POST` | `/auth/login` | Login y obtención de token JWT |
| `GET` | `/auth/me` | Datos del usuario autenticado |

### Productos
| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `GET` | `/products/` | Listar todos los productos |
| `GET` | `/products/{id}` | Detalle de un producto |
| `POST` | `/products/` | Crear producto (admin) |
| `PUT` | `/products/{id}` | Actualizar producto (admin) |
| `DELETE` | `/products/{id}` | Eliminar producto (admin) |

### Carrito
| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `GET` | `/cart/` | Ver carrito actual |
| `POST` | `/cart/add` | Agregar producto al carrito |
| `DELETE` | `/cart/remove/{id}` | Quitar producto del carrito |

### Pedidos
| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `POST` | `/checkout/` | Crear pedido desde el carrito |
| `GET` | `/orders/` | Historial de pedidos del usuario |
| `GET` | `/admin/orders` | Todos los pedidos (admin) |

### Reseñas
| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `GET` | `/reviews/{product_id}` | Reseñas de un producto |
| `POST` | `/reviews/` | Crear reseña |
| `POST` | `/reviews/reply` | Responder una reseña |

### IA
| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `POST` | `/ai/chat` | Enviar mensaje a Nathalia |

---

## 🛠️ Instalación y puesta en marcha

### Requisitos previos
- Python **3.11+**
- Flutter **SDK 3.x**
- MySQL **8.0+**
- Git

### 1️⃣ Clonar el repositorio

```bash
git clone https://github.com/hmau625/smarttech-store-Final.git
cd smarttech-store-Final
```

### 2️⃣ Configurar el Backend

```bash
cd Backend

# Crear y activar entorno virtual
python -m venv venv
venv\Scripts\activate        # Windows
# source venv/bin/activate   # Linux / Mac

# Instalar dependencias
pip install -r requirements.txt
```

Crear el archivo `.env` dentro de `Backend/`:

```dotenv
PORT=8000
DB_HOST=localhost
DB_USER=tu_usuario
DB_PASSWORD=tu_contraseña
DB_NAME=smarttech_store
AI_PROVIDER=groq
AI_API_KEY=tu_api_key_de_groq
```

> 🔑 Obtén tu API Key gratuita en [console.groq.com](https://console.groq.com)

```bash
uvicorn app.main:app --reload
```

### 3️⃣ Configurar la base de datos

```bash
mysql -u root -p smarttech_store < database/smarttech_store.sql
```

### 4️⃣ Configurar el Frontend

```bash
cd Frontend
flutter pub get
flutter run
```

---

## 📁 Estructura del proyecto

```
SmartTech Store/
├── Backend/
│   ├── app/
│   │   ├── models/          # Modelos ORM (SQLAlchemy)
│   │   ├── routes/          # Endpoints REST de la API
│   │   ├── schemas/         # Validación de datos (Pydantic)
│   │   ├── services/        # Lógica de negocio y servicios externos
│   │   ├── database.py      # Configuración de conexión MySQL
│   │   └── main.py          # Punto de entrada + middlewares
│   ├── static/              # Imágenes de productos y usuarios
│   └── requirements.txt
│
├── Frontend/
│   ├── lib/
│   │   ├── models/          # Modelos de datos Flutter
│   │   ├── screens/         # Pantallas de la aplicación
│   │   └── services/        # Servicios HTTP y lógica de cliente
│   └── pubspec.yaml
│
├── database/
│   └── smarttech_store.sql
│
├── .gitignore
└── README.md
```

---

## 📄 Licencia

Este proyecto fue desarrollado con fines académicos y de portafolio profesional.  
© 2026 **SmartTech Store** — Todos los derechos reservados.

---

<div align="center">

*Construido con pasión, caffeine y muchas horas de código.* ☕

**⭐ Si te gustó el proyecto, déjale una estrella en GitHub.**

</div>
