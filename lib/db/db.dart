import 'package:sqlite3/common.dart' show CommonDatabase;
import 'sqlite3/sqlite3.dart' show openSqliteDb;

late CommonDatabase sqliteDb;

Future<void> openDb() async {
  sqliteDb = await openSqliteDb();

  final dbVersion =
      sqliteDb.select('PRAGMA user_version').first['user_version'];

  print('DB version: $dbVersion');

  if (dbVersion == 0) {
    sqliteDb.execute('''
      BEGIN;
      -- TODO
      PRAGMA user_version = 1;
      COMMIT;

      CREATE TABLE habits (
        name VARCHAR(200) PRIMARY KEY
      );
      CREATE TABLE recurrance (
        weekday TINYINT NOT NULL,
        time TEXT NOT NULL,
        PRIMARY KEY(weekday, time)
      );
      CREATE TABLE habit_recurrance (
        habit_fr INTEGER NOT NULL,
        weekday_id_fr TINYINT NOT NULL,
        time_id_fr TEXT NOT NULL,
        CONSTRAINT habit_recurrance_habit_fk FOREIGN KEY(habit_fr) REFERENCES habits(name),
        CONSTRAINT habit_recurrance_weekday_fk FOREIGN KEY(weekday_id_fr, time_id_fr) REFERENCES recurrance(weekday,time),
        CONSTRAINT habit_recurrance_pk PRIMARY KEY(habit_fr, weekday_id_fr, time_id_fr)
      );

    ''');
  }
}
