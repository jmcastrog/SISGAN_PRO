# SISGAN PRO — Estado del Proyecto

## Meta
Sistema de gestión ganadera. VCL Delphi (SisganDBViewer) + web dashboard (Node.js :5000) + API Horse (:5001) + servicio Windows (ServicioSisgan).

## Progreso hasta hoy (2 Jun 2026)

### Resumen de cambios realizados
- **SisganTray.exe eliminado** — App tray standalone descartada, VCL maneja todo.
- **VCL (MainUnit.pas/.dfm):** Se quitó TrayIcon y lógica de minimizar a bandeja. Se restauró btnCloseApp ("SALIR") que cierra directo. Se restauraron btnToggleService, lblStatus, TimerStatus. Se agregaron Iniciar/Detener Servicio con ShellExecute runas. Filtro de lotes usa `estatus = 'Vivos'` (líneas 819-825).
- **Web dashboard (index.html + style.css):** SPA en `public/`.
  - Sección Dashboard con stats-grid, Composición del Hato, Próximos Partos.
  - Tarjeta Animales angosta (una línea: número + etiqueta).
  - Tarjeta de Producción Últimos 7 Días: fila de títulos (Total + días abreviados) arriba, fila de datos abajo (leche + queso + lts/kg en Total, leche + queso por día).
  - Composición del Hato: dos columnas (Por Lote / Por Propietario), cada ítem muestra nombre + cantidad + porcentaje.
  - Próximos Partos: tabla con Madre y Fecha Est.
  - Sección Fichas (buscador y listado completo) — pendiente de terminar.
- **server.js:** Endpoint `/api/dashboard` que devuelve `{animales, produccion, proximos, lotes, propietarios}`. Todos los queries filtran `estatus = 'Vivos'`. Datos de producción simulados (últimos 7 días) porque BD real está vacía.
- **BD:** Renombrados lotes "B Ordeño" → "Becerros Ordeño" y "Ordeño" → "Vacas en Ordeño" en tabla `animales` y `CAT_LOTE`.

### Pendiente / Por hacer
1. **Terminar sección Fichas** — formulario de nuevo animal, edición, listado completo con scroll infinito o paginación.
2. **Reemplazar datos simulados de producción** con datos reales cuando existan en BD.
3. **Relación Leche/Queso** — verificar fórmula y datos (actualmente lts/kg se calcula como total_leche / total_queso).
4. **Mejoras en dashboard** — refinar layout, responsive, filtros.
5. **Sincronización VCL ↔ Web** — asegurar que los cambios desde web dashboard se reflejen.
6. **Servicio Windows** — Verificar que Iniciar/Detener funcione correctamente.

## Stack técnico
- **Frontend web:** HTML+CSS+JS vanilla en `public/`
- **Backend web:** Node.js + Express (server.js, puerto 5000)
- **API backend (Horse):** uServicioSisgan.pas, URutasSisgan.pas (puerto 5001)
- **VCL:** MainUnit.pas/.dfm (Delphi)
- **BD:** SQLite (`data/sisgan_pro.db`)

## Archivos clave
| Archivo | Propósito |
|---|---|
| `server.js` | Servidor Express :5000, `/api/dashboard`, sirve `public/` |
| `public/index.html` | SPA dashboard + fichas |
| `public/style.css` | Estilos del dashboard |
| `SisganDBViewer/MainUnit.pas` | VCL form principal |
| `SisganDBViewer/MainUnit.dfm` | Layout VCL |
| `SisganDBViewer/uServicioSisgan.pas` | Horse server (puerto 5001) |
| `SisganDBViewer/URutasSisgan.pas` | Rutas Horse API |

## Cómo iniciar
- Servidor Node: `node server.js` (puerto 5000)
- VCL: compilar y ejecutar SisganDBViewer.dpr
- Horse API: se inicia desde VCL o como servicio Windows (puerto 5001)
