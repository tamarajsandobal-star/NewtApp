# Solución: "El término 'flutter' no se reconoce..."

Este error significa que Windows no sabe dónde está instalado Flutter. Tenés que agregarlo a las "Variables de Entorno".

## Paso 1: Encontrar dónde está Flutter
Si ya descargaste Flutter, buscalo en tu disco. Comunmente está en:
- `C:\src\flutter`
- `C:\flutter`
- O en tu carpeta de Descargas/Documentos.

Necesitás la ruta a la carpeta **`bin`**.
*Ejemplo:* `C:\src\flutter\bin`

## Paso 2: Agregar al PATH (Windows)
1. Presioná la tecla **Windows** y escribí **"env"** o **"variables de entorno"**.
2. Seleccioná **"Editar las variables de entorno del sistema"**.
3. Clic en el botón **"Variables de entorno..."**.
4. En la sección **"Variables del usuario"** (arriba) o **"Variables del sistema"** (abajo), buscá la variable llamada **`Path`** y hacé doble clic.
5. Clic en **"Nuevo"**.
6. Pegá la ruta de la carpeta **bin** que encontraste en el Paso 1 (ej: `C:\src\flutter\bin`).
7. Aceptá todas las ventanas.

## Paso 3: Reiniciar
**Cerrá todas las terminales (PowerShell/CMD) que tengas abiertas y abriles de nuevo.**

## Paso 4: Verificar
Escribí de nuevo:
```bash
flutter --version
```
Si te muestra la versión, ¡ya está! Ahora podés seguir con:
```bash
cd C:\Users\tamar\.gemini\antigravity\scratch\neuro_social
flutter create .
```
