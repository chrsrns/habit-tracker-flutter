import 'package:cohabit/new_habit_dialog.dart';
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

  @override
  void initState() {
    super.initState();
    // TODO  remove delay at some point
    _habitData = Future.delayed(
            Duration(seconds: 0), (() => DatabaseHelper.retrieveHabits()))
        .whenComplete(() => setState(() {
              _isLoading = false;
              print(_isLoading);
            }));

    DatabaseHelper.updates.then((value) => value
      ..listen((event) {
        setState(() {
          _habitData = Future.delayed(
                  Duration(seconds: 0), (() => DatabaseHelper.retrieveHabits()))
              .whenComplete(() => setState(() {
                    _isLoading = false;
                    print(_isLoading);
                  }));
        });
      }));
  }

  @override
  Widget build(BuildContext context) {
    void deleteHabit(String habit) {
      setState(() {
        _isLoading = true;
        print(_isLoading);
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
    var result;
    if (data != null)
      result = <Widget>[
        ...data.map((e) {
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
                  DatabaseHelper.retrieveHabit(e['name']).then((value) {
                    if (value != null) {
                      showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return NewHabitDialog(habit: value);
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
                onPressed: () => deleteHabit(e['name']),
                icon: Icon(Icons.delete_forever),
              )
            ],
          );
          return Card(
            elevation: 5,
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: ListTile(
                  // tileColor:
                  //     Theme.of(context).colorScheme.secondaryContainer,
                  title: Text(e['name']),
                  trailing: trailingButtonRow),
            ),
          );
        }),
        SizedBox(
          height: 56 + 16,
        )
      ];
    else
      result = [];
    return result;
  }
}
