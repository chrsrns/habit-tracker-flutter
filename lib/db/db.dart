import 'package:sqlite3/common.dart' show CommonDatabase;
import 'package:cohabit/db/table_columns.dart';
import 'sqlite3/sqlite3.dart' show openSqliteDb;

late CommonDatabase sqliteDb;

Future<void> openDb() async {
  sqliteDb = await openSqliteDb();

  final currentDbVersion = 1;

  final dbVersion =
      sqliteDb.select('PRAGMA user_version').first['user_version'];

  print('DB version: $dbVersion');

  if (dbVersion < currentDbVersion) {
    var sql = '''
      BEGIN;

      CREATE TABLE habits (
        ${TableHabits.name} VARCHAR(200) PRIMARY KEY
      );
      CREATE TABLE recurrance (
        ${TableRecurrance.weekday} TINYINT NOT NULL,
        ${TableRecurrance.start_hour} TINYINT NOT NULL,
        ${TableRecurrance.start_minute} TINYINT NOT NULL,
        ${TableRecurrance.end_hour} TINYINT NOT NULL,
        ${TableRecurrance.end_minute} TINYINT NOT NULL,
        PRIMARY KEY(
          ${TableRecurrance.weekday}, 
          ${TableRecurrance.start_hour}, 
          ${TableRecurrance.start_minute}, 
          ${TableRecurrance.end_hour}, 
          ${TableRecurrance.end_minute})
      );
      CREATE TABLE habit_recurrance (
        ${TableHabitRecurrance.habit_fr} INTEGER NOT NULL,
        ${TableHabitRecurrance.weekday_id_fr} TINYINT NOT NULL,
        ${TableHabitRecurrance.start_hour_fr} TINYINT NOT NULL,
        ${TableHabitRecurrance.start_minute_fr} TINYINT NOT NULL,
        ${TableHabitRecurrance.end_hour_fr} TINYINT NOT NULL,
        ${TableHabitRecurrance.end_minute_fr} TINYINT NOT NULL,
        CONSTRAINT habit_recurrance_habit_fk 
          FOREIGN KEY(${TableHabitRecurrance.habit_fr}) 
          REFERENCES habits(${TableHabits.name}) 
          ON DELETE CASCADE,
        CONSTRAINT habit_recurrance_weekday_fk 
          FOREIGN KEY(
            ${TableHabitRecurrance.weekday_id_fr}, 
            ${TableHabitRecurrance.start_hour_fr}, 
            ${TableHabitRecurrance.start_minute_fr}, 
            ${TableHabitRecurrance.end_hour_fr},
            ${TableHabitRecurrance.end_minute_fr}) 
          REFERENCES recurrance(
            ${TableRecurrance.weekday}, 
            ${TableRecurrance.start_hour},
            ${TableRecurrance.start_minute},
            ${TableRecurrance.end_hour},
            ${TableRecurrance.end_minute})
          ON DELETE CASCADE,
        CONSTRAINT habit_recurrance_pk 
          PRIMARY KEY(
            ${TableHabitRecurrance.habit_fr}, 
            ${TableHabitRecurrance.weekday_id_fr}, 
            ${TableHabitRecurrance.start_hour_fr}, 
            ${TableHabitRecurrance.start_minute_fr}, 
            ${TableHabitRecurrance.end_hour_fr},
            ${TableHabitRecurrance.end_minute_fr})
      );
      PRAGMA user_version = $currentDbVersion;
      COMMIT;
    ''';
    // print(sql);
    sqliteDb.execute(sql);
  }
}
