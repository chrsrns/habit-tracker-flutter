class TimeRange {
  final int start_hour;
  final int start_minute;

  final int end_hour;
  final int end_minute;

  TimeRange(
      {required this.start_hour,
      this.start_minute = 0,
      end_hour,
      this.end_minute = 0})
      : this.end_hour = start_hour;

  String get start_time => "$start_hour:$start_minute:00";

  String get end_time => "$end_hour:$end_minute:00";

  @override
  String toString() {
    return "$start_hour:$start_minute:00";
  }
}
