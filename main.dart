import 'dart:async';

import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:trip_reminder/database/user_info.dart';
import 'package:trip_reminder/forms/event_trip.dart';
import 'profile/user_profile.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

void main() {
  runApp(const MaterialApp(home: Home()));
}

List<Trip> trips = [];

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  void initState() {
    fetchRows();
    super.initState();
  }

  void refreshPage() {
    //iterable++;
  }

  FutureOr onBack(dynamic value) {
    refreshPage();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            backgroundColor: Colors.lightBlue,
            elevation: 0,
            title: Text('Trip Planner',
                style: TextStyle(
                  color: Colors.white,
                  letterSpacing: 2.0,
                )),
            actions: <Widget>[
              TextButton.icon(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return const EventTrip();
                  })).then(onBack);
                },
                icon: Icon(
                  Icons.add,
                  color: Colors.white,
                ),
                label: Text(
                  'Add a Trip',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ]),
        backgroundColor: Colors.blue,
        // ignore: unnecessary_new
        body: Container(
            child: new ListView.builder(
                itemCount: trips.length,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                itemBuilder: (context, index) {
                  //List.generate(trips.length, ((index) {
                  return Center(
                      key: new Key(index.toString()),
                      child: TripRoute(
                        trip: trips[index],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    Profile(trip: trips[index])),
                          ).then((_) {
                            setState(() {});
                          });
                        },
                      ));
                }))); //));
  }
}

class Trip {
  final String title;
  final String location;
  final String start_date;
  final String end_date;
  const Trip(
      {required this.title,
      required this.location,
      required this.start_date,
      required this.end_date});
}

// void _insert(name, description, date, time, location) async {
//   Database db = await UserDatabase.instance.database;

//   Map<String, dynamic> row = {
//     UserDatabase.columnName: name,
//     UserDatabase.columnDescription: description,
//     UserDatabase.columnTripStartDate: date,
//     UserDatabase.columnTime: time,
//     UserDatabase.columnLocation: location
//   };
//   int id = await db.insert(UserDatabase.table, row);
// }

Future<void> fetchRows() async {
  // dynamic count = fetchLength();
  // int length = count?.toInt() ?? 0;
  Database db = await UserDatabase.instance.database;
  int count = Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM eventPlanner'))
          ?.toInt() ??
      0;
  trips.clear();
  for (int i = 1; i <= count; i++) {
    Trip map = await get(i);
    trips.add(map);
  }
}

Future<Trip> get(int id) async {
  Database db = await UserDatabase.instance.database;
  final maps =
      //await db.query(UserDatabase.table2, where: 'id = ?', whereArgs: [id]);
      await db.rawQuery('SELECT * FROM eventPlanner WHERE id2=?', [id]);
  print(maps.toString());
  return Trip(
      title: maps[0]['tripName'].toString(),
      location: maps[0]['tripLocation'].toString(),
      start_date: maps[0]['startDate'].toString(),
      end_date: maps[0]['endDate'].toString());
}

class TripRoute extends StatefulWidget {
  const TripRoute({
    super.key,
    required this.trip,
    required this.onTap,
  });
  final Trip trip;
  final VoidCallback onTap;

  @override
  State<TripRoute> createState() => _TripRouteState();
}

class _TripRouteState extends State<TripRoute> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: () {
          widget.onTap();
        },
        child: Container(
            margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black),
                borderRadius: BorderRadius.all(Radius.circular(15))),
            child: Row(
              children: <Widget>[
                Container(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      child: Text('Name: ${widget.trip.title}'),
                    ),
                    SizedBox(height: 20),
                    Container(
                      child: Text('Location: ${widget.trip.location}'),
                    ),
                    Container(child: dateChecker()),
                  ],
                )),
                Spacer(),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black),
                    borderRadius: BorderRadius.all(Radius.circular(15)),
                  ),
                  child: TextButton.icon(
                      onPressed: () {
                        _alertBuilder(context, widget.trip);
                        setState(() {});
                      },
                      icon: Icon(Icons.delete),
                      label: Text('Delete')),
                ),
              ],
            )));
  }

  Widget dateChecker() {
    /// check this
    if (widget.trip.start_date != '0000-00-00T00:00:00.000') {
      final String start_date = widget.trip.start_date.split('T')[0];
      final String end_date = widget.trip.end_date.split('T')[0];
      return Text('${start_date} + " - " + ${end_date}');
    }
    return Text('Add an event!');
  }

  Widget listView() {}
}

Future delete(String tripName, String tripLocation) async {
  Database db = await UserDatabase.instance.database;
  final maps = await db.rawDelete(
      'DELETE FROM eventPlanner WHERE tripName = ? AND tripLocation = ?',
      [tripName, tripLocation]);
}

Future deleteFromList(Trip trip) async {
  if (trips.contains(trip)) {
    trips.remove(trip);
  }
}

Future<void> _alertBuilder(BuildContext context, trip) async {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Are you sure you want to delete this trip?'),
        actions: <Widget>[
          TextButton(
            child: const Text('Yes'),
            onPressed: () {
              delete(
                trip.title.toString(),
                trip.location.toString(),
              );
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Home(),
                  ));
            },
          ),
          TextButton(
            child: const Text('No'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}
