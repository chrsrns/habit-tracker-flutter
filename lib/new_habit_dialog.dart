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
      items.firstWhere((element) => element == recurrancePair).weekday =
          weekday;
      items.remove(recurrancePair);
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
    return AlertDialog(
      title: Text("Create New Habit"),
      content: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width - 400,
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
                child: ListView(
                  scrollDirection: Axis.vertical,
                  shrinkWrap: true,
                  children: [
                    ...uiEntries.items.map((recurrance_pair) {
                      return Container(
                        margin: EdgeInsets.fromLTRB(0, 8, 0, 8),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: DropdownButton(
                                items: weekdayDropdownItems,
                                value: recurrance_pair.weekday,
                                onChanged: (value) {
                                  // recurrance_pair.weekday = value as Weekday?;
                                  if (value is Weekday)
                                    uiEntries.updateWeekdayOfPair(
                                        recurrance_pair, value);
                                  setState(() {});
                                },
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Column(
                                children: [
                                  ...recurrance_pair.timeranges
                                      .map((e) => Text(e.toString()))
                                ],
                              ),
                            )
                          ],
                        ),
                      );
                    })
                  ],
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

              final pair = _MutableRecurrancePair(weekday: weekday);
              pair.timeranges.add(trange);

              setState(() {
                uiEntries.add(pair);
              });
            },
            child: Text("Add new button"))
      ],
    );
  }
}
