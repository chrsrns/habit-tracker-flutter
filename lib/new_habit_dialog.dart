import 'dart:math';

import 'package:cohabit/db/database_helper.dart';
import 'package:cohabit/db/db_habit.dart';
import 'package:cohabit/db/db_time_range.dart';
import 'package:cohabit/db/weekdays_enum.dart';
import 'package:flutter/material.dart';

class _MutableRecurrancePair {
  Weekday? weekday;
  List<TimeRange> timeranges = [];

  _MutableRecurrancePair({this.weekday, List<TimeRange>? timeranges})
      : timeranges = timeranges ?? [];

  _MutableRecurrancePair copy() => _MutableRecurrancePair(
      weekday: this.weekday, timeranges: this.timeranges);
}

class _RecurrancePairList {
  List<_MutableRecurrancePair> items = [];

  void add(_MutableRecurrancePair recurrancePair) {
    for (var i = 0; i < items.length; i++) {
      var existingPair = items[i];

      if (recurrancePair.weekday == existingPair.weekday) {
        items[i].weekday = recurrancePair.weekday;
        items[i].timeranges.addAll(recurrancePair.timeranges);
        return;
      }
    }
    items.add(recurrancePair);
  }

  void updateWeekdayOfPair(
      _MutableRecurrancePair recurrancePair, Weekday weekday) {
    final List<_MutableRecurrancePair> toRemove = [];
    var tmp = _MutableRecurrancePair();
    for (final existingPair in items) {
      if (existingPair.weekday == weekday) {
        tmp = existingPair.copy();
        toRemove.add(recurrancePair);
        break;
      }
    }
    if (toRemove.isEmpty) {
      var firstWhere = items.firstWhere((element) => element == recurrancePair);
      firstWhere.weekday = weekday;
    } else {
      tmp.timeranges.addAll(recurrancePair.timeranges);
      items.removeWhere((element) {
        print(toRemove.contains(element));
        return toRemove.contains(element);
      });
    }
  }
}

class NewHabitDialog extends StatefulWidget {
  final Habit? habit;
  NewHabitDialog({super.key, this.habit}) {
    print("Selected Habit: ${habit?.name}");
  }

  @override
  State<NewHabitDialog> createState() => _NewHabitDialogState(habit);
}

class _NewHabitDialogState extends State<NewHabitDialog> {
  final Habit? _habit;

  List<DropdownMenuItem<Weekday>> get weekdayDropdownItems {
    List<DropdownMenuItem<Weekday>> menuItems = [
      DropdownMenuItem(child: Text("Monday"), value: Weekday.monday),
      DropdownMenuItem(child: Text("Tuesday"), value: Weekday.tuesday),
      DropdownMenuItem(child: Text("Wednesday"), value: Weekday.wednesday),
      DropdownMenuItem(child: Text("Thursday"), value: Weekday.thursday),
      DropdownMenuItem(child: Text("Friday"), value: Weekday.friday),
      DropdownMenuItem(child: Text("Saturday"), value: Weekday.saturday),
      DropdownMenuItem(child: Text("Sunday"), value: Weekday.sunday),
    ];
    return menuItems;
  }

  final habitNameController = TextEditingController();
  final uiEntries = _RecurrancePairList();

