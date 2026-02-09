# Configuración de Firebase (Paso a Paso)

Para que el **Login** y el **Chat** funcionen, necesitamos crear el "cerebro" de la app en internet (Google Firebase).

## 1. Entrar a la Consola
1. Hacé clic en este link: [**console.firebase.google.com**](https://console.firebase.google.com/)
2. Iniciá sesión con tu cuenta de Google (Gmail).

## 2. Crear el Proyecto
1. Clic en el botón grande que dice **"Agregar proyecto"** (o "Create a project").
2. **Nombre**: Escribí `neuro-social`.
3. **Google Analytics**: Podés desactivarlo (es más rápido) o dejarlo activo. Dale a "Continuar".
4. Esperá a que termine de cargar y dale a "Continuar".

## 3. Activar el Login
1. En el menú de la izquierda, buscá **"Compilación"** (Build) -> **"Authentication"**.
2. Clic en **"Comenzar"** (Get started).
3. En la pestaña **"Sign-in method"**, elegí **"Correo electrónico/contraseña"**.
4. Activá la primera opción ("Habilitar") y dale a **"Guardar"**.

## 4. Activar la Base de Datos
1. En el menú de la izquierda, buscá **"Firestore Database"**.
2. Clic en **"Crear base de datos"**.
3. **Ubicación**: Dejá la que viene por defecto (us-central o us-east).
4. **Reglas de seguridad**: Elegí **"Comenzar en modo de prueba"** (Test mode).
5. Clic en **"Crear"** (o "Habilitar").

## 5. Conectar tu App (Web / Edge)
Como estás usando Edge, vamos a configuralo como una **Web App**:
1. En la página principal de tu proyecto (clic en la ruedita de configuración arriba a la izquierda -> **Configuración del proyecto**).
2. Bajá hasta abajo donde dice "Tus apps".
3. Clic en el ícono redondo **`</>`** (Web).
4. **Apodo**: `neuro-social-web`.
5. Clic en **"Registrar app"**.
6. Te va a mostrar un código. **COPIÁ solo la parte que dice `const firebaseConfig = { ... }`**. (Son las claves secretas).

---

### ¿Qué hago con el código copiado?
Una vez que tengas ese código, avisame y te digo dónde pegarlo en la app (`lib/firebase_options.dart`).
