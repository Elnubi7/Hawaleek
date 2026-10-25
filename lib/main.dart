import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var firebaseReady = false;
  String? firebaseInitError;
  try {
    final options = DefaultFirebaseOptions.currentPlatform;
    await Firebase.initializeApp(options: options);
    firebaseReady = true;
  } on FirebaseException catch (error) {
    firebaseReady = false;
    firebaseInitError = error.code;
    if (kDebugMode) {
      debugPrint(
        'Firebase initialization failed [${error.code}]: ${error.message}',
      );
    }
  } catch (error) {
    firebaseReady = false;
    firebaseInitError = 'initialization-failed';
    if (kDebugMode) debugPrint('Firebase initialization failed: $error');
  }
  runApp(
    HawaleekApp(
      firebaseReady: firebaseReady,
      firebaseInitError: firebaseInitError,
    ),
  );
}
