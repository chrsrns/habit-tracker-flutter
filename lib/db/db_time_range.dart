import 'package:flutter/foundation.dart';

@immutable
class TimeRange {
  final int _startHour;
  final int? _startMinute;

  final int? _endHour;
  final int? _endMinute;

  TimeRange(
      {required int startHour, int? startMinute, int? endHour, int? endMinute})
      : _startHour = startHour,
        _startMinute = startMinute,
        _endHour = endHour,
        _endMinute = endMinute;

  int get startHour => _startHour;
  int get startMinute => _startMinute ?? 0;
  int get endHour => _endHour ?? _startHour;
  int get endMinute => _endMinute ?? _startMinute ?? 0;

  String get startTime => "$_startHour:$_startMinute:00";
  String get endTime => "$_endHour:$_endMinute:00";

  @override
  String toString() {
    final startTimeObj = DateTime(0, 1, 1, startHour, startMinute);
    final endTimeObj = DateTime(0, 1, 1, endHour, endMinute);

    var startTimeStr = startTimeObj.toIso8601String().split('T')[1];
    if (startTimeStr.length > 0) {
      startTimeStr = startTimeStr.substring(0, startTimeStr.length - 1);
    }
    var endTimeStr = endTimeObj.toIso8601String().split('T')[1];
    if (endTimeStr.length > 0) {
      endTimeStr = endTimeStr.substring(0, endTimeStr.length - 1);
    }

    return "$startTimeStr|$endTimeStr";
  }
}
