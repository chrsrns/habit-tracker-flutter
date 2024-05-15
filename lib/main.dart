import 'package:cron/cron.dart';
import 'package:flutter/material.dart';
import 'package:cohabit/db/database_helper.dart';
import 'package:cohabit/home_page.dart';
import 'package:sqlite3/common.dart';

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
  // This widget is the root of your application.
  var cron = Cron();

  void newSchedule() async {
    try {
      await cron.close();
      cron = Cron();
      var upcomingHabit = await DatabaseHelper.upcomingHabit;
      var recurrance = upcomingHabit?.recurrances.entries.first;

      if (recurrance != null) {
        var firstTimeRange = recurrance.value.first;
        print(
            "Now Scheduled: [weekday: ${recurrance.key}, startHour: ${firstTimeRange.startHour}, startMinute: ${firstTimeRange.startMinute}]");
        cron.schedule(
            Schedule(
                hours: firstTimeRange.startHour,
                minutes: firstTimeRange.startMinute), () {
          print("Habit starting now...");
        });
      }
    } on ScheduleParseException {
      // "ScheduleParseException" is thrown if cron parsing is failed.
      await cron.close();
    }
  }

  @override
  void initState() {
    super.initState();

    newSchedule();
    DatabaseHelper.updates.then((value) => value.listen((event) {
          // TODO Table names should have an enum
          if (event.kind == SqliteUpdateKind.insert &&
              event.tableName == "habit_recurrance") {
            newSchedule();
          }
        }));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
      ),
      home: const HomePage(title: 'CoHabit'),
    );
  }
}
