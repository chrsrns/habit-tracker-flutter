import 'dart:async';

import 'package:cron/cron.dart';
import 'package:flutter/material.dart';
import 'package:sqlite3/common.dart';
import 'package:sqlite3/common.dart' as sqlite3Com;
import 'package:cohabit/db/db.dart';
import 'package:cohabit/db/db_habit.dart';
import 'package:cohabit/db/db_time_range.dart';
import 'package:cohabit/db/table_columns.dart';

class DatabaseHelper {
  static Cron _cron = Cron();
  static Future<CommonDatabase> get _db async {
    return sqliteDb;
  }

  static ResultSet? _habitsSortedCache;
  static var _habitsSortedController = StreamController<ResultSet?>();
  static StreamSubscription<void> _habitsSortedDelayer =
      Future.value().asStream().listen((_) {});
  static Future<void> _updateHabitsSorted() async {
    await _habitsSortedDelayer.cancel();
    _habitsSortedDelayer =
        Future.delayed(Durations.short1).asStream().listen((event) async {
      var retrievedHabitsSorted = await retrieveHabitsSorted();
      _habitsSortedCache = retrievedHabitsSorted;

      var habitRow = _habitsSortedCache?.firstOrNull;
      if (_habitsSortedCache != null && habitRow != null) {
        print("[${DateTime.now()}] Schedule on start of upcoming habit");
        var startHour =
            habitRow['${TableHabitRecurrance.start_hour_fr}'] as int;
        var startMinute =
            habitRow['${TableHabitRecurrance.start_minute_fr}'] as int;
        _updateOnHabitStart = _cron
            .schedule(Schedule(hours: startHour, minutes: startMinute), () {
          _updateOnHabitStart?.cancel();
          print("[${DateTime.now()}] Updating streams");
          _updateHabitsSorted();
          _updateOngoingHabit();
        });
      }
      _habitsSortedController.add(retrievedHabitsSorted);
    });
  }

  static Stream<ResultSet?> get habitsSorted => _habitsSortedController.stream;

  static Habit? _ongoingHabitCache;
  static var _ongoingHabitController = StreamController<List<Habit>?>();
  static StreamSubscription<void> _ongoingHabitDelayer =
      Future.value().asStream().listen((_) {});
  static Future<void> _updateOngoingHabit() async {
    await _ongoingHabitDelayer.cancel();
    _ongoingHabitDelayer =
        Future.delayed(Durations.short1).asStream().listen((event) async {
      var retrievedOngoingHabit = await _ongoingHabit;
      _ongoingHabitCache = retrievedOngoingHabit.firstOrNull;
      if (_ongoingHabitCache != null) {
        var recurranceOrNull = _ongoingHabitCache
            ?.recurrances[_ongoingHabitCache?.recurrances.keys.firstOrNull]
            ?.first;
        if (recurranceOrNull != null) {
          print("[${DateTime.now()}] Schedule on end of ongoing habit");
          _updateOnHabitEnd = _cron.schedule(
              Schedule(
                  hours: recurranceOrNull.endHour,
                  minutes: recurranceOrNull.endMinute), () {
            _updateOnHabitEnd?.cancel();
            print("[${DateTime.now()}] Updating streams");
            _updateHabitsSorted();
            _updateOngoingHabit();
          });
        }
      }
      _ongoingHabitController.add(retrievedOngoingHabit);
    });
  }

  static Stream<List<Habit>?> get ongoingHabit =>
      _ongoingHabitController.stream;

  static ScheduledTask? _updateOnHabitStart = null;
  static ScheduledTask? _updateOnHabitEnd = null;

  static Future<void> initDB() async {
    await openDb();
    final db = await _db;

    _updateHabitsSorted();
    _updateOngoingHabit();
    db.updates.listen((event) async {
      print("[${DateTime.now()}] Updates on database");
      if (event.tableName == "habit_recurrance") {
        print("[${DateTime.now()}] Updates on habit_recurrance");
        _updateOngoingHabit();
        _updateHabitsSorted();
      }
    });
    return;
  }

  static Future<Stream<SqliteUpdate>> get updates async {
    final db = await _db;
    return db.updates;
  }

