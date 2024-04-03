import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
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
  late bool _showNavDrawer;

  void _handleNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget buildNavDrawerScaffold() {
    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        appBar: AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text(widget.title),
        ),
        drawer: NavigationDrawer(
          onDestinationSelected: _handleNavTap,
          selectedIndex: _selectedIndex,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 16, 16, 10),
              child: Text(
                'Header',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            ...destinations.map(
              (NavDestinations destination) {
                return NavigationDrawerDestination(
                  label: Text(destination.label),
                  icon: destination.icon,
                  selectedIcon: destination.selectedIcon,
                );
              },
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(28, 16, 28, 10),
              child: Divider(),
            ),
          ],
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
    _showNavDrawer = MediaQuery.of(context).size.width >= 450;
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.

    return _showNavDrawer ? buildNavDrawerScaffold() : buildBottomNavScaffold();
  }
}

class HabitListPage extends StatelessWidget {
  const HabitListPage({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO Replace with actual data
    final habitsPlaceholder = [
      "Exercise",
      "Write one code commit",
      "Drink water when peckish",
      "Write one Obsidian entry",
      "Finish one lesson"
    ];
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          Text(
            "Your current habits",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
          ),
          ...habitsPlaceholder.map((e) => ListTile(
              title: Text(e),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all(Colors.white),
                        shape:
                            MaterialStateProperty.all<RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4)))),
                    onPressed: () => print("Button pressed"),
                    icon: Icon(Icons.delete_forever),
                  )
                ],
              )))
        ],
      ),
    );
  }
}
