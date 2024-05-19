import 'dart:async';

import 'package:cohabit/new_habit_dialog.dart';
import 'package:cron/cron.dart';
import 'package:flutter/material.dart';
import 'package:cohabit/db/database_helper.dart';
import 'package:cohabit/nav_destinations.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var _selectedIndex = 0; // ← Add this property.
  late bool _showNavRail;
  var _expandNavRail = false;

  void _handleNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final cron = Cron();
  ScheduledTask? currentSchedule = null;
  StreamSubscription<void> delayer = Future.value().asStream().listen((_) {});

  void newSchedule() async {
    await delayer.cancel();
    delayer = Future.delayed(Durations.long1).asStream().listen((event) async {
      try {
        var upcomingHabit = await DatabaseHelper.upcomingHabit;
        var recurrance = upcomingHabit?.recurrances.entries.first;

        if (recurrance != null) {
          var firstTimeRange = recurrance.value.first;
          print(
              "Now Scheduled: [weekday: ${recurrance.key}, startHour: ${firstTimeRange.startHour}, startMinute: ${firstTimeRange.startMinute}]");
          await currentSchedule?.cancel();
          currentSchedule = cron.schedule(
              Schedule(
                  hours: firstTimeRange.startHour,
                  minutes: firstTimeRange.startMinute), () {
            print("Habit is starting");
            showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text("Habit is starting..."),
                  );
                });
          });
        }
      } on ScheduleParseException {
        // "ScheduleParseException" is thrown if cron parsing is failed.
        await cron.close();
      }
    });
  }

  @override
  void initState() {
    super.initState();

    newSchedule();
    DatabaseHelper.updates.then((value) => value.listen((event) {
          // TODO Table names should have an enum
          if (event.tableName == "habit_recurrance") {
            newSchedule();
          }
        }));
  }

  Widget buildNavRailScaffold() {
    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        appBar: AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text(widget.title),
        ),
        body: Row(
          children: [
            NavigationRail(
              extended: _expandNavRail,
              onDestinationSelected: _handleNavTap,
              selectedIndex: _selectedIndex,
              labelType: _expandNavRail
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              destinations: destinations.map(
                (NavDestinations destination) {
                  return NavigationRailDestination(
                    label: Text(
                      destination.label,
                      style: TextStyle(fontSize: _expandNavRail ? 16 : 14),
                    ),
                    icon: destination.icon,
                    selectedIcon: destination.selectedIcon,
                  );
                },
              ).toList(),
            ),
            Expanded(
              child: Container(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: destinations[_selectedIndex].page,
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            showDialog(
                context: context,
                builder: (BuildContext context) {
                  return NewHabitDialog();
                });
          },
          tooltip: 'New habit',
          child: const Icon(Icons.add),
        ),
      );
    });
  }

  Widget buildBottomNavScaffold() {
    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        appBar: AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text(widget.title),
        ),
        bottomNavigationBar: NavigationBar(
          onDestinationSelected: (int index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          selectedIndex: _selectedIndex,
          destinations: destinations.map(
            (NavDestinations destination) {
              return NavigationDestination(
                label: destination.label,
                icon: destination.icon,
                selectedIcon: destination.selectedIcon,
                tooltip: destination.label,
              );
            },
          ).toList(),
        ),
        body: Row(
          children: [
            Expanded(
              child: Container(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: destinations[_selectedIndex].page,
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => print("TODO"), //TODO
          tooltip: 'Increment',
          child: const Icon(Icons.add),
        ),
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _showNavRail = MediaQuery.of(context).size.width >= 450;
    _expandNavRail = MediaQuery.of(context).size.width >= 700;
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.

    return _showNavRail ? buildNavRailScaffold() : buildBottomNavScaffold();
  }
}
