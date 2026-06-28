import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:homely/routers/auth_router.dart';
import 'firebase_options.dart';

void main() async {
  await _initializeFlutter();
  await _initializeFirebase();
  runApp(const HomelyApp());
}

Future<void> _initializeFlutter() async {
  WidgetsFlutterBinding.ensureInitialized();
}

Future<void> _initializeFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class HomelyApp extends StatelessWidget {
  const HomelyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Homely',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6C63FF)),
        useMaterial3: true,
      ),
      home: const AuthRouter(),
    );
  }
}