  static Future<bool> insertHabit(Habit habit) async {
    if (!habit.valid) return false;
    final db = await _db;

    db.execute("BEGIN;");

    db.execute("""
        INSERT INTO habits(name) VALUES('${habit.name}')
          ON CONFLICT DO NOTHING;
      """);

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
        // print("[Executing insert SQL]");
        // print(sql);
        db.execute(sql);
      }
    }
    db.execute("COMMIT;");

    return true; //TODO Aggregate all the results to one
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

    // print('[Habit]: ');
    // print(habit.toJsonString());
    return habit;
  }

  static Future<ResultSet> retrieveHabits() async {
    final db = await _db;

    var result = await db.select('''
      SELECT * FROM habit_recurrance
        ORDER BY ${TableHabitRecurrance.weekday_id_fr} ASC,
          ${TableHabitRecurrance.start_hour_fr} ASC,
          ${TableHabitRecurrance.start_minute_fr} ASC;
    ''');
    // print("Habits #: ${result.length}");
    // for (final Row row in result) {
    //   print('Habit[name: ${row['name']}]');
    // }

    return result;
  }

  static Future<ResultSet> retrieveHabitsSorted() async {
    final db = await _db;
    final currentTime = DateTime.now();

    var sql = '''
      WITH RankedResults AS (
        SELECT 
            *, 
            ROW_NUMBER() OVER (
              PARTITION BY ${TableHabitRecurrance.habit_fr} 
              ) AS rn_duplicate
        FROM (
          SELECT *, ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) as rn_order FROM (

            SELECT * FROM (
              SELECT *
                FROM habit_recurrance
                WHERE ${TableHabitRecurrance.weekday_id_fr} = ${currentTime.weekday} 
                AND (
                  ${TableHabitRecurrance.start_hour_fr} < ${currentTime.hour} 
                  OR
                  (
                    ${TableHabitRecurrance.start_hour_fr} = ${currentTime.hour}
                    AND
                    ${TableHabitRecurrance.start_minute_fr} <= ${currentTime.minute} 
                  )
                )
                AND (
                  ${TableHabitRecurrance.end_hour_fr} > ${currentTime.hour} 
                  OR
                  (
                    ${TableHabitRecurrance.end_hour_fr} = ${currentTime.hour}
                    AND
                    ${TableHabitRecurrance.end_minute_fr} > ${currentTime.minute} 
                  )
                )
                ORDER BY ${TableHabitRecurrance.weekday_id_fr} ASC,
                  ${TableHabitRecurrance.start_hour_fr} ASC,
                  ${TableHabitRecurrance.start_minute_fr} ASC
                LIMIT 1
            )

            UNION ALL

            SELECT * FROM (
              SELECT *
                FROM habit_recurrance
                WHERE ${TableHabitRecurrance.weekday_id_fr} = ${currentTime.weekday} 
                AND ${TableHabitRecurrance.start_hour_fr} = ${currentTime.hour} 
                AND ${TableHabitRecurrance.start_minute_fr} >= ${currentTime.minute} 
                ORDER BY ${TableHabitRecurrance.weekday_id_fr} ASC,
                  ${TableHabitRecurrance.start_hour_fr} ASC,
                  ${TableHabitRecurrance.start_minute_fr} ASC
            )

            UNION ALL

            SELECT * FROM (
              SELECT *
                FROM habit_recurrance
                WHERE ${TableHabitRecurrance.weekday_id_fr} = ${currentTime.weekday} 
                AND ${TableHabitRecurrance.start_hour_fr} > ${currentTime.hour} 
                ORDER BY ${TableHabitRecurrance.weekday_id_fr} ASC,
                  ${TableHabitRecurrance.start_hour_fr} ASC,
                  ${TableHabitRecurrance.start_minute_fr} ASC
            )

            UNION ALL

            SELECT * FROM (
              SELECT *
                FROM habit_recurrance
                WHERE ${TableHabitRecurrance.weekday_id_fr} > ${currentTime.weekday} 
                ORDER BY ${TableHabitRecurrance.weekday_id_fr} ASC,
                  ${TableHabitRecurrance.start_hour_fr} ASC,
                  ${TableHabitRecurrance.start_minute_fr} ASC
            )
            
            UNION ALL

            SELECT * FROM (
              SELECT *
                FROM habit_recurrance
                WHERE ${TableHabitRecurrance.weekday_id_fr} < ${currentTime.weekday} 
                ORDER BY ${TableHabitRecurrance.weekday_id_fr} ASC,
                  ${TableHabitRecurrance.start_hour_fr} ASC,
                  ${TableHabitRecurrance.start_minute_fr} ASC
            )
            
            UNION ALL

            SELECT * FROM (
              SELECT *
                FROM habit_recurrance
                WHERE ${TableHabitRecurrance.weekday_id_fr} = ${currentTime.weekday} 
                AND ${TableHabitRecurrance.start_hour_fr} < ${currentTime.hour} 
                ORDER BY ${TableHabitRecurrance.weekday_id_fr} ASC,
                  ${TableHabitRecurrance.start_hour_fr} ASC,
                  ${TableHabitRecurrance.start_minute_fr} ASC
            )

            UNION ALL 

            SELECT * FROM (
              SELECT *
                FROM habit_recurrance
                WHERE ${TableHabitRecurrance.weekday_id_fr} = ${currentTime.weekday} 
                AND ${TableHabitRecurrance.start_hour_fr} = ${currentTime.hour} 
                AND ${TableHabitRecurrance.start_minute_fr} < ${currentTime.minute} 
                ORDER BY ${TableHabitRecurrance.weekday_id_fr} ASC,
                  ${TableHabitRecurrance.start_hour_fr} ASC,
                  ${TableHabitRecurrance.start_minute_fr} ASC
            )
          )
        )
      )
      SELECT *
      FROM RankedResults
      WHERE rn_duplicate = 1
      ORDER BY rn_order ASC
    ''';
    var result = await db.select(sql);
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

    var sql = '''
      PRAGMA foreign_keys = ON;
      DELETE FROM habits WHERE name='${habit}';
    ''';
    db.execute(sql);
  }

  static Future<Habit?> get upcomingHabit async {
    final db = await _db;
    final currentTime = DateTime.now();

    var sql = '''
      SELECT * FROM (
        SELECT * FROM (
          SELECT *
            FROM habit_recurrance
            WHERE ${TableHabitRecurrance.weekday_id_fr} = ${currentTime.weekday} 
            AND ${TableHabitRecurrance.start_hour_fr} = ${currentTime.hour} 
            AND ${TableHabitRecurrance.start_minute_fr} > ${currentTime.minute} 
            ORDER BY ${TableHabitRecurrance.weekday_id_fr} ASC,
              ${TableHabitRecurrance.start_hour_fr} ASC,
              ${TableHabitRecurrance.start_minute_fr} ASC
        )
         
        UNION ALL

        SELECT * FROM (
          SELECT *
            FROM habit_recurrance
            WHERE ${TableHabitRecurrance.weekday_id_fr} = ${currentTime.weekday} 
            AND ${TableHabitRecurrance.start_hour_fr} > ${currentTime.hour} 
            ORDER BY ${TableHabitRecurrance.weekday_id_fr} ASC,
              ${TableHabitRecurrance.start_hour_fr} ASC,
              ${TableHabitRecurrance.start_minute_fr} ASC
        )

        UNION ALL

        SELECT * FROM (
          SELECT *
            FROM habit_recurrance
            WHERE ${TableHabitRecurrance.weekday_id_fr} > ${currentTime.weekday} 
            ORDER BY ${TableHabitRecurrance.weekday_id_fr} ASC,
              ${TableHabitRecurrance.start_hour_fr} ASC,
              ${TableHabitRecurrance.start_minute_fr} ASC
        )
        
        UNION ALL

        SELECT * FROM (
          SELECT *
            FROM habit_recurrance
            WHERE ${TableHabitRecurrance.weekday_id_fr} < ${currentTime.weekday} 
            ORDER BY ${TableHabitRecurrance.weekday_id_fr} ASC,
              ${TableHabitRecurrance.start_hour_fr} ASC,
              ${TableHabitRecurrance.start_minute_fr} ASC
        )
        
        UNION ALL

        SELECT * FROM (
          SELECT *
            FROM habit_recurrance
            WHERE ${TableHabitRecurrance.weekday_id_fr} = ${currentTime.weekday} 
            AND ${TableHabitRecurrance.start_hour_fr} < ${currentTime.hour} 
            ORDER BY ${TableHabitRecurrance.weekday_id_fr} ASC,
              ${TableHabitRecurrance.start_hour_fr} ASC,
              ${TableHabitRecurrance.start_minute_fr} ASC
        )
      )
      LIMIT 1;
    ''';
    // print(sql);
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

  static Future<List<Habit>> get _ongoingHabit async {
    final db = await _db;
    final currentTime = DateTime.now();

    var sql = '''
    SELECT *
      FROM habit_recurrance
      WHERE ${TableHabitRecurrance.weekday_id_fr} = ${currentTime.weekday} 
      AND (
        ${TableHabitRecurrance.start_hour_fr} < ${currentTime.hour} 
        OR
        (
          ${TableHabitRecurrance.start_hour_fr} = ${currentTime.hour}
          AND
          ${TableHabitRecurrance.start_minute_fr} <= ${currentTime.minute} 
        )
      )
      AND (
        ${TableHabitRecurrance.end_hour_fr} > ${currentTime.hour} 
        OR
        (
          ${TableHabitRecurrance.end_hour_fr} = ${currentTime.hour}
          AND
          ${TableHabitRecurrance.end_minute_fr} > ${currentTime.minute} 
        )
      )
      ORDER BY ${TableHabitRecurrance.weekday_id_fr} ASC,
        ${TableHabitRecurrance.start_hour_fr} ASC,
        ${TableHabitRecurrance.start_minute_fr} ASC
      LIMIT 1;
    ''';
    // print(sql);
    var ongoingTimeOr = await db.select(sql);

    List<Habit> result = [];

    for (final sqlite3Com.Row row in ongoingTimeOr) {
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

      result.add(habit);
    }
    return result;
  }
}
