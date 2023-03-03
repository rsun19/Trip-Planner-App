import 'package:sqflite/sqflite.dart';
import 'dart:async';
import 'package:path/path.dart';

class UserDatabase {
  static final _databaseName = "userinfo.db";
  static final _databaseVersion = 1;
  static final table = "users";
  static final table2 = "eventPlanner";
  static final columnId = 'id';
  static final columnId2 = 'id2';
  static final columnName = 'name';
  static final columnDescription = 'description';
  static final columnDateTime = 'dateTime';
  static final columnLocation = 'location';
  static final columnTripName = 'tripName';
  static final columnTripLocation = 'tripLocation';
  static final columnTripNameEvent = 'tripNameEvent';
  static final columnTripLocationEvent = 'tripLocationEvent';
  static final columnTripStartDate = 'tripStartDate';
  static final columnTripEndDate = 'tripEndDate';
  static final fullAddress = 'fullAddress';
  static final visibility = "visibility";
  static final email = "email";

  UserDatabase._privateConstructor();
  static final UserDatabase instance = UserDatabase._privateConstructor();

  static Database? _database;
  Future<Database> get database async => _database ??= await _initDatabase();

  _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute(
      """CREATE TABLE $table(
          $columnId INTEGER PRIMARY KEY,
          $columnName TEXT,
          $columnDescription TEXT,
          $columnDateTime TEXT,
          $columnLocation TEXT,
          $fullAddress TEXT,
          $columnTripNameEvent TEXT,
          $columnTripLocationEvent TEXT,
          createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )""",
    );
    await db.execute(
      """CREATE TABLE $table2(
          $columnId2 INTEGER PRIMARY KEY,
          $columnTripName TEXT,
          $columnTripLocation TEXT,
          $columnTripStartDate TEXT,
          $columnTripEndDate TEXT,
          $visibility TEXT,
          $email TEXT,
          createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
        )""",
    );
  }
}
