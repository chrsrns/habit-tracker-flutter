import 'package:cohabit/landing_screen.dart';
import 'package:flutter/material.dart';
import 'package:cohabit/db/database_helper.dart';

Future<void> main() async {
  // WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.initDB();
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({Key? key}) : super(key: key);

  static _MainAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MainAppState>()!;

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CoHabit',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepOrange, brightness: Brightness.dark),
      ),
      themeMode: _themeMode,
      home: LandingScreen(onSplashDone: () {}),
    );
  }

  void changeTheme(ThemeMode themeMode) {
    setState(() {
      _themeMode = themeMode;
      print(_themeMode);
    });
  }

  ThemeMode get currentTheme {
    return _themeMode;
  }
}
