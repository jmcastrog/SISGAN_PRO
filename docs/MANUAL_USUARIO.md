# Manual de Usuario - SISGAN PRO

Bienvenido al Manual de Usuario de **SISGAN PRO**. Este documento le guiará a través de las funciones principales de la aplicación para gestionar su hato de manera eficiente.

---

## 1. Acceso al Sistema
Para ingresar al sistema:
1. Abra la aplicación en su navegador o dispositivo móvil.
2. Ingrese su **Usuario** y **Contraseña**.
3. Haga clic en **INGRESAR AL SISTEMA**.

---

## 2. El Dashboard (Panel de Inicio)
Al entrar, verá un resumen rápido:
- **Estadísticas**: Total de animales activos y producción de leche del día.
- **Próximos Partos**: Una lista automática de las vacas que están cerca de parir, basada en sus palpaciones previas.
- **Acceso Externo**: Si el sistema está configurado para acceso remoto, verá la URL aquí.

---

## 3. Gestión de Animales
Haga clic en **Animales** en el menú lateral.
- **Buscador**: Puede buscar cualquier animal escribiendo su número o nombre. 
- **Nuevo Animal**: Use el botón "Nuevo" para registrar un animal desde cero. Puede usar el botón de la "varita mágica" para que el sistema sugiera el siguiente número disponible.
- **Ficha del Animal**: Al hacer clic en el icono del ojo (👁️), verá toda la historia del animal: pesajes de leche, partos previos y servicios reproductivos.

---

## 4. Control Lechero (Ordeño Diario)
Este módulo está diseñado para capturar datos rápidamente en el campo:
1. **Configuración**: Seleccione la fecha y el turno (Mañana/Tarde). Ajuste el peso del tobo (balde vacío).
2. **Registro**: Busque el animal en el campo "Buscar vaca" y escriba el peso bruto.
3. **Uso de la Cámara (OCR)**: Si tiene la balanza digital en frente, puede presionar el icono de la **cámara** para tomar una foto del indicador y que el sistema detecte el peso automáticamente.
4. **Borrador**: El sistema guarda sus cambios localmente mientras trabaja. Si la página se cierra, verá un aviso de "Borrador recuperado" al volver.
5. **Grabar**: Al finalizar la lista, presione **GRABAR EN BD** para guardar definitivamente los datos.

---

## 5. Registro de Partos
Para registrar un nacimiento o un aborto:
1. Seleccione la **Madre**.
2. Indique la fecha y el sexo de la cría.
3. **Automatización**: Si la cría nace viva, el sistema le pedirá un número de arete. Al guardar:
   - Se crea automáticamente la ficha de la cría.
   - La madre cambia automáticamente al lote **"Ordeño"** y estatus **"En Lactancia"**.

---

## 6. Reproducción y Palpaciones
- **Servicios**: Registre montas naturales, inseminaciones o transferencias.
- **Palpaciones**: Registre el diagnóstico del veterinario.
  - Si marca **"Preñada"**, el sistema le pedirá la Fecha Estimada de Parto. Al guardar, esta vaca aparecerá automáticamente en las alertas del Dashboard.

---

## 7. Bajas del Hato
Cuando un animal sale del hato (por venta, muerte, robo, etc.):
1. Busque el animal.
2. Seleccione el tipo de baja.
3. Si es **Venta**, puede registrar el precio y el comprador. El sistema calculará automáticamente el precio por kilo.

---

## 8. Administración y Configuración
- **Datos de Tablas**: Permite ver todas las tablas en formato de cuadrícula (estilo Excel). Puede editar celdas directamente o borrar registros.
- **Reglas de Categorización**: En el menú **Configuración**, puede definir qué edad o estado reproductivo debe tener un animal para pertenecer a una categoría (ej. Ternero, Novilla, Vaca). El sistema aplicará estas reglas automáticamente para sugerir categorías en el buscador.

---
*Si tiene dudas adicionales, consulte con el administrador del sistema.*
