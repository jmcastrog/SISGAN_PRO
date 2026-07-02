# Interfaces del Sistema SISGAN PRO

---

## 1. VCL (SisganDBViewer) — Aplicación de Escritorio

**Puerto/Localización:** Ejecutable standalone (`SisganDBViewer.exe`)  
**Tecnología:** Delphi VCL, FireDAC SQLite  
**Propósito:** Visor/editor de base de datos en modo tabla, control del servicio Windows.

### Funcionalidades

#### 1.1 Conexión a Base de Datos
- Se conecta automáticamente al iniciar a `sisgan_pro.db` (SQLite con WAL).
- Busca la BD primero junto al EXE, luego en `D:\Proyectos\SISGAN_PRO\data\`.
- Crea tablas CAT (CAT_TIPO, CAT_LOTE, CAT_ESTATUS, CAT_Propietario) si no existen, poblándolas desde datos huérfanos en `animales`.

#### 1.2 Navegación de Tablas
- `cbTables` — ComboBox que lista todas las tablas de la BD (obtenidas de `sqlite_master`).
- Al seleccionar una tabla, carga sus datos con SQL específico según la tabla (joins para `partos`, `servicios`, `control_leche`, `bajas`, `palpaciones`).
- Las tablas CAT muestran una columna calculada `cantidad` (registros en `animales` que referencian ese valor).

#### 1.3 Grid de Datos (DBGrid1)
- Edición inline directamente en la celda.
- PickList desplegable en columnas `tipo`, `lote`, `estatus`, `propietario` con valores de las tablas CAT.
- `DBGrid1TitleClick` — Click en encabezado ordena asc/desc.
- Ajuste automático de ancho de columnas.
- Fechas en formato `dd-mm-yyyy`.

#### 1.4 CRUD de Registros
- **Agregar** (`btnAdd`): Agrega un registro vacío al final.
- **Eliminar** (`btnDelete`): Confirma con mensaje, elimina y activa Deshacer por 15 segundos.
- **Deshacer** (`btnUndo`): Revierte la última eliminación (ventana de 15s por `TimerUndo`).
- **Aplicar Cambios** (`btnRefresh`): Persiste todas las ediciones pendientes a la BD (usa `ApplyUpdates` + `CommitUpdates`).

#### 1.5 Filtro Global de Texto
- `edtFilter` — Búsqueda libre tipo "type-ahead" que filtra en todos los campos (string, integer, float, date, memo) con `LIKE '%texto%'`.

#### 1.6 Filtros Multi-Select (4 Slots Dinámicos)
- Cuatro botones con checklist popup que cambian según la tabla seleccionada.
- `btnFilterEstatus`, `btnFilterTipo`, `btnFilterLote`, `btnFilterPropietario`.
- Cada slot se etiqueta y puebla según la tabla (ej. en `animales`: Estatus/Tipo/Lote/Propietario; en `partos`: Estado/Propietario/Estatus/Sexo).
- Lógica AND entre filtros y con el filtro global.
- Para `animales.lote`, solo muestra valores con `estatus = 'Vivos'`.

#### 1.7 Panel de Columnas (Personalización)
- `btnTogglePanel` — Muestra/oculta panel lateral izquierdo.
- `chkColumns` — Checklist con todas las columnas de la tabla.
  - Check/Uncheck: muestra/oculta la columna.
  - Drag & Drop: reordena columnas.
- Configuración persistida por tabla en `ViewerSettings.ini`.

#### 1.8 Exportar a PDF
- `btnExportPDF` — Genera un HTML con las columnas visibles y lo abre en el navegador predeterminado para imprimir/guardar como PDF.

#### 1.9 Control del Servicio Windows (ServicioSisgan)
- `btnToggleService` — Inicia/Detiene el servicio `ServicioSisgan` (Horse API en puerto 5001) con elevación de permisos (`runas`).
- `lblStatus` — Muestra "Servicio: ACTIVO" (verde) o "Servicio: DETENIDO" (rojo).
- `TimerStatus` (3s) — Sondea el estado del servicio cada 3 segundos.
- `ServicioActivo()` — Consulta el SCM de Windows para estado real.

#### 1.10 Salida
- `btnCloseApp` ("SALIR") — Cierra la aplicación directamente (sin minimizar a bandeja).

#### 1.11 Persistencia
- `ViewerSettings.ini` guarda por tabla: orden de columnas y visibilidad.

#### 1.12 Tablas Reconocidas (con SQL personalizado)

| Tabla | FK a `animales` | Filtros | Columnas calculadas |
|---|---|---|---|
| `animales` | — | estatus, tipo, lote, propietario | Edad |
| `partos` | num_madre | estado, propietario, estatus, sexo | propietario, estatus |
| `servicios` | numero | tipo, toro, propietario, estatus | propietario, estatus |
| `palpaciones` | numero | diagnostico, propietario, estatus, tecnico | propietario, estatus |
| `control_leche` | numero_animal | turno, propietario, estatus | propietario, estatus |
| `bajas` | numero_animal | tipo_baja, propietario, estatus, causa | propietario, estatus |
| `queso` | — | equipo | — |
| `CAT_TIPO` | — | — | cantidad |
| `CAT_LOTE` | — | — | cantidad |
| `CAT_ESTATUS` | — | — | cantidad |
| `CAT_Propietario` | — | — | cantidad |

---

## 2. Web Dashboard (Node.js :5000) — SPA

**URL:** `http://localhost:5000/`  
**Tecnología:** HTML + CSS + JavaScript vanilla, Express.js  
**Propósito:** Dashboard visual y gestión completa del hato desde el navegador.

