// File configured for FlowerConnect Firebase integration
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for FlowerConnect using the real Firebase project `flowerconnect-7acaa`.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'only Android configuration (flowerconnect-7acaa) is currently provided.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for iOS - '
          'only Android configuration (flowerconnect-7acaa) is currently provided.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  /// Real Android FirebaseOptions from mobile/android/app/google-services.json
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBkryF-mpMAaTj_oveYloBn3Dch2saVqXE',
    appId: '1:385022177428:android:dbdc224602c2c2c37d0481',
    messagingSenderId: '385022177428',
    projectId: 'flowerconnect-7acaa',
    storageBucket: 'flowerconnect-7acaa.firebasestorage.app',
  );
}
