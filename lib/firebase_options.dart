import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) throw UnsupportedError('웹 플랫폼은 지원하지 않습니다.');
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('지원하지 않는 플랫폼: $defaultTargetPlatform');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDMZasGG9OR1NkyUHqqn3ryZNd1C43wZwY',
    appId: '1:338803924247:android:3f5f3add367caab124eb52',
    messagingSenderId: '338803924247',
    projectId: 'bridge-96007',
    storageBucket: 'bridge-96007.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDMZasGG9OR1NkyUHqqn3ryZNd1C43wZwY',
    appId: '1:338803924247:android:3f5f3add367caab124eb52',
    messagingSenderId: '338803924247',
    projectId: 'bridge-96007',
    storageBucket: 'bridge-96007.firebasestorage.app',
    iosBundleId: 'com.example.bridgeApp',
  );
}
