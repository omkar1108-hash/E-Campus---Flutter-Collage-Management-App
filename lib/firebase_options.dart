// PLACEHOLDER — replace by running `flutterfire configure` (see README),
// which regenerates this file with your own Firebase project's values.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;

class DefaultFirebaseOptions {
  static const _placeholder = 'YOUR_API_KEY';

  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('E-Campus supports Android and iOS only.');
    }
  }

  /// True once real project values have been generated.
  static bool get isConfigured => currentPlatform.apiKey != _placeholder;

  static const android = FirebaseOptions(
    apiKey: _placeholder,
    appId: 'YOUR_ANDROID_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
  );

  static const ios = FirebaseOptions(
    apiKey: _placeholder,
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
    iosBundleId: 'in.edu.aimsr.eCampus',
  );
}
