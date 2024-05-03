class TimeRange {
  late int _startHour;
  late int _startMinute;

  late int _endHour;
  late int _endMinute;

  TimeRange(
      {required int startHour,
      int? startMinute,
      int? endHour,
      int? endMinute}) {
    this._startHour = startHour;
    this._startMinute = startMinute ?? 0;
    this._endHour = endHour ?? startHour;
    this._endMinute = endMinute ?? startMinute ?? 0;
  }

  int get startHour => _startHour;
  int get startMinute => _startMinute;
  int get endHour => _endHour;
  int get endMinute => _endMinute;

  String get startTime => "$_startHour:$_startMinute:00";
  String get endTime => "$_endHour:$_endMinute:00";

  void updateTime(
      {required int startHour,
      int? startMinute,
      int? endHour,
      int? endMinute}) {
    this._startHour = startHour;
    this._startMinute = startMinute ?? 0;
    this._endHour = endHour ?? startHour;
    this._endMinute = endMinute ?? startMinute ?? 0;
  }

  @override
  String toString() {
    return "$start_hour:$start_minute:00";
  }
}
