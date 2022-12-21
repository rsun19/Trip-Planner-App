// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:trip_reminder/forms/user_form.dart';
import 'package:trip_reminder/forms/event_trip.dart';

class UserInfo {
  late int id;
  late String name;
  late String description;
  late String dateTime;
  late String location;
  late String tripName;
  late String tripLocation;

  UserInfo(this.id, this.name, this.description, this.dateTime, this.location,
      this.tripName, this.tripLocation);

  UserInfo.fromMap(Map<String, dynamic> map) {
    id = map['id'];
    name = map['name'];
    description = map['description'];
    dateTime = map['dateTime'];
    location = map['location'];
    tripName = map['tripName'];
    tripLocation = map['tripLocation'];
  }

  Map<String, dynamic> toMap() {
    return {
      UserDatabase.columnId: id,
      UserDatabase.columnName: name,
      UserDatabase.columnDescription: description,
      UserDatabase.columnDateTime: dateTime,
      UserDatabase.columnLocation: location,
      UserDatabase.columnTripNameEvent: tripName,
      UserDatabase.columnTripLocationEvent: tripLocation,
    };
  }

  // @override
  // String toString() {
  //   return 'UserInfo{id: $id, user: $user, age: $age, gender: $gender, goalGulps: $goalGulps, goalLiters: $goalLiters, litgal: $litgal}';
  //}
}

class TripInfo {
  late int id;
  late String tripName;
  late String tripLocation;
  late String tripHotel;
  late String startDate;
  late String endDate;

  TripInfo(this.id, this.tripName, this.tripLocation, this.tripHotel);

  TripInfo.fromMap(Map<String, dynamic> map) {
    id = map['id'];
    tripName = map['tripName'];
    tripLocation = map['tripLocation'];
    tripHotel = map['tripHotel'];
    startDate = map['startDate'];
    endDate = map['endDate'];
  }

  Map<String, dynamic> toMap() {
    return {
      UserDatabase.columnId: id,
      UserDatabase.columnTripName: tripName,
      UserDatabase.columnTripLocation: tripLocation,
      UserDatabase.columnTripHotel: tripHotel,
      UserDatabase.columnTripStartDate: startDate,
      UserDatabase.columnTripEndDate: endDate
    };
  }
}

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
  static final columnTripHotel = 'tripHotel';
  static final columnTripNameEvent = 'tripNameEvent';
  static final columnTripLocationEvent = 'tripLocationEvent';
  static final columnTripStartDate = 'tripStartDate';
  static final columnTripEndDate = 'tripEndDate';

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
          $columnTripNameEvent TEXT,
          $columnTripLocationEvent TEXT,
          createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
        )""",
    );
    await db.execute(
      """CREATE TABLE $table2(
          $columnId2 INTEGER PRIMARY KEY,
          $columnTripName TEXT,
          $columnTripLocation TEXT,
          $columnTripHotel TEXT,
          $columnTripStartDate TEXT,
          $columnTripEndDate TEXT,
          createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
        )""",
    );
  }
}
