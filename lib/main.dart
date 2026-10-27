import 'package:flutter/material.dart';
import 'database/app_database.dart';
import 'pages/Login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi database lokal SQLite via Drift
  try {
    await AppDatabase.instance.seedInitialData();
  } catch (e) {
    debugPrint('Gagal inisialisasi database: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PrekDuaDara',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF206C36)),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}


