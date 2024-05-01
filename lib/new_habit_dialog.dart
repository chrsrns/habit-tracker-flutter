import 'dart:math';

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
  const NewHabitDialog({super.key});

  @override
  State<NewHabitDialog> createState() => _NewHabitDialogState();
}

class _NewHabitDialogState extends State<NewHabitDialog> {
  Map<Weekday, List<TimeRange>> recurrances = {};
  Map<Weekday, TextEditingController> controllers = {};

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

  final uiEntries = _RecurrancePairList();

  @override
  Widget build(BuildContext context) {
    final entriesList = uiEntries.items.map((recurrance_pair) {
      var list = weekdayDropdownItems.where((element) {
        for (final pair in uiEntries.items) {
          if (recurrance_pair.weekday == element.value) return true;
          if (pair.weekday == element.value) return false;
        }
        return true;
      }).toList();
      return Container(
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: DropdownButton(
                hint: Text("Select weekday"),
                items: list,
                value: recurrance_pair.weekday,
                onChanged: (value) {
                  if (value is Weekday)
                    setState(() {
                      uiEntries.updateWeekdayOfPair(recurrance_pair, value);
                    });
                },
              ),
            ),
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  ...recurrance_pair.timeranges.map((e) => Container(
                        margin: EdgeInsets.only(top: 8.0, bottom: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                                onPressed: () {},
                                child: Container(
                                  padding: EdgeInsets.only(
                                      left: 12, right: 12, top: 8, bottom: 8),
                                  child: Container(
                                    height: 20,
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Text("${e.start_time}"),
                                        VerticalDivider(),
                                        Text("${e.end_time}")
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
                        } else
                          showTimeRangePickers(context, recurrance_pair);
                      },
                      child: Text("Add new time..."))
                ],
              ),
            ),
            Divider()
          ],
        ),
      );
    }).toList();
    return AlertDialog(
      title: Text("Create New Habit"),
      content: Center(
        child: SizedBox(
          // TODO add animation to this dynamic sizing
          width: MediaQuery.of(context).size.width >= 700
              ? MediaQuery.of(context).size.width - 400
              : MediaQuery.of(context).size.width,
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Name of new habit',
                ),
              ),
              SizedBox(height: 8),
              Divider(),
              Expanded(
                child: ListView.separated(
                  scrollDirection: Axis.vertical,
                  shrinkWrap: true,
                  itemCount: entriesList.length,
                  itemBuilder: (context, index) {
                    return entriesList[index];
                  },
                  separatorBuilder: (context, index) => Divider(),
                ),
              )
            ],
          ),
        ),
      ),
      actions: [
        ElevatedButton(
            onPressed: () {
              int weekdayInt = Random().nextInt(7);
              Weekday weekday = Weekday.values[weekdayInt];

              TimeRange trange = TimeRange(
                  start_hour: Random().nextInt(23),
                  end_hour: Random().nextInt(23));

              final pair = _MutableRecurrancePair();
              // pair.timeranges.add(trange);

              setState(() {
                uiEntries.add(pair);
              });
            },
            child: Text("Add new button"))
      ],
    );
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
                  start_hour: startHour,
                  start_minute: startMinute,
                  end_hour: endHour,
                  end_minute: endMinute);
              recurrance_pair.timeranges.add(timeRange);
            });
          }
        });
      }
    });
  }
}
