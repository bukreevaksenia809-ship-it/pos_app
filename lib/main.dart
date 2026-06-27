import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pos_app/providers/app_provider.dart';
import 'package:pos_app/providers/theme_provider.dart';
import 'package:pos_app/screens/pos_screen.dart';
import 'package:pos_app/screens/catalog_screen.dart';
import 'package:pos_app/screens/history_screen.dart';
import 'package:pos_app/screens/add_product_screen.dart';
import 'package:pos_app/screens/summary_screen.dart';
import 'package:pos_app/screens/importer_screen.dart';
import 'package:pos_app/services/database/database_helper.dart';
import 'package:pos_app/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('isDarkTheme') ?? false;
  try {
    await DatabaseHelper().database;
  } catch (e) {
    print('❌ Ошибка БД: $e');
  }
  runApp(MyApp(isDark: isDark));
}

class MyApp extends StatelessWidget {
  final bool isDark;
  const MyApp({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()..init()),
        ChangeNotifierProvider(create: (_) => ThemeProvider(isDark)),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Кассовое приложение Pro',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            initialRoute: '/',
            routes: {
              '/': (context) => const PosScreen(),
              '/catalog': (context) => const CatalogScreen(),
              '/history': (context) => const HistoryScreen(),
              '/add_product': (context) => AddProductScreen(),
              '/summary': (context) => const SummaryScreen(),
              '/importer': (context) => const ImporterScreen(),
            },
          );
        },
      ),
    );
  }
}
