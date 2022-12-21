import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:trip_reminder/database/user_info.dart';
import 'package:trip_reminder/forms/user_form.dart';
import 'package:sqflite/sqflite.dart';
import 'package:trip_reminder/database/user_info.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:trip_reminder/main.dart';

class tripEvent {
  const tripEvent(
      {required this.name,
      required this.description,
      required this.dateTime,
      required this.location});

  final String name;
  final String description;
  final String dateTime;
  final String location;
}

const List<tripEvent> events = const <tripEvent>[];

Future<void> fetchRows() async {
  Database db = await UserDatabase.instance.database;
  int count =
      Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM users'))
              ?.toInt() ??
          0;
  events.clear();
  for (int i = 1; i <= count; i++) {
    tripEvent map = await get(i);
    events.add(map);
  }
}

Future<tripEvent> get(int id) async {
  Database db = await UserDatabase.instance.database;
  final maps =
      await db.query(UserDatabase.table, where: 'id2=?', whereArgs: [id]);
  return tripEvent(
      name: maps[0][0].toString(),
      description: maps[0][1].toString(),
      dateTime: maps[0][2].toString(),
      location: maps[0][3].toString());
}

class Profile extends StatelessWidget {
  const Profile(
      {super.key,
      required this.trip,
      this.name,
      this.description,
      this.dateTime,
      this.location});
  final Trip trip;

  final String? name;
  final String? description;
  final String? dateTime;
  final String? location;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: Text(
            '${trip.title}',
            style: TextStyle(
              color: Colors.white,
              letterSpacing: 2.0,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return UserFormCase(trip: trip);
                }));
              },
              child: Text(
                'Add More Events',
                style: TextStyle(
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ),
        body: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(20.0),
          children: List.generate(
            events.length,
            (index) => eventInfo(
              tripevent: events[index],
              trip: trip,
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => UserFormCase(trip: trip)));
              },
            ),
          ),
        ));
  }
}

class eventInfo extends StatefulWidget {
  const eventInfo({
    super.key,
    required this.tripevent,
    required this.trip,
    required this.onTap,
  });

  final tripEvent tripevent;
  final VoidCallback onTap;
  final Trip trip;

  @override
  State<eventInfo> createState() => _eventInfoState();
}

class _eventInfoState extends State<eventInfo> {
  @override
  late List dateTimeList = widget.tripevent.dateTime.split('T');
  late var _date = DateFormat("yyyy-MM-dd").parse(dateTimeList[0]);
  late var date = DateFormat("MM/dd/yyyy").format(_date);
  late var _time = DateFormat.Hm().parse(dateTimeList[1].substring(0, 5));
  late var time = DateFormat.jm().format(_time);

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
            child: Row(children: <Widget>[
              Container(
                child: Column(
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Container(
                                child: Text(
                                  'Name: ${widget.tripevent.name}',
                                  style: TextStyle(
                                    fontSize: 20,
                                    letterSpacing: .5,
                                  ),
                                ),
                              ),
                              SizedBox(height: 10),
                              Container(
                                child: Text(
                                  'Date: ${date}' + ' at ' + '${time}',
                                  style: TextStyle(
                                    fontSize: 20,
                                    letterSpacing: .5,
                                  ),
                                ),
                              ),
                              SizedBox(height: 10),
                              Container(
                                child: Text(
                                  'Location: ${widget.tripevent.location}',
                                  style: TextStyle(
                                    fontSize: 20,
                                    letterSpacing: .5,
                                  ),
                                ),
                              ),
                              SizedBox(height: 10),
                              Container(
                                child: Text(
                                  'Description: ${widget.tripevent.description}',
                                  style: TextStyle(
                                    fontSize: 20,
                                    letterSpacing: .5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Spacer(),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black),
                            borderRadius: BorderRadius.all(Radius.circular(15)),
                          ),
                          child: TextButton.icon(
                              onPressed: () {
                                _alertBuilder(
                                    context, widget.trip, widget.tripevent);
                                setState(() {});
                              },
                              icon: Icon(Icons.delete),
                              label: Text('Delete')),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ])));
  }
}

void sortList() {
  events.sort((a, b) {
    return a.dateTime.compareTo(b.dateTime);
  });
}

Future<void> _alertBuilder(
    BuildContext context, Trip trip, tripEvent tripevent) async {
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
                tripevent.name.toString(),
                trip.title.toString(),
                tripevent.location.toString(),
              );
              sortList();
              compareTimes(trip.title, trip.location);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Profile(
                      trip: trip,
                    ),
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

Future delete(String tripName, String tripNameEvent, String location) async {
  Database db = await UserDatabase.instance.database;
  final maps = await db.rawDelete(
      'DELETE FROM users WHERE name = ?, tripNameEvent = ?, tripLocationEvent = ?',
      [tripName, tripNameEvent, location]);
}