### Funcionalidades

#### 2.1 Autenticación
- Pantalla de login con usuario/contraseña.
- Token almacenado en `localStorage`.
- Usuario por defecto: `admin` / `admin123`.

#### 2.2 Navegación (Sidebar)
| Sección | Descripción |
|---|---|
| **Dashboard** | Panel de inicio con resumen general |
| **Animales** | Fichas, buscador, listado completo, alta de nuevos animales |
| **Control Lechero** | Registro diario de ordeño por turno (mañana/tarde) |
| **Producción Queso** | Registro de producción de queso con foto y EXIF |
| **Partos** | Registro de partos con asignación automática de número y ficha |
| **Reproducción** | Servicios (monta/IA) y palpaciones |
| **Bajas del Hato** | Registro de muertes, ventas y sacrificios |
| **Administración** | Edición tipo Excel de tablas (animales, partos, etc.) |
| **Configuración** | Reglas de categorización dinámicas |

#### 2.3 Dashboard (sec_inicio)
- **Tarjeta Animales**: Total de animales (angosta, una línea).
- **Tarjeta Producción Últimos 7 Días**: Fila de títulos (Total + días) arriba, datos abajo con leche (lts), queso (kg), y relación lts/kg.
  - API: `GET /api/dashboard` → `{animales, produccion: {diario, queso_total}, proximos, lotes, propietarios}`.
- **Composición del Hato**: Desglose por Lote y por Propietario con cantidades y porcentajes.
- **Próximos Partos**: Tabla con madre y fecha estimada.
- **URL de Acceso Externo**: (stub, actualmente no implementado).

#### 2.4 Animales / Fichas (sec_fichas)
- **Buscador Rápido**: Input tipo type-ahead que busca por número o nombre (top 15 resultados). Cada resultado tiene botón "Ficha" que abre detalle completo.
- **Listado Completo**: Tabla con filtros por Sexo, Estatus, Lote, Tipo. Cada fila tiene botón "Ficha".
- **Nuevo Animal**: Formulario con número (auto-generado con año + correlativo), nombre, sexo, tipo.
- **Ficha Detallada**: Formulario completo con:
  - Fotos (animal y hierro) con previsualización y upload.
  - Campos editables: nombre, raza, lote, tipo, sexo, estatus_repro, estatus, fecha_nac, peso_nacer, madre, padre, propietario, comentarios.
  - Resumen: total partos, total leche, promedio, días pesados.
  - Historial de Partos (tabla).
  - Últimos Pesajes (tabla).
  - Acciones rápidas: +PARTO, +PESAJE.
  - API: `GET /api/detalle/:numero`, `POST /api/registrar-animal`.

