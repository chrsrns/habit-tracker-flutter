import 'dart:async';
import 'dart:collection';

import 'package:cohabit/db/db_habit.dart';
import 'package:cohabit/db/table_columns.dart';
import 'package:cohabit/db/weekdays_enum.dart';
import 'package:cohabit/new_habit_dialog.dart';
import 'package:cron/cron.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as material;
import 'package:sqlite3/common.dart' as sqlite;
import 'package:cohabit/db/database_helper.dart';
import 'package:sqlite3/sqlite3.dart';

class HabitListPage extends StatefulWidget {
  const HabitListPage({super.key});

  @override
  State<HabitListPage> createState() => _HabitListPageState();
}

class _HabitListPageState extends State<HabitListPage> {
  // TODO Replace with actual data
  Future<sqlite.ResultSet?> _habitData =
      Future.value(sqlite.ResultSet([], [], []));

  bool _isLoading = true;
  Habit? ongoingHabit;
  Cron cron = Cron();
  StreamSubscription<ResultSet?>? _habitsSortedSubscription;
  StreamSubscription<List<Habit>?>? _ongoingHabitSubscription;
  ScheduledTask? onOngoingHabitEnd = null;

  @override
  void initState() {
    super.initState();
    // TODO  remove delay at some point
    _habitsSortedSubscription = DatabaseHelper.habitsSorted.listen((event) {
      _habitData = Future.value(event);
      setState(() {
        _isLoading = false;
      });
    });

    _ongoingHabitSubscription = DatabaseHelper.ongoingHabit.listen((event) {
      var habitOrNull = event?.firstOrNull;
      setState(() {
        ongoingHabit = habitOrNull;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _habitsSortedSubscription?.cancel();
    _ongoingHabitSubscription?.cancel();
    onOngoingHabitEnd?.cancel();
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
          Divider(),
          FutureBuilder<sqlite.ResultSet?>(
            future: _habitData,
            builder: (BuildContext context,
                AsyncSnapshot<sqlite.ResultSet?> snapshot) {
              Widget childWidget;
              print("snapshot.hasData: ${snapshot.hasData}");
              if (snapshot.hasData) {
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

  List<Widget> renderListData(AsyncSnapshot<sqlite.ResultSet?> snapshot,
      void deleteHabit(String habit)) {
    var data = snapshot.data;
    var habits = HashSet<String>();
    var result = <Widget>[];
    if (data != null) {
      for (var habitRow in data) {
        var habitName = habitRow['${TableHabitRecurrance.habit_fr}'] as String;
        var weekday = habitRow['${TableHabitRecurrance.weekday_id_fr}'] as int;
        var startHour =
            habitRow['${TableHabitRecurrance.start_hour_fr}'] as int;
        var startMinute =
            habitRow['${TableHabitRecurrance.start_minute_fr}'] as int;
        var endHour = habitRow['${TableHabitRecurrance.end_hour_fr}'] as int;
        var endMinute =
            habitRow['${TableHabitRecurrance.end_minute_fr}'] as int;
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
        late Widget habitText;
        late Card paddedChip;
        late Color cardColor;
        if (ongoingHabit?.name == habitName) {
          habitText = IntrinsicWidth(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(style: TextStyle(fontSize: 12), "Ongoing Habit"),
              Text(style: TextStyle(fontWeight: FontWeight.bold), habitName),
            ],
          ));
          paddedChip = Card(
            margin: EdgeInsets.all(0),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Wrap(
                spacing: 4,
                crossAxisAlignment: WrapCrossAlignment.end,
                key: ValueKey(habitName),
                children: [
                  Text(style: TextStyle(fontSize: 12), "Habit ends in: "),
                  Text(
                      style: TextStyle(fontSize: 12),
                      TimeOfDay(hour: endHour, minute: endMinute)
                          .format(context)),
                ],
              ),
            ),
          );
          cardColor = Theme.of(context).colorScheme.tertiaryContainer;
        } else {
          habitText = Text(habitName);
          paddedChip = Card(
            margin: EdgeInsets.all(0),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Wrap(
                spacing: 4,
                crossAxisAlignment: WrapCrossAlignment.end,
                key: ValueKey(habitName),
                children: [
                  Text(style: TextStyle(fontSize: 12), "Next Start: "),
                  Text(
                      style: TextStyle(fontSize: 12),
                      Weekday.fromInt(weekday).label),
                  Text(
                      style: TextStyle(fontSize: 12),
                      TimeOfDay(hour: startHour, minute: startMinute)
                          .format(context)),
                ],
              ),
            ),
          );
          cardColor = Theme.of(context).colorScheme.surface;
        }
        result.add(Card(
          color: cardColor,
          elevation: 5,
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: ListTile(
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 4),
                      child: habitText,
                    ),
                    paddedChip
                  ],
                ),
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
