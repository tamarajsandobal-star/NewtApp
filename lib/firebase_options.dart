// File generated manually based on user input for Web/Edge keys.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for android - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        // Using the same config as Web for Windows often works for development 
        // if the project is simple, or if specifically configured. 
        // Ideally Windows has its own app registration.
        return web; 
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDwTsMzy0NhCkdfdRQKrK23JvQUNvQMsSo',
    appId: '1:36526529200:web:a0186c23b11a32d1de7975',
    messagingSenderId: '36526529200',
    projectId: 'newt-4c60e',
    authDomain: 'newt-4c60e.firebaseapp.com',
    storageBucket: 'newt-4c60e.firebasestorage.app',
    measurementId: 'G-7KKWXFW1XC',
  );
}
