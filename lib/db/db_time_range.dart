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
    return "$_startHour:$_startMinute:00|$_endHour:$_endMinute:00";
  }
}
