import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var firebaseReady = false;
  try {
    final options = DefaultFirebaseOptions.currentPlatform;
    await Firebase.initializeApp(options: options);
    firebaseReady = true;
  } on FirebaseException {
    firebaseReady = false;
  } catch (_) {
    firebaseReady = false;
  }
  runApp(HawaleekApp(firebaseReady: firebaseReady));
}
