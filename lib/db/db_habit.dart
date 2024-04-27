import 'dart:convert';
import 'package:cohabit/db/db_time_range.dart';

class Habit {
  final String name;
  Map<int, List<TimeRange>> recurrances = {};

  Habit({required this.name, Map<int, List<TimeRange>>? recurrances})
      : recurrances = recurrances ?? {};

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'recurrences': recurrances
          .map((key, value) => MapEntry(key.toString(), value.toString())),
    };
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }
}
