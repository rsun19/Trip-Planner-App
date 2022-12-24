import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:trip_reminder/database/user_info.dart';
import 'package:trip_reminder/forms/event_trip.dart';
import 'package:trip_reminder/forms/event_form.dart';
import 'profile/event_listings.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

void main() {
  runApp(const MaterialApp(home: Home()));
}

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
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
                    return const EventTripInfo();
                  })).then((_) {
                    sortList();
                  });
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
        body: FutureBuilder<List<Trip>>(
          future: sortList(),
          builder: (context, snapshot) {
            if (snapshot.hasData &&
                snapshot.connectionState == ConnectionState.done) {
              return ListView.builder(
                  itemCount: snapshot.data!.length,
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  itemBuilder: (context, index) {
                    return Center(
                        key: new Key(index.toString()),
                        child: TripRoute(
                          trip: snapshot.data![index],
                          onTap: () {
                            compareTimes(snapshot.data![index].title,
                                snapshot.data![index].location);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      Profile(trip: snapshot.data![index])),
                            );
                          },
                        ));
                  });
            } else {
              return CircularProgressIndicator();
            }
          },
        ));
  }
}

List<Trip> sortedDates = [];
List<Trip> passedDates = [];

Future<List<Trip>> sortList() async {
  String currentDay = DateTime.now().toIso8601String();
  sortedDates.clear();
  passedDates.clear();
  Database db = await UserDatabase.instance.database;
  int count = Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM eventPlanner'))
          ?.toInt() ??
      0;
  for (int i = 1; i <= count; i++) {
    final maps =
        await db.query(UserDatabase.table2, where: 'id2=?', whereArgs: [i]);
    sortedDates.add(Trip(
        title: maps[0]['tripName'].toString(),
        location: maps[0]['tripLocation'].toString(),
        start_date: maps[0]['tripStartDate'].toString(),
        end_date: maps[0]['tripEndDate'].toString()));
  }
  sortedDates.sort((a, b) {
    return a.start_date.compareTo(b.start_date);
  });
  for (var each in sortedDates) {
    if (each.end_date.compareTo(currentDay) < 1) {
      passedDates.add(each);
    }
  }
  sortedDates.removeWhere((e) => passedDates.contains(e));
  for (var each in passedDates) {
    sortedDates.add(each);
  }
  List<Trip> sentDates = [];
  for (var each in sortedDates) {
    sentDates.add(each);
  }
  return sentDates;
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
                    SizedBox(height: 20),
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
    if (widget.trip.start_date != '0000-00-00T00:00:00.000') {
      late var _start_date =
          DateFormat("yyyy-MM-dd").parse(widget.trip.start_date.split('T')[0]);
      late String start_date =
          DateFormat("MM/dd/yyyy").format(_start_date).toString();
      late var _end_date =
          DateFormat("yyyy-MM-dd").parse(widget.trip.end_date.split('T')[0]);
      late String end_date =
          DateFormat("MM/dd/yyyy").format(_end_date).toString();
      return Text('Dates: ${start_date} - ${end_date}');
    }
    return Text('Add an event!');
  }
}

Future delete(String tripName, String tripLocation) async {
  Database db = await UserDatabase.instance.database;
  final maps = await db.rawDelete(
      'DELETE FROM eventPlanner WHERE tripName = ? AND tripLocation = ?',
      [tripName, tripLocation]);
  await db.rawDelete(
      'DELETE FROM users WHERE tripNameEvent = ? AND tripLocationEvent = ?',
      [tripName, tripLocation]);
}

Future deleteFromList(Trip trip) async {
  if (sortedDates.contains(trip)) {
    sortedDates.remove(trip);
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