  _NewHabitDialogState(this._habit) {
    final habit = _habit;

    if (habit != null) {
      habitNameController.text = habit.name;
      for (var recurrance in habit.recurrances.keys) {
        uiEntries.add(_MutableRecurrancePair(
            weekday: Weekday.values[recurrance],
            timeranges: habit.recurrances[recurrance]));
      }
    }
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is removed from the
    // widget tree.
    habitNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext buildctx) {
    final dialogWidth = () {
      var appWidth = MediaQuery.of(buildctx).size.width;
      if (appWidth >= 700)
        return appWidth - 250;
      else
        return appWidth;
    }();

    final getEntriesList = (BuildContext ctx) {
      return uiEntries.items.map((recurrance_pair) {
        var list = weekdayDropdownItems.where((element) {
          for (final pair in uiEntries.items) {
            if (recurrance_pair.weekday == element.value) return true;
            if (pair.weekday == element.value) return false;
          }
          return true;
        }).toList();
        var timeRangesAsButtons = [
          ...recurrance_pair.timeranges.map((e) => Container(
                margin: EdgeInsets.only(top: 8.0, bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                        onPressed: () {
                          updateTimeRange(buildctx, e, recurrance_pair);
                        },
                        child: Container(
                          padding: EdgeInsets.only(
                              left: 12, right: 12, top: 8, bottom: 8),
                          child: Container(
                            height: 20,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text("${e.startTime}"),
                                VerticalDivider(),
                                Text("${e.endTime}")
                              ],
                            ),
                          ),
                        )),
                  ],
                ),
              )),
          ElevatedButton(
              onPressed: () {
                if (recurrance_pair.weekday == null) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: const Text('Select weekday on the left first'),
                      duration: const Duration(seconds: 3),
                      action: SnackBarAction(
                        label: 'ACTION',
                        onPressed: () {},
                      ),
                    ),
                  );
                } else
                  showTimeRangePickers(buildctx, recurrance_pair);
              },
              child: Text("Add new time..."))
        ];
        return Container(
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: DropdownButton(
                  padding: EdgeInsets.only(left: 8, right: 8),
                  hint: Text("Select weekday"),
                  items: list,
                  value: recurrance_pair.weekday,
                  onChanged: (dropdownValue) {
                    if (dropdownValue is Weekday)
                      setState(() {
                        uiEntries.updateWeekdayOfPair(
                            recurrance_pair, dropdownValue);
                      });
                  },
                ),
              ),
              Expanded(
                flex: 1,
                child: Column(
                  children: timeRangesAsButtons,
                ),
              ),
              Divider()
            ],
          ),
        );
      }).toList();
    };
    return ScaffoldMessenger(
      child: Builder(
        builder: (scaffoldMessengerCtx) => Scaffold(
          backgroundColor: Colors.transparent,
          body: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(scaffoldMessengerCtx).pop(),
            child: GestureDetector(
              onTap: () {},
              child: AlertDialog(
                title: Text(_habit == null
                    ? "Create New Habit"
                    : "Modifying this Habit"),
                content: Center(
                  child: SizedBox(
                    // TODO add animation to this dynamic sizing
                    width: dialogWidth,
                    child: Column(
                      children: [
                        TextField(
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Name of new habit',
                          ),
                          controller: habitNameController,
                        ),
                        SizedBox(height: 8),
                        Divider(),
                        (BuildContext context) {
                          // TODO rename
                          final entriesList = getEntriesList(context);
                          return Expanded(
                            child: ListView.separated(
                              scrollDirection: Axis.vertical,
                              shrinkWrap: true,
                              itemCount: entriesList.length,
                              itemBuilder: (context, index) {
                                return entriesList[index];
                              },
                              separatorBuilder: (context, index) => Divider(),
                            ),
                          );
                        }(scaffoldMessengerCtx),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.of(context, rootNavigator: true).pop();
                      },
                      child: const Text("Cancel")),
                  FilledButton.tonal(
                      onPressed: () {
                        final pair = _MutableRecurrancePair();
                        setState(() {
                          uiEntries.add(pair);
                        });
                      },
                      child: Text("Add another week")),
                  FilledButton(
                      onPressed: () {
                        if (habitNameController.text.isEmpty) {
                          ScaffoldMessenger.of(scaffoldMessengerCtx)
                              .showSnackBar(
                            SnackBar(
                              content:
                                  const Text('Fill up the habit name first'),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                          return;
                        }

                        var map = Map<int, List<TimeRange>>();
                        for (var recurranceItem in uiEntries.items) {
                          final weekday = recurranceItem.weekday;
                          if (weekday != null)
                            map[weekday.index] = recurranceItem.timeranges;
                        }
                        print(map);
                        var deleteFirst = () {
                          if (_habit != null) {
                            return DatabaseHelper.deleteHabit(_habit!);
                          } else
                            return Future.value();
                        }();
                        deleteFirst.then((_) {
                          DatabaseHelper.insertHabit(
                            Habit(
                                name: habitNameController.text,
                                recurrances: map),
                          );
                        }).whenComplete(() {
                          Navigator.of(context, rootNavigator: true).pop();
                        });
                      },
                      child: Text(_habit == null ? "Create" : "Modify"))
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void updateTimeRange(BuildContext context, TimeRange e,
      _MutableRecurrancePair recurrance_pair) {
    final timePicker = showTimePicker(
        context: context,
        helpText: "What is the starting time of this habit?",
        initialTime: TimeOfDay(hour: e.startHour, minute: e.startMinute),
        initialEntryMode: TimePickerEntryMode.dialOnly);
    timePicker.then((startTime) {
      if (startTime != null) {
        final startHour = startTime.hour;
        final startMinute = startTime.minute;
        final endTimePicker = showTimePicker(
            context: context,
            helpText: "What is the ending time of this habit?",
            initialTime: TimeOfDay(hour: e.endHour, minute: e.endMinute));
        endTimePicker.then((endTime) {
          if (endTime != null) {
            setState(() {
              var endHour = endTime.hour;
              var endMinute = endTime.minute;
              final indexOf = recurrance_pair.timeranges.indexOf(e);
              recurrance_pair.timeranges.replaceRange(indexOf, indexOf + 1, [
                TimeRange(
                    startHour: startHour,
                    startMinute: startMinute,
                    endHour: endHour,
                    endMinute: endMinute)
              ]);
            });
          }
        });
      }
    });
  }

  void showTimeRangePickers(
      BuildContext context, _MutableRecurrancePair recurrance_pair) {
    final timePicker = showTimePicker(
        context: context,
        helpText: "What is the starting time of this habit?",
        initialTime: TimeOfDay.now(),
        initialEntryMode: TimePickerEntryMode.dialOnly);
    timePicker.then((startTime) {
      if (startTime != null) {
        final startHour = startTime.hour;
        final startMinute = startTime.minute;
        final endTimePicker = showTimePicker(
            context: context,
            helpText: "What is the ending time of this habit?",
            initialTime: TimeOfDay.now());
        endTimePicker.then((endTime) {
          if (endTime != null) {
            setState(() {
              var endHour = endTime.hour;
              var endMinute = endTime.minute;
              var timeRange = TimeRange(
                  startHour: startHour,
                  startMinute: startMinute,
                  endHour: endHour,
                  endMinute: endMinute);
              recurrance_pair.timeranges.add(timeRange);
            });
          }
        });
      }
    });
  }
}
