enum TableHabits {
  name;

  @override
  String toString() => this.name;
}

enum TableRecurrance {
  weekday,
  start_hour,
  start_minute,
  end_hour,
  end_minute;

  @override
  String toString() => this.name;
}

enum TableHabitRecurrance {
  habit_fr,
  weekday_id_fr,
  start_hour_fr,
  start_minute_fr,
  end_hour_fr,
  end_minute_fr;

  @override
  String toString() => this.name;
}
