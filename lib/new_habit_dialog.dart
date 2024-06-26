import 'dart:math';

import 'package:cohabit/db/database_helper.dart';
import 'package:cohabit/db/db_habit.dart';
import 'package:cohabit/db/db_time_range.dart';
import 'package:cohabit/db/weekdays_enum.dart';
import 'package:flex_list/flex_list.dart';
import 'package:flutter/material.dart';

class NewHabitDialog extends StatefulWidget {
  final Habit? habit;
  NewHabitDialog({super.key, this.habit}) {
    // print("Selected Habit: ${habit?.name}");
  }

  @override
  State<NewHabitDialog> createState() => _NewHabitDialogState(habit);
}

class _NewHabitDialogState extends State<NewHabitDialog> {
  final Habit _srcHabit;
  Habit _habitStateData;
  final _isCreationMode;

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

  _NewHabitDialogState(Habit? habit)
      : _srcHabit = habit ?? Habit(name: ""),
        _habitStateData = habit ?? Habit(name: ""),
        _isCreationMode = habit == null {
    final habit = _habitStateData;

    if (!_isCreationMode) {
      habitNameController.text = habit.name;
    }
    habitNameController.addListener(() {
      _habitStateData = Habit(
          name: habitNameController.text,
          recurrances: _habitStateData.recurrances);
    });
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
    var appWidth = MediaQuery.of(buildctx).size.width;

    final dialogWidth = () {
      if (appWidth >= 700)
        return appWidth - 250;
      else
        return appWidth;
    }();

    void updateWeekdayOfPair(Weekday fromWeekday, Weekday toWeekday) {
      var srcRecurrance = _habitStateData.recurrances[fromWeekday.intVal];
      if (_habitStateData.recurrances.keys.contains(toWeekday.intVal)) {
        var destRecurrance = _habitStateData.recurrances[toWeekday.intVal];
        if (srcRecurrance != null) destRecurrance?.addAll(srcRecurrance);
      } else {
        if (srcRecurrance != null)
          _habitStateData.recurrances[toWeekday.intVal] = srcRecurrance;
      }
      _habitStateData.recurrances.remove(fromWeekday.intVal);
    }

    final getEntriesList = (BuildContext ctx) {
      var sortedEntries = _habitStateData.recurrances.entries.toList();
      sortedEntries.sort(((a, b) => a.key.compareTo(b.key)));
      return sortedEntries.map((recurrance_pair) {
        var weekday = Weekday.fromInt(recurrance_pair.key);
        var timeRanges = recurrance_pair.value;
        var list = weekdayDropdownItems.where((element) {
          if (_habitStateData.valid) {
            for (final pair in _habitStateData.recurrances.entries) {
              if (weekday == element.value) return true;
              if (Weekday.fromInt(pair.key) == element.value) return false;
            }
          }
          return true;
        }).toList();
        var timeRangesAsButtons = [
          ...timeRanges.map((e) => Container(
                margin: EdgeInsets.only(top: 8.0, bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                        onPressed: () {
                          updateTimeRange(buildctx, e, timeRanges);
                        },
                        child: Container(
                          padding: EdgeInsets.only(
                              left: 12, right: 12, top: 8, bottom: 8),
                          child: Container(
                            height: 20,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(TimeOfDay(
                                        hour: e.startHour,
                                        minute: e.startMinute)
                                    .format(context)),
                                VerticalDivider(),
                                Text(TimeOfDay(
                                        hour: e.endHour, minute: e.endMinute)
                                    .format(context))
                              ],
                            ),
                          ),
                        )),
                  ],
                ),
              )),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: ElevatedButton(
                onPressed: () {
                  showTimeRangePickers(buildctx, timeRanges);
                },
                child: Padding(
                    padding:
                        EdgeInsets.only(left: 4, right: 4, top: 8, bottom: 8),
                    child: Text("Add new time..."))),
          )
        ];
        final buttonStyle = ButtonStyle(
            backgroundColor: WidgetStateProperty.all(
                Theme.of(context).colorScheme.primaryContainer),
            shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4))));
        return Row(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: FlexList(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IntrinsicWidth(
                        child: DropdownButton(
                          padding: EdgeInsets.only(left: 8),
                          hint: Text("Select weekday"),
                          items: list,
                          value: weekday,
                          onChanged: (dropdownValue) {
                            if (dropdownValue is Weekday &&
                                dropdownValue != weekday) {
                              setState(() {
                                updateWeekdayOfPair(
                                    Weekday.fromInt(recurrance_pair.key),
                                    dropdownValue);
                              });
                            }
                            ;
                          },
                        ),
                      ),
                    ],
                  ),
                  IntrinsicWidth(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: timeRangesAsButtons,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                    style: buttonStyle,
                    onPressed: () {
                      setState(() {
                        _habitStateData.recurrances.remove(recurrance_pair.key);
                      });
                    },
                    icon: Icon(Icons.delete_forever)),
              ],
            ),
          ],
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
                shape: () {
                  if (appWidth < 425)
                    return LinearBorder();
                  else
                    return RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4)));
                }(),
                insetPadding: () {
                  if (appWidth < 425)
                    return EdgeInsets.zero;
                  else
                    return EdgeInsets.symmetric(
                        horizontal: 40.0, vertical: 24.0);
                }(),
                title: Text(_isCreationMode
                    ? "Create New Habit"
                    : "Modifying this Habit"),
                content: dialogContents(
                    dialogWidth, getEntriesList, scaffoldMessengerCtx),
                actions: dialogActions(scaffoldMessengerCtx),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> dialogActions(BuildContext scaffoldMessengerCtx) {
    return [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: TextButton(
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop();
            },
            child: const Text("Cancel")),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: FilledButton.tonal(
            onPressed: () {
              final weekdays = List.from(Weekday.values);
              for (var weedayInt in _habitStateData.recurrances.keys) {
                var weekday = Weekday.fromInt(weedayInt);
                weekdays.remove(weekday);
              }
              if (weekdays.isNotEmpty) {
                setState(() {
                  final _random = new Random();
                  var randomWeekday =
                      weekdays[_random.nextInt(weekdays.length)];
                  _habitStateData.recurrances[randomWeekday.intVal] = [];
                });
              }
            },
            child: Text("Add week")),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: FilledButton(
            onPressed: () async {
              if (habitNameController.text.isEmpty) {
                ScaffoldMessenger.of(scaffoldMessengerCtx).showSnackBar(
                  SnackBar(
                    content: const Text('Fill up the habit name first'),
                    duration: const Duration(seconds: 3),
                  ),
                );
                return;
              }

              if (_habitStateData.recurrances.isEmpty) {
                ScaffoldMessenger.of(scaffoldMessengerCtx).showSnackBar(
                  SnackBar(
                    content: const Text('Add a week first'),
                    duration: const Duration(seconds: 3),
                  ),
                );
                return;
              }

              bool timesEmpty = true;
              for (final times in _habitStateData.recurrances.values) {
                if (times.isNotEmpty) timesEmpty = false;
              }
              if (timesEmpty) {
                ScaffoldMessenger.of(scaffoldMessengerCtx).showSnackBar(
                  SnackBar(
                    content: const Text('Set time for the weeks first'),
                    duration: const Duration(seconds: 3),
                  ),
                );
                return;
              }

              Navigator.of(context, rootNavigator: true).pop();
              // TODO This delays the database transaction. It is better to split the transaction to smaller chunks so that other Futures don't starve.
              if (!_isCreationMode && _srcHabit.valid) {
                await DatabaseHelper.deleteHabit(_srcHabit);
              }
              await DatabaseHelper.insertHabit(_habitStateData);
            },
            child: Text(_isCreationMode ? "Create" : "Modify")),
      )
    ];
  }

  Center dialogContents(
      double dialogWidth,
      List<Row> getEntriesList(BuildContext ctx),
      BuildContext scaffoldMessengerCtx) {
    return Center(
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
              final habitRecurranceEntries = getEntriesList(context);
              return Expanded(
                child: ListView.separated(
                  scrollDirection: Axis.vertical,
                  shrinkWrap: true,
                  itemCount: habitRecurranceEntries.length,
                  itemBuilder: (context, index) {
                    return habitRecurranceEntries[index];
                  },
                  separatorBuilder: (context, index) => Divider(),
                ),
              );
            }(scaffoldMessengerCtx),
          ],
        ),
      ),
    );
  }

  void updateTimeRange(
      BuildContext context, TimeRange e, List<TimeRange> timeRanges) {
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
              final indexOf = timeRanges.indexOf(e);
              timeRanges.replaceRange(indexOf, indexOf + 1, [
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

  void showTimeRangePickers(BuildContext context, List<TimeRange> timeRanges) {
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
              timeRanges.add(timeRange);
            });
          }
        });
      }
    });
  }
}
