import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as material;
import 'package:sqlite3/common.dart' as sqlite;
import 'package:testapp/database.dart';

class HabitListPage extends StatefulWidget {
  const HabitListPage({super.key});

  @override
  State<HabitListPage> createState() => _HabitListPageState();
}

class _HabitListPageState extends State<HabitListPage> {
  // TODO Replace with actual data
  Future<sqlite.ResultSet> _habitData =
      Future.value(sqlite.ResultSet([], [], []));

  @override
  void initState() {
    super.initState();
    _habitData = DatabaseHelper.retrieveHabits();
  }

  @override
  Widget build(BuildContext context) {
    void deleteHabit(String habit) {
      setState(() {
        DatabaseHelper.deleteHabitByName(habit);
        _habitData = DatabaseHelper.retrieveHabits();
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
          FutureBuilder<sqlite.ResultSet>(
            future: _habitData,
            builder: (BuildContext context,
                AsyncSnapshot<sqlite.ResultSet> snapshot) {
              List<Widget> children;
              if (snapshot.hasData) {
                var data = snapshot.data;
                if (data != null)
                  children = <Widget>[
                    ...data.map((e) => Card(
                          elevation: 5,
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: ListTile(
                                // tileColor:
                                //     Theme.of(context).colorScheme.secondaryContainer,
                                title: Text(e['name']),
                                trailing: material.Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      style: ButtonStyle(
                                          backgroundColor:
                                              MaterialStateProperty.all(
                                                  Colors.white),
                                          shape: MaterialStateProperty.all<
                                                  RoundedRectangleBorder>(
                                              RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          4)))),
                                      onPressed: () => deleteHabit(e['name']),
                                      icon: Icon(Icons.delete_forever),
                                    )
                                  ],
                                )),
                          ),
                        )),
                    SizedBox(
                      height: 56 + 16,
                    )
                  ];
                else
                  children = [];
              } else if (snapshot.hasError) {
                children = <Widget>[
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 60,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text('Error: ${snapshot.error}'),
                  ),
                ];
              } else {
                children = const <Widget>[
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Text('Awaiting result...'),
                  ),
                ];
              }
              return Expanded(
                child: ListView(
                  children: children,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
