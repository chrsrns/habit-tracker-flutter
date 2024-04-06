import 'package:flutter/material.dart';

class Habit {
  final String name;
  final List<List<int>> recurrances;

  Habit({required this.name, this.recurrances = const []});
}

class HabitListPage extends StatefulWidget {
  const HabitListPage({super.key});

  @override
  State<HabitListPage> createState() => _HabitListPageState();
}

class _HabitListPageState extends State<HabitListPage> {
  // TODO Replace with actual data
  final habitsObjPlaceholder = [
    Habit(name: 'Exercise'),
    Habit(name: 'Write one code commit'),
    Habit(name: 'Drink water when peckish'),
    Habit(name: 'Write one Obsidian entry'),
    Habit(name: 'Finish one lesson'),
  ];
  @override
  Widget build(BuildContext context) {
    void deleteHabit(Habit habit) {
      setState(() {
        print(habitsObjPlaceholder.remove(habit));
        print(habitsObjPlaceholder);
      });
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Container(
            child: Text(
              "Your current habits",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                ...habitsObjPlaceholder.map((e) => ListTile(
                    tileColor: Theme.of(context).colorScheme.secondaryContainer,
                    title: Text(e.name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          style: ButtonStyle(
                              backgroundColor:
                                  MaterialStateProperty.all(Colors.white),
                              shape: MaterialStateProperty.all<
                                      RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4)))),
                          onPressed: () => deleteHabit(e),
                          icon: Icon(Icons.delete_forever),
                        )
                      ],
                    ))),
                SizedBox(
                  height: 56 + 16,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
