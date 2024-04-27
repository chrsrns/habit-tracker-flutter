enum TableHabits {
  name;

  @override
  String toString() => this.name;
}

enum TableRecurrance {
  weekday,
  starttime,
  endtime;

  @override
  String toString() => this.name;
}

enum TableHabitRecurrance {
  habit_fr,
  weekday_id_fr,
  starttime_id_fr,
  endtime_id_fr;

  @override
  String toString() => this.name;
}
