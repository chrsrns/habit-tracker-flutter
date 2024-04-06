import 'package:flutter/material.dart';
import 'package:testapp/habit.dart';

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