#### 2.5 Control Lechero (sec_leche)
- Selección de fecha y turno (MAÑANA / TARDE).
- Búsqueda de animal (filtrado a lote="ordeño" y estatus=Vivos).
- Ingreso de peso bruto, peso del tobo, cálculo automático de peso neto.
- Soporte para cámara (OCR) para capturar peso desde foto.
- Lista de entradas con total acumulado.
- Borrador persistido en servidor (archivo JSON) para no perder datos.
- `GRABAR EN BD`: Confirma todas las entradas en lote.
- API: `POST /api/borrador-leche`, `POST /api/confirmar-leche`.

#### 2.6 Producción Queso (sec_queso)
- Fecha auto-detectada desde metadatos EXIF de la foto.
- Turno (MAÑANA/TARDE), peso total, leche usada.
- Foto del equipo de queso con previsualización.
- Detección de duplicados (misma fecha + equipo).
- API: `POST /api/registrar-queso`.

#### 2.7 Partos (sec_partos)
- **Nuevo Parto**: Búsqueda de madre, selección de sexo de cría, padre, estado (Vivo/Muerto), peso al nacer, tipo de evento (Parto/Aborto).
  - Asignación automática de número a la cría (año + correlativo) y nombre sugerido ("H de [Madre]" o "M de [Madre]").
  - Si es Aborto → fuerza estado Muerto.
  - Al registrar: crea ficha para la cría (si nació viva) y actualiza madre a "En Lactancia"/"Vacas en Ordeño".
- **Partos Recientes**: Lista de últimos 50 partos con códigos de color por estado.
- API: `POST /api/registrar-parto`.

#### 2.8 Reproducción / Servicios (sec_servicios)
- **Monta/Semen**: Registro de servicio (fecha, hembra, tipo, toro).
- **Palpaciones**: Registro (fecha, hembra, diagnóstico, fecha est. de parto si está preñada, técnico, observaciones).
  - Al registrar: actualiza `estatus_repro` del animal (Preñada/Vacía) y `fecha_parto_est`.
- **Historial**: Vista unificada (servicios + palpaciones) ordenada por fecha descendente.
- API: `POST /api/registrar-servicio`, `POST /api/registrar-palpacion`.

#### 2.9 Bajas del Hato (sec_bajas)
- **Registrar Baja**: Fecha, búsqueda de animal, tipo de baja:
  - *Muerte*: causa (7 opciones), seguro (Sí/No).
  - *Venta*: comprador, precio total, peso venta, guía movilización, precio/kg (cálculo automático).
  - *Sacrificio*: motivo (4 opciones).
  - Observaciones.
  - Al registrar: actualiza `animales.estatus` (Muertos/Vendidos/Sacrificados/etc.).
- **Historial de Bajas**: Últimos 100 registros.
- API: `POST /api/registrar-baja`.

#### 2.10 Administración (sec_admin)
- Selector de tabla (6 permitidas: animales, partos, servicios, control_leche, bajas, palpaciones).
- Tabla editable tipo Excel con:
  - Celdas contenteditables con guardado individual o por lote.
  - Filtros por columna estilo Excel (checklist de valores únicos).
  - Ordenamiento A-Z / Z-A por columna.
  - Fotos (icono cámara abre modal).
  - Fichas (icono abre ficha detallada).
  - Agregar/Eliminar filas.
  - Auto-clasificación de categoría según reglas configuradas (sugerirCategoria).
- Configuración de columnas visibles (modal con checkboxes, persistido en `admin_config.json`).
- API: `GET /api/tablas/:nombre`, `POST /api/save-cell`, `POST /api/borrar-fila`, `POST /api/agregar-fila`.

#### 2.11 Configuración (sec_config)
- Reglas de categorización dinámicas: tabla editable con orden, nombre categoría, sexo, días min/max, meses post-parto, condición de preñez.
- Reordenar, editar, agregar, eliminar reglas.
- Guardar todo a `POST /api/configuraciones/categorias_animales`.
- Modal explicativo "Reglas de Categorización" en lenguaje natural.

#### 2.12 OCR — Reconocimiento de Pesos desde Foto
- Modal accesible desde Control Lechero (botón cámara junto al peso).
- Toma/Selecciona foto → envía a `POST /api/ocr-peso` → Tesseract.js extrae número → lo inserta en el campo.
- Soporte para reintento si tarda demasiado.

