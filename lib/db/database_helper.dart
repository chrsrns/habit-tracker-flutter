import 'dart:async';

import 'package:sqlite3/common.dart';
import 'package:sqlite3/common.dart' as sqlite3Com;
import 'package:cohabit/db/db.dart';
import 'package:cohabit/db/db_habit.dart';
import 'package:cohabit/db/db_time_range.dart';
import 'package:cohabit/db/table_columns.dart';

class DatabaseHelper {
  static Future<CommonDatabase> get _db async {
    return sqliteDb;
  }

  static Future<void> initDB() async {
    await openDb();
    return;
  }

  static Future<Stream<SqliteUpdate>> get updates async {
    final db = await _db;
    return db.updates;
  }

  static Future<int> insertHabit(Habit habit) async {
    final db = await _db;

    db.execute(
      """
        PRAGMA foreign_keys = ON;
        INSERT INTO habits(name) VALUES('${habit.name}')
          ON CONFLICT DO NOTHING;
      """,
    );

    for (var weekday in habit.recurrances.keys) {
      final times = habit.recurrances[weekday];
      if (times == null) continue;

      for (var time in times) {
        var sql = """
          PRAGMA foreign_keys = ON;
          INSERT INTO recurrance(
            ${TableRecurrance.weekday}, 
            ${TableRecurrance.start_hour}, 
            ${TableRecurrance.start_minute}, 
            ${TableRecurrance.end_hour},
            ${TableRecurrance.end_minute}) 
            VALUES(
              '$weekday', 
              '${time.startHour}',
              '${time.startMinute}',
              '${time.endHour}',
              '${time.endMinute}')
              ON CONFLICT DO NOTHING;
          INSERT INTO habit_recurrance(
            ${TableHabitRecurrance.habit_fr}, 
            ${TableHabitRecurrance.weekday_id_fr}, 
            ${TableHabitRecurrance.start_hour_fr}, 
            ${TableHabitRecurrance.start_minute_fr}, 
            ${TableHabitRecurrance.end_hour_fr}, 
            ${TableHabitRecurrance.end_minute_fr}) 
            VALUES(
              '${habit.name}',
              '$weekday',
              '${time.startHour}', 
              '${time.startMinute}', 
              '${time.endHour}', 
              '${time.endMinute}') 
              ON CONFLICT DO NOTHING;
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
    for (final sqlite3Com.Row row in recurrancesFromDb) {
      final int weekdayFromDb =
          row['${TableHabitRecurrance.weekday_id_fr}'] ?? -1;
      final getColVal = (String colName) {
        final rowVal = row[colName];
        if (rowVal is int)
          return rowVal;
        else
          return -1;
      };
      final rowStartHour = getColVal('${TableHabitRecurrance.start_hour_fr}');
      final rowStartMinute =
          getColVal('${TableHabitRecurrance.start_minute_fr}');
      final rowEndHour = getColVal('${TableHabitRecurrance.end_hour_fr}');
      final rowEndMinute = getColVal('${TableHabitRecurrance.end_minute_fr}');
      if (weekdayFromDb == -1 ||
          rowStartHour == -1 ||
          rowStartMinute == -1 ||
          rowEndHour == -1 ||
          rowEndMinute == -1) {
        continue;
      }
      if (!habit.recurrances.containsKey(weekdayFromDb))
        habit.recurrances[weekdayFromDb] = [];

      // TODO Shouldn't be null, but Dart safety checker says otherwise
      habit.recurrances[weekdayFromDb]?.add(TimeRange(
        startHour: rowStartHour,
        startMinute: rowStartMinute,
        endHour: rowEndHour,
        endMinute: rowEndMinute,
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

    db.execute('''
      PRAGMA foreign_keys = ON;
      DELETE FROM habits WHERE name='${habit.name}'
    ''');
  }

  static Future deleteHabitByName(String habit) async {
    final db = await _db;

    db.execute('''
      PRAGMA foreign_keys = ON;
      DELETE FROM habits WHERE name='${habit}';
    ''');
  }

  // TODO current implementation only checks upcoming habit for the current week. Should be changed.
  static Future<Habit?> get upcomingHabit async {
    final db = await _db;
    final currentTime = DateTime.now();

    var sql = '''
      SELECT *
        FROM habit_recurrance
        WHERE ${TableHabitRecurrance.weekday_id_fr} >= ${currentTime.weekday} 
        AND ${TableHabitRecurrance.start_hour_fr} >= ${currentTime.hour} 
        ORDER BY ${TableHabitRecurrance.weekday_id_fr} ASC,
          ${TableHabitRecurrance.start_hour_fr} ASC,
          ${TableHabitRecurrance.start_minute_fr} ASC
        LIMIT 1;
    ''';
    print(sql);
    var upcomingTimeOr = await db.select(sql);

    if (upcomingTimeOr.length != 1) return null;

    for (final sqlite3Com.Row row in upcomingTimeOr) {
      final getColVal = (String colName) {
        final rowVal = row[colName];
        if (rowVal is int)
          return rowVal;
        else
          return -1;
      };
      final rowStartHour = getColVal('${TableHabitRecurrance.start_hour_fr}');
      final rowStartMinute =
          getColVal('${TableHabitRecurrance.start_minute_fr}');
      final rowEndHour = getColVal('${TableHabitRecurrance.end_hour_fr}');
      final rowEndMinute = getColVal('${TableHabitRecurrance.end_minute_fr}');
      if (rowStartHour == -1 ||
          rowStartMinute == -1 ||
          rowEndHour == -1 ||
          rowEndMinute == -1) {
        continue;
      }

      final timeRange = TimeRange(
        startHour: rowStartHour,
        startMinute: rowStartMinute,
        endHour: rowEndHour,
        endMinute: rowEndMinute,
      );

      final habit =
          Habit(name: row['${TableHabitRecurrance.habit_fr}'], recurrances: {
        row['${TableHabitRecurrance.weekday_id_fr}']: [timeRange]
      });

      return habit;
    }
    return null;
  }
}
