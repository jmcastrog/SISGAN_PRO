# Estructura de la Base de Datos SISGAN PRO

A continuación se detalla la estructura actual de las tablas en la base de datos (`data/sisgan_pro.db`), incluyendo el nombre de cada columna y su tipo de dato:

## Tabla `ANIMALES`
| Columna | Tipo de Dato |
| :--- | :--- |
| `id` | INTEGER |
| `numero` | TEXT |
| `nombre` | TEXT |
| `fecha_nac` | TEXT |
| `sexo` | TEXT |
| `raza` | TEXT |
| `tipo` | TEXT |
| `lote` | TEXT |
| `estatus` | TEXT |
| `propietario` | TEXT |
| `num_madre` | TEXT |
| `nom_madre` | TEXT |
| `padre` | TEXT |
| `peso_nacer` | REAL |
| `comentarios` | TEXT |
| `foto_animal` | TEXT |
| `foto_hierro` | TEXT |
| `fecha_parto_est` | TEXT |

## Tabla `CONTROL_LECHE`
| Columna | Tipo de Dato |
| :--- | :--- |
| `id` | INTEGER |
| `fecha` | TEXT |
| `numero_animal` | TEXT |
| `nombre_animal` | TEXT |
| `kg` | REAL |
| `turno` | TEXT |
| `peso_tobo` | REAL |
| `creado_por` | TEXT |
| `creado_en` | TEXT |

## Tabla `PARTOS`
| Columna | Tipo de Dato |
| :--- | :--- |
| `id` | INTEGER |
| `fecha` | TEXT |
| `num_madre` | TEXT |
| `nom_madre` | TEXT |
| `num_asignado` | TEXT |
| `sexo` | TEXT |
| `peso` | REAL |
| `estado` | TEXT |
| `raza` | TEXT |
| `padre` | TEXT |
| `observacion` | TEXT |
| `estatus_cria` | TEXT |
| `creado_por` | TEXT |
| `creado_en` | TEXT |

## Tabla `SERVICIOS`
| Columna | Tipo de Dato |
| :--- | :--- |
| `id` | INTEGER |
| `fecha` | TEXT |
| `numero` | TEXT |
| `nombre` | TEXT |
| `tipo` | TEXT |
| `toro` | TEXT |
| `raza_toro` | TEXT |
| `creado_por` | TEXT |
| `creado_en` | TEXT |

## Tabla `USUARIOS`
| Columna | Tipo de Dato |
| :--- | :--- |
| `id` | INTEGER |
| `usuario` | TEXT |
| `password` | TEXT |
| `nombre` | TEXT |
| `rol` | TEXT |
| `activo` | INTEGER |

## Tabla `QUESO`
| Columna | Tipo de Dato |
| :--- | :--- |
| `id` | INTEGER |
| `fecha` | TEXT |
| `equipo` | TEXT |
| `peso_kg` | REAL |
| `foto_path` | TEXT |
| `creado_por` | TEXT |
| `creado_en` | TEXT |