#### 2.13 Upload de Fotos
- Fotos de animal y hierro (desde ficha detallada).
- Foto de queso (desde producción).
- Almacenadas en `uploads/`.
- API: `POST /api/upload-foto`.

---

## 3. Horse API (:5001) — Backend Delphi Windows Service

**URL:** `http://localhost:5001/`  
**Tecnología:** Horse (Delphi HTTP framework), FireDAC SQLite  
**Propósito:** API REST CRUD legacy para compatibilidad con el PWA anterior (`viewer.html`). Sirve datos al VCL y al PWA legacy.

### Funcionalidades

#### 3.1 Archivos Estáticos
| Ruta | Descripción |
|---|---|
| `GET /` | Redirige a `/viewer.html` |
| `GET /viewer.html` | Sirve el PWA legacy (`public/viewer.html`) |
| `GET /public/:archivo` | Sirve archivos estáticos de `public/` (CSS, JS, imágenes, fuentes) |
| `GET /manifest.json` | Sirve el manifest PWA |

#### 3.2 Metadatos y Esquema
| Ruta | Descripción |
|---|---|
| `GET /api/tablas` | Lista todas las tablas de la BD |
| `GET /api/esquema/:tabla` | Devuelve nombres y tipos de columnas |
| `GET /api/config?table=X` | Devuelve configuración de columnas (visibilidad) |

#### 3.3 CRUD Genérico (Legacy)
| Ruta | Método | Descripción |
|---|---|---|
| `GET /api/data?table=X` | GET | Lee hasta 5000 filas con `rowid_internal` |
| `POST /api/insert` | POST | Inserta fila en cualquier tabla |
| `GET /api/update?table=X&field=F&value=V&id=N` | GET | Actualiza una celda |
| `GET /api/delete?table=X&id=N` | GET | Elimina fila por rowid |

#### 3.4 CRUD Nombrado (API Style)
| Ruta | Método | Descripción |
|---|---|---|
| `GET /api/datos/:tabla` | GET | Lee hasta 1000 filas con metadatos y filtros. Usa `GetTableSQL()` para tablas conocidas (joins) |
| `POST /api/actualizar` | POST | Actualiza fila (body JSON: `{tabla, rowid, ...campos}`) |
| `POST /api/eliminar` | POST | Elimina fila (body JSON: `{tabla, rowid}`) |
| `GET /api/exportar/:tabla` | GET | Exporta tabla completa como JSON (sin límite) |

#### 3.5 Negocio / Dashboard
| Ruta | Descripción |
|---|---|
| `GET /api/catalogs` | Valores distintos de CAT_ESTATUS, CAT_TIPO, CAT_LOTE, CAT_Propietario |
| `GET /api/dashboard` | Resumen: total animales, leche de hoy, próximos partos (60 días), lotes |

### Middleware
- `Jhonson` — Parseo de JSON en body.

### Notas
- Las rutas legacy (`/api/data`, `/api/update`, `/api/delete`) usan interpolación de strings para nombres de tabla — riesgo potencial de SQL injection, pero solo accesible localmente.
- Las tablas reconocidas (`animales`, `partos`, `servicios`, `control_leche`, `bajas`, `palpaciones`, `queso`, CAT*) tienen SQL optimizado con subqueries para obtener `propietario` y `estatus` desde `animales`.

---

## Resumen de Puertos y Tecnologías

| Interfaz | Puerto | Tecnología | Propósito principal |
|---|---|---|---|
| **Web Dashboard (SPA)** | `:5000` | Node.js + Express + HTML/CSS/JS vanilla | Gestión completa del hato vía navegador |
| **Horse API (Servicio Windows)** | `:5001` | Delphi Horse + FireDAC | API CRUD legacy + dashboard endpoint |
| **VCL (SisganDBViewer)** | — | Delphi VCL + FireDAC | Visor/editor en modo tabla, control de servicio |

**BD Compartida:** `data/sisgan_pro.db` (SQLite) — misma base de datos para las 3 interfaces.

---

## Nota sobre datos de ejemplo
Si se agregan datos de prueba/simulados (ej. producción de leche/queso de los últimos 7 días), deben restaurarse después de las pruebas para no contaminar la BD real. Se recomienda usar datos en memoria o archivos temporales separados.
