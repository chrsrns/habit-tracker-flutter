import 'dart:async';

import 'package:sqlite3/common.dart';
import 'package:testapp/db/db.dart';
import 'package:testapp/db/db_habit.dart';
import 'package:testapp/db/db_time_range.dart';
import 'package:testapp/db/table_columns.dart';

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
        var sql = """
            INSERT INTO recurrance(${TableRecurrance.weekday}, ${TableRecurrance.starttime}, ${TableRecurrance.endtime}) VALUES('$weekday', '${time.start_time}', '${time.end_time}') ON CONFLICT DO NOTHING;
            INSERT INTO habit_recurrance(${TableHabitRecurrance.habit_fr}, ${TableHabitRecurrance.weekday_id_fr}, ${TableHabitRecurrance.starttime_id_fr}, ${TableHabitRecurrance.endtime_id_fr}) VALUES('${habit.name}','$weekday','${time.start_time}', '${time.end_time}') ON CONFLICT DO NOTHING;
          """;
        print("[Executing insert SQL]");
        print(sql);
        db.execute(
          sql,
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
      final int weekdayFromDb = row['weekday_id_fr'] ?? -1;
      final rowStartTime = row[TableHabitRecurrance.starttime_id_fr.name] ?? '';
      final rowEndTime = row[TableHabitRecurrance.endtime_id_fr.name] ?? '';
      if (weekdayFromDb == -1 || rowStartTime == '' || rowEndTime == '') {
        print(
            "Invalid habit [wd: $weekdayFromDb, st: $rowStartTime, et: $rowEndTime]");
        continue;
      }

      final start_time = rowStartTime.split(':');
      final end_time = rowEndTime.split(':');

      final start_hour = int.tryParse(start_time[0]) ?? -1;
      final start_minute = int.tryParse(start_time[1]) ?? -1;

      final end_hour = int.tryParse(end_time[0]) ?? -1;
      final end_minute = int.tryParse(end_time[1]) ?? -1;

      if (!habit.recurrances.containsKey(weekdayFromDb))
        habit.recurrances[weekdayFromDb] = [];

      // TODO Shouldn't be null, but Dart safety checker says otherwise
      habit.recurrances[weekdayFromDb]?.add(TimeRange(
        start_hour: start_hour,
        start_minute: start_minute,
        end_hour: end_hour,
        end_minute: end_minute,
      ));
    }

    print('[Habit]: ');
    print(habit.toJsonString());
    return habit;
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
