// lib/main_debug.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pos_app/providers/app_provider.dart';
import 'package:pos_app/screens/pos_screen.dart';
import 'package:pos_app/services/database/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🔄 Приложение запускается...');
  
  try {
    print('🔄 Инициализация базы данных...');
    final db = DatabaseHelper();
    await db.database;
    print('✅ База данных инициализирована');
  } catch (e, stack) {
    print('❌ ОШИБКА БД: $e');
    print('📚 Стек: $stack');
    // Показываем ошибку на экране
    runApp(ErrorApp(error: e.toString()));
    return;
  }
  
  runApp(const MyApp());
}

class ErrorApp extends StatelessWidget {
  final String error;
  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Ошибка инициализации',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.red),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        print('🔄 Создание AppProvider...');
        final provider = AppProvider();
        provider.init();
        return provider;
      },
      child: MaterialApp(
        title: 'Кассовое приложение',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const PosScreen(),
      ),
    );
  }
}