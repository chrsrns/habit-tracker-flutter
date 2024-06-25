import 'dart:ui';

import 'package:cohabit/main.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isDarkMode = false;
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _isDarkMode = () {
      final currentTheme = MainApp.of(context).currentTheme;
      final platformBrightness = PlatformDispatcher.instance.platformBrightness;
      if (currentTheme == ThemeMode.dark)
        return true;
      else if (currentTheme == ThemeMode.system &&
          platformBrightness == Brightness.dark)
        return true;
      else
        return false;
    }();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.only(bottom: 8.0),
            child: Text(
              "Settings",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
            ),
          ),
          Divider(),
          Card.filled(
              child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
            child: Row(
              children: [
                Expanded(child: Text("Toggle Dark Mode")),
                Switch(
                    value: _isDarkMode,
                    onChanged: (bool on) {
                      if (on)
                        setState(() {
                          MainApp.of(context).changeTheme(ThemeMode.dark);
                        });
                      else
                        setState(() {
                          MainApp.of(context).changeTheme(ThemeMode.light);
                        });
                    })
              ],
            ),
          ))
        ],
      ),
    );
  }
}
