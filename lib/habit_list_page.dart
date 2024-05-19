import 'dart:async';
import 'dart:collection';

import 'package:cohabit/db/db_habit.dart';
import 'package:cohabit/db/table_columns.dart';
import 'package:cohabit/new_habit_dialog.dart';
import 'package:cron/cron.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as material;
import 'package:sqlite3/common.dart' as sqlite;
import 'package:cohabit/db/database_helper.dart';

class HabitListPage extends StatefulWidget {
  const HabitListPage({super.key});

  @override
  State<HabitListPage> createState() => _HabitListPageState();
}

class _HabitListPageState extends State<HabitListPage> {
  // TODO Replace with actual data
  Future<sqlite.ResultSet> _habitData =
      Future.value(sqlite.ResultSet([], [], []));

  bool _isLoading = true;
  Habit? ongoingHabit;
  StreamSubscription<void> delayer = Future.value().asStream().listen((_) {});
  Cron cron = Cron();
  ScheduledTask? currentSchedule = null;

  void updateOngoingHabit() async {
    await delayer.cancel();
    delayer = Future.delayed(Durations.long1).asStream().listen((event) async {
      var ongoingHabits = await DatabaseHelper.ongoingHabit;
      var habitOrNull = ongoingHabits.firstOrNull;
      setState(() {
        ongoingHabit = habitOrNull;
        print(
            "[${DateTime.now()} Ongoing Habit: ${ongoingHabit?.toJsonString()}");
      });
    });
  }

  @override
  void initState() {
    super.initState();
    // TODO  remove delay at some point
    _habitData = Future.delayed(
            Duration(seconds: 0), (() => DatabaseHelper.retrieveHabits()))
        .whenComplete(() => setState(() {
              _isLoading = false;
              // print(_isLoading);
            }));

    updateOngoingHabit();
    DatabaseHelper.updates.then((value) => value
      ..listen((event) {
        _habitData = Future.delayed(
                Duration(seconds: 0), (() => DatabaseHelper.retrieveHabits()))
            .whenComplete(() => setState(() {
                  setState(() {
                    _isLoading = false;
                  });
                  // print(_isLoading);
                }));

        if (event.tableName == "habit_recurrance") {
          updateOngoingHabit();
        }
      }));
    currentSchedule = cron.schedule(Schedule.parse("*/1 * * * *"), () {
      updateOngoingHabit();
    });
  }

  @override
  Widget build(BuildContext context) {
    void deleteHabit(String habit) {
      setState(() {
        DatabaseHelper.deleteHabitByName(habit);
      });
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.only(bottom: 8.0),
            child: Text(
              "Your current habits",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
            ),
          ),
          if (ongoingHabit != null)
            Row(
              children: [
                Text("Ongoing Habit: "),
                Text(ongoingHabit?.name ?? "")
              ],
            ),
          Divider(),
          FutureBuilder<sqlite.ResultSet>(
            future: _habitData,
            builder: (BuildContext context,
                AsyncSnapshot<sqlite.ResultSet> snapshot) {
              Widget childWidget;
              if (snapshot.hasData && !_isLoading) {
                childWidget =
                    ListView(children: renderListData(snapshot, deleteHabit));
              } else if (snapshot.hasError) {
                childWidget = Center(
                    child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 60,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text('Error: ${snapshot.error}'),
                    ),
                  ],
                ));
              } else {
                childWidget = Center(
                    child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Text('Awaiting result...'),
                    ),
                  ],
                ));
              }
              return Expanded(child: childWidget);
            },
          ),
        ],
      ),
    );
  }

  List<Widget> renderListData(AsyncSnapshot<sqlite.ResultSet> snapshot,
      void deleteHabit(String habit)) {
    var data = snapshot.data;
    var habits = HashSet<String>();
    var result = <Widget>[];
    if (data != null) {
      for (var habitRow in data) {
        var habitName = habitRow['${TableHabitRecurrance.habit_fr}'] as String;
        if (habits.contains(habitName)) continue;

        habits.add(habitName);
        final buttonStyle = ButtonStyle(
            backgroundColor: MaterialStateProperty.all(Colors.white),
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4))));
        final trailingButtonRow = material.Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              style: buttonStyle,
              onPressed: () {
                DatabaseHelper.retrieveHabit(habitName).then((habit) {
                  if (habit != null) {
                    showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return NewHabitDialog(habit: habit);
                        });
                  }
                });
              },
              icon: Icon(Icons.edit),
            ),
            SizedBox(
              width: 8,
            ),
            IconButton(
              style: buttonStyle,
              onPressed: () => deleteHabit(habitName),
              icon: Icon(Icons.delete_forever),
            )
          ],
        );
        result.add(Card(
          elevation: 5,
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: ListTile(
                // tileColor:
                //     Theme.of(context).colorScheme.secondaryContainer,
                title: Text(habitName),
                trailing: trailingButtonRow),
          ),
        ));
      }
    }
    result.add(SizedBox(
      height: 56 + 16,
    ));
    return result;
  }
}
