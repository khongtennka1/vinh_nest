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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
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
    apiKey: 'AIzaSyBVWIB_mR2TpvVamE5ZZ810XX_ZTwgxQI0',
    appId: '1:179919459089:web:01f46ba7f23b6c9f2472b0',
    messagingSenderId: '179919459089',
    projectId: 'roomrental-d2361',
    authDomain: 'roomrental-d2361.firebaseapp.com',
    storageBucket: 'roomrental-d2361.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB8s0cWIOWeBO_H3qssQ0fK_g55kC3GFIs',
    appId: '1:179919459089:android:720015cd255a479c2472b0',
    messagingSenderId: '179919459089',
    projectId: 'roomrental-d2361',
    storageBucket: 'roomrental-d2361.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDycFqmV5DozILT92aNsKcKcvhSGcClQPw',
    appId: '1:179919459089:ios:ec38c9f2bbbd41b12472b0',
    messagingSenderId: '179919459089',
    projectId: 'roomrental-d2361',
    storageBucket: 'roomrental-d2361.firebasestorage.app',
    iosBundleId: 'com.example.roomRentalApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDycFqmV5DozILT92aNsKcKcvhSGcClQPw',
    appId: '1:179919459089:ios:ec38c9f2bbbd41b12472b0',
    messagingSenderId: '179919459089',
    projectId: 'roomrental-d2361',
    storageBucket: 'roomrental-d2361.firebasestorage.app',
    iosBundleId: 'com.example.roomRentalApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBVWIB_mR2TpvVamE5ZZ810XX_ZTwgxQI0',
    appId: '1:179919459089:web:b0c19d82aad7145a2472b0',
    messagingSenderId: '179919459089',
    projectId: 'roomrental-d2361',
    authDomain: 'roomrental-d2361.firebaseapp.com',
    storageBucket: 'roomrental-d2361.firebasestorage.app',
  );

}