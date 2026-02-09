# Guía para Iniciar la App NeuroSocial

Acá tenés los pasos simples para hacer funcionar la app en tu compu.

## 1. Preparar las carpetas (Importante)
Como generé el código de la app "a mano", faltan las carpetas que configuran Android e iOS.
1. Abrí una terminal (PowerShell o CMD).
2. Entrá a la carpeta del proyecto:
   ```bash
   cd C:\Users\tamar\.gemini\antigravity\scratch\neuro_social
   ```
3. Ejecutá este comando para generar los archivos que faltan:
   ```bash
   flutter create .
   ```
   *(El punto al final es importante, significa "en esta carpeta")*.

## 2. Instalar dependencias
Una vez que termine el paso anterior, ejecutá:
```bash
flutter pub get
```

## 3. Configurar Firebase (Base de Datos)
Para que el login y el chat funcionen, necesitás conectar la app a Google Firebase.
1. Entrá a [Firebase Console](https://console.firebase.google.com/) y creá un proyecto nuevo (ponele "neuro-social").
2. **Para Android**:
   - Agregá una app Android (package name: `com.example.neuro_social` o el que veas en `android/app/build.gradle`).
   - Descargá el archivo `google-services.json`.
   - Ponelo en la carpeta: `neuro_social/android/app/`.
3. **Activar servicios** en el panel de Firebase:
   - **Authentication**: Activá "Email/Password".
   - **Firestore Database**: Crealo, elegí un servidor cercano (ej: us-east1) y ponelo en "Test Mode" por ahora.
   - **Storage**: Activalo también en "Test Mode".

## 4. Correr la App
Con todo listo, en la terminal escribí:
```bash
flutter run
```
Si tenés un celular conectado o un emulador abierto, la app debería abrirse ahí.

## Resumen de Comandos
```bash
cd neuro_social
flutter create .
flutter pub get
flutter run
```
