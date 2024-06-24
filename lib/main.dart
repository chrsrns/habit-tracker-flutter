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

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CoHabit',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
      ),
      home: LandingScreen(onSplashDone: () {}),
    );
  }
}
