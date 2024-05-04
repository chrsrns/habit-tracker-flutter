import 'dart:convert';
import 'package:cohabit/db/db_time_range.dart';
import 'package:flutter/foundation.dart';

@immutable
class Habit {
  final String name;
  final Map<int, List<TimeRange>> recurrances;

  Habit({required this.name, Map<int, List<TimeRange>>? recurrances})
      : recurrances = recurrances ?? {};

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
