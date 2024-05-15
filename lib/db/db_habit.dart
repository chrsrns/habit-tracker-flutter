import 'dart:convert';
import 'package:cohabit/db/db_time_range.dart';
import 'package:flutter/foundation.dart';

@immutable
class Habit {
  final String name;
  final Map<int, List<TimeRange>> recurrances;

  Habit({required this.name, Map<int, List<TimeRange>>? recurrances})
      : recurrances = recurrances ?? {};

  bool get valid {
    for (var recurrance in recurrances.entries) {
      for (var timeRange in recurrance.value) {
        if (timeRange.startHour > timeRange.endHour) return false;
        if (timeRange.startHour == timeRange.endHour &&
            timeRange.startMinute >= timeRange.endMinute) return false;
      }
    }
    return true;
  }

  // For Debugging
  Map<String, dynamic> _toJson() {
    return {
      'name': name,
      'recurrences': recurrances
          .map((key, value) => MapEntry(key.toString(), value.toString())),
    };
  }

  String toJsonString() {
    return jsonEncode(_toJson());
  }
}
