enum Weekday {
  monday("Monday"),
  tuesday("Tuesday"),
  wednesday("Wednesday"),
  thursday("Thursday"),
  friday("Friday"),
  saturday("Saturday"),
  sunday("Sunday");

  const Weekday(this.label);
  final String label;

  // THIS SHOULD BE USED IN PLACE OF `index` getter
  int get intVal => this.index + 1;

  // THIS SHOULD BE USED IN PLACE OF ACCESSING `values` array
  static Weekday fromInt(int val) {
    return Weekday.values[val - 1];
  }
}
