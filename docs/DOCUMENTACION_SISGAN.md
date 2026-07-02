# Documentación Global de SISGAN PRO

SISGAN PRO es un sistema integral de gestión ganadera diseñado para optimizar el control de inventario, producción lechera, procesos reproductivos y administración de hatos.

## 1. Arquitectura del Sistema

El sistema utiliza una arquitectura **Monolítica Ligera**:
- **Backend**: Node.js con Express para la API REST.
- **Base de Datos**: SQLite3 (archivo local en `data/sisgan_pro.db`) para persistencia rápida y sin dependencias externas.
- **Frontend**: Single Page Application (SPA) construida con HTML5, CSS3 vanila y JavaScript nativo.
- **OCR**: Integración con `Tesseract.js` para reconocimiento de texto en fotos (pesajes).

---

## 2. Módulos Principales

### 🐄 Gestión de Animales (Fichas)
Módulo central para el registro y consulta de animales.
- **Ficha Compacta**: Visualización detallada de identificación, origen, salud y estadísticas.
- **Buscador Inteligente**: Filtros por número, nombre, sexo, lote, tipo y estatus.
- **Historiales**: Acceso directo desde la ficha a partos, producciones de leche y servicios del animal.

### 🥛 Control Lechero
Gestión diaria de pesajes de leche.
- **Sesiones de Pesaje**: Registro por fecha y turno (Mañana/Tarde).
- **Modo Borrador**: Autoguardado local para evitar pérdida de datos durante la jornada.
- **Validación**: Filtros automáticos que solo muestran vacas aptas para ordeño (vivas y en lote de ordeño).

### 🐣 Registro de Partos
Control de nacimientos y eventos reproductivos.
- **Automatización**: Al registrar un parto, el sistema actualiza automáticamente a la madre (Lote: Ordeño, Estatus: En Lactancia) y crea la ficha de la cría.
- **Trazabilidad**: Vinculación permanente entre madre, padre y cría.

### 🩺 Reproducción y Servicios
Gestión del ciclo reproductivo.
- **Servicios**: Registro de Montas Naturales, Inseminación Artificial y Transferencia de Embriones.
- **Palpaciones**: Diagnóstico técnico con actualización automática del estatus reproductivo ("Preñada" / "Vacía") y cálculo de fecha estimada de parto.

### 🧀 Producción de Queso
Control de transformación de la materia prima.
- Registro de peso y equipo de trabajo por turno.

### 📉 Bajas del Hato
Gestión de salidas de animales del sistema.
- Categorización de bajas: Muerte, Venta, Robo, Sacrificio, etc.
- Impacto automático en el inventario activo.

---

## 3. Lógica Avanzada y Automatización

SISGAN PRO destaca por reducir la carga manual mediante disparadores lógicos:

1.  **Transiciones Automáticas de Parto**:
    - **Madre**: `lote` ➔ 'Ordeño', `estatus_repro` ➔ 'En Lactancia'.
    - **Cría**: Creación automática en `lote` ➔ 'Crías' con nombre sugerido basado en la madre.
2.  **Gestión Reproductiva**:
    - Las palpaciones positivas ("Preñada") bloquean automáticamente la fecha estimada de parto en el Dashboard.
    - Los diagnósticos negativos limpian las fechas estimadas para evitar confusión.
3.  **Seguridad y Roles**:
    - Sistema de login con contraseñas hasheadas (SHA-256).
    - Niveles de acceso diferenciados entre Administradores y Trabajadores.

---

## 4. Detalles Técnicos (Referencia)

### Base de Datos (`animales`)
Columnas clave:
- `numero`: Identificador único (Arete).
- `lote`: Categorización por grupos (Ordeño, Horro, Crías, etc.).
- `estatus_repro`: Estado actual (Vacía, Preñada, En Lactancia).
- `fecha_parto_est`: Utilizada para las alertas del Dashboard.

### Rutas de API Clave
- `GET /api/dashboard`: Estadísticas rápidas y próximos eventos.
- `POST /api/registrar-parto`: Disparador de lógica de crías y madres.
- `POST /api/registrar-palpacion`: Actualizador de estatus reproductivo.

---
*Documento generado para SISGAN PRO V5*
