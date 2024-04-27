import 'package:sqlite3/common.dart' show CommonDatabase;
import 'package:cohabit/db/table_columns.dart';
import 'sqlite3/sqlite3.dart' show openSqliteDb;

late CommonDatabase sqliteDb;

Future<void> openDb() async {
  sqliteDb = await openSqliteDb();

  final dbVersion =
      sqliteDb.select('PRAGMA user_version').first['user_version'];

  print('DB version: $dbVersion');

  if (dbVersion == 0) {
    var sql = '''
      BEGIN;

      CREATE TABLE habits (
        ${TableHabits.name} VARCHAR(200) PRIMARY KEY
      );
      CREATE TABLE recurrance (
        ${TableRecurrance.weekday} TINYINT NOT NULL,
        ${TableRecurrance.starttime} TEXT NOT NULL,
        ${TableRecurrance.endtime} TEXT NOT NULL,
        PRIMARY KEY(${TableRecurrance.weekday}, ${TableRecurrance.starttime}, ${TableRecurrance.endtime})
      );
      CREATE TABLE habit_recurrance (
        ${TableHabitRecurrance.habit_fr} INTEGER NOT NULL,
        ${TableHabitRecurrance.weekday_id_fr} TINYINT NOT NULL,
        ${TableHabitRecurrance.starttime_id_fr} TEXT NOT NULL,
        ${TableHabitRecurrance.endtime_id_fr} TEXT NOT NULL,
        CONSTRAINT habit_recurrance_habit_fk FOREIGN KEY(${TableHabitRecurrance.habit_fr}) REFERENCES habits(name),
        CONSTRAINT habit_recurrance_weekday_fk FOREIGN KEY(${TableHabitRecurrance.weekday_id_fr}, ${TableHabitRecurrance.starttime_id_fr}, ${TableHabitRecurrance.endtime_id_fr}) REFERENCES recurrance(weekday,starttime,endtime),
        CONSTRAINT habit_recurrance_pk PRIMARY KEY(${TableHabitRecurrance.habit_fr}, ${TableHabitRecurrance.weekday_id_fr}, ${TableHabitRecurrance.starttime_id_fr}, ${TableHabitRecurrance.endtime_id_fr})
      );
      PRAGMA user_version = 1;
      COMMIT;
    ''';
    print(sql);
    sqliteDb.execute(sql);
  }
}
