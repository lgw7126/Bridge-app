import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

// ⚠️  Firebase 프로젝트 설정 후 실제 값으로 교체하세요.
// 자동 생성 방법:
//   1. dart pub global activate flutterfire_cli
//   2. flutterfire configure --project=YOUR_PROJECT_ID
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

  // TODO: Firebase 콘솔 → 프로젝트 설정 → google-services.json 값으로 교체
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_ANDROID_API_KEY',
    appId: 'YOUR_ANDROID_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
  );

  // TODO: Firebase 콘솔 → 프로젝트 설정 → GoogleService-Info.plist 값으로 교체
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
    iosBundleId: 'com.bridgeapp.bridgeApp',
  );
}
