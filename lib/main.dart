import 'dart:ffi';

import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class Habit {
  final String name;
  final List<List<Int>> recurrances;

  Habit({required this.name, this.recurrances = const []});
}

class NavDestinations {
  const NavDestinations(this.label, this.page, this.icon, this.selectedIcon);

  final String label;
  final Widget page;
  final Widget icon;
  final Widget selectedIcon;
}

const List<NavDestinations> destinations = <NavDestinations>[
  NavDestinations('Habits', HabitListPage(), Icon(Icons.widgets_outlined),
      Icon(Icons.widgets)),
  NavDestinations('Settings', Placeholder(), Icon(Icons.settings_outlined),
      Icon(Icons.settings)),
];

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
      ),
      home: const MyHomePage(title: 'CoHabit'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var _selectedIndex = 0; // ← Add this property.
  late bool _showNavRail;
  var _expandNavRail = false;

  void _handleNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
          onPressed: () => print("TODO"), //TODO
          tooltip: 'Increment',
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
