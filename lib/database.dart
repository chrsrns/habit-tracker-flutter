import 'dart:async';
import 'dart:convert';

import 'package:sqlite3/common.dart';
import 'package:testapp/db/db.dart';

class Habit {
  final String name;
  Map<int, List<String>> recurrances = {};

  Habit({required this.name, recurrances}) : recurrances = recurrances ?? {};

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'recurrences':
          recurrances.map((key, value) => MapEntry(key.toString(), value)),
    };
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }
}

class DatabaseHelper {
  static Future<CommonDatabase> get _db async {
    return sqliteDb;
  }

  static Future<void> initDB() async {
    await openDb();
    return;
  }

  static Future<int> insertHabit(Habit habit) async {
    final db = await _db;

    db.execute(
      """
        INSERT INTO habits(name) VALUES('${habit.name}')
          ON CONFLICT DO NOTHING;
      """,
    );

    for (var weekday in habit.recurrances.keys) {
      final times = habit.recurrances[weekday];
      if (times == null) continue;

      for (var time in times) {
        db.execute(
          """
            INSERT INTO recurrance(weekday, time) VALUES('$weekday', '$time') ON CONFLICT DO NOTHING;
            INSERT INTO habit_recurrance(habit_fr,weekday_id_fr,time_id_fr) VALUES('${habit.name}','$weekday','$time') ON CONFLICT DO NOTHING;
          """,
        );
      }
    }

    return 0; //TODO Aggregate all the results to one
  }

  static Future<Habit?> retrieveHabit(String name) async {
    final db = await _db;
    final habitFromDb =
        await db.select("SELECT * FROM habits WHERE name='$name';");
    final recurrancesFromDb = await db
        .select("SELECT * FROM habit_recurrance WHERE habit_fr='$name';");

    // print('[Habit # from SELECT]: ${habitFromDb.length}');
    if (habitFromDb.length != 1) return null;
    final habit = Habit(name: name);
    for (final Row row in recurrancesFromDb) {
      if (row['weekday_id_fr'] == null || row['time_id_fr'] == null) continue;
      final int weekdayFromDb = row['weekday_id_fr'];

      if (!habit.recurrances.containsKey(weekdayFromDb))
        habit.recurrances[weekdayFromDb] = [];

      // TODO Shouldn't be null, but Dart safety checker says otherwise
      habit.recurrances[weekdayFromDb]?.add(row['time_id_fr']);
    }

    // print('[Habit]: ');
    // print(habit.toJsonString());
  }

  static Future<ResultSet> retrieveHabits() async {
    final db = await _db;

    var result = await db.select('SELECT * FROM habits;');
    // print("Habits #: ${result.length}");
    // for (final Row row in result) {
    //   print('Habit[name: ${row['name']}]');
    // }

    return result;
  }

  static Future deleteHabit(Habit habit) async {
    final db = await _db;

    db.execute("DELETE FROM habits WHERE name='${habit.name}'");
  }

  static Future deleteHabitByName(String habit) async {
    final db = await _db;

    db.execute("DELETE FROM habits WHERE name='${habit}'");
  }
}
