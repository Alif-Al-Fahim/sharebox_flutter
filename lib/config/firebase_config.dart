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
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // ✅ Web config 
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'dummy',
    appId: 'dummy',
    messagingSenderId: '246323136837',
    projectId: 'sharebox-flutter',
    authDomain: 'sharebox-flutter.firebaseapp.com',
    storageBucket: 'sharebox-flutter.firebasestorage.app',
  );

  // ✅ Android config 
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'dummy',
    appId: 'dummy',
    messagingSenderId: '246323136837',
    projectId: 'sharebox-flutter',
    storageBucket: 'sharebox-flutter.firebasestorage.app',
  );

  // ✅ iOS (safe placeholder)
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'dummy',
    appId: 'dummy',
    messagingSenderId: '246323136837',
    projectId: 'sharebox-flutter',
    storageBucket: 'sharebox-flutter.firebasestorage.app',
    iosBundleId: 'com.sharebox.bd',
  );
}
