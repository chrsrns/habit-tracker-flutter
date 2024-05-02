class TimeRange {
  late int _start_hour;
  late int _start_minute;

  late int _end_hour;
  late int _end_minute;

  TimeRange(
      {required int start_hour,
      int? start_minute,
      int? end_hour,
      int? end_minute}) {
    this._start_hour = start_hour;
    this._start_minute = start_minute ?? 0;
    this._end_hour = end_hour ?? start_hour;
    this._end_minute = end_minute ?? start_minute ?? 0;
  }

  int get start_hour => _start_hour;
  int get start_minute => _start_minute;
  int get end_hour => _end_hour;
  int get end_minute => _end_minute;

  String get start_time => "$_start_hour:$_start_minute:00";

  String get end_time => "$_end_hour:$_end_minute:00";

  @override
  String toString() {
    return "$start_hour:$start_minute:00";
  }
}
