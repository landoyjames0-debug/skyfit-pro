import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBlc9GB09PgFr-_KvBoP40t-C5WD6E5Ajw',
    appId: '1:1055112886693:web:2c0bca633ab4b0ae44504c',
    messagingSenderId: '1055112886693',
    projectId: 'skyfit-pro',
    authDomain: 'skyfit-pro.firebaseapp.com',
    storageBucket: 'skyfit-pro.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAkyUV5kV2k6u1fJtFUm5O1geGlnmaZQUI',
    appId: '1:1055112886693:android:97f5f95eb874ad8344504c',
    messagingSenderId: '1055112886693',
    projectId: 'skyfit-pro',
    authDomain: 'skyfit-pro.firebaseapp.com',
    storageBucket: 'skyfit-pro.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAkyUV5kV2k6u1fJtFUm5O1geGlnmaZQUI',
    appId: '1:1055112886693:ios:97f5f95eb874ad8344504c',
    messagingSenderId: '1055112886693',
    projectId: 'skyfit-pro',
    authDomain: 'skyfit-pro.firebaseapp.com',
    storageBucket: 'skyfit-pro.appspot.com',
    iosBundleId: 'com.example.skyfitPro',
  );
}
