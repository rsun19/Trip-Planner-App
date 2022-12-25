import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:trip_reminder/database/user_info.dart';
import 'package:trip_reminder/forms/event_form.dart';
import 'package:sqflite/sqflite.dart';
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

class Profile extends StatefulWidget {
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
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: Text(
            '${widget.trip.title}',
            style: TextStyle(
              color: Colors.white,
              letterSpacing: 2.0,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return UserFormCase(trip: widget.trip);
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
        backgroundColor: Colors.lightBlue,
        body: SizedBox(
            height: 1000,
            width: 1000,
            child: FutureBuilder<List<tripEvent>>(
                future: sortedList(),
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
                              child: eventInfo(
                                tripevent: snapshot.data![index],
                                trip: widget.trip,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => EventView(
                                            trip: widget.trip,
                                            tripevent: snapshot.data![index])),
                                  );
                                },
                              ));
                        });
                  } else {
                    return CircularProgressIndicator();
                  }
                })));
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
  late String location = widget.tripevent.location;

  Widget build(BuildContext context) {
    return InkWell(
        onTap: () {
          widget.onTap();
        },
        child: Container(
            height: 200,
            width: 250,
            margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black),
                borderRadius: BorderRadius.all(Radius.circular(15))),
            child: Row(children: <Widget>[
              Container(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      child: Text(
                        'Name: ${widget.tripevent.name}',
                        style: TextStyle(
                            //fontSize: 20,
                            //letterSpacing: .5,
                            ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Container(
                      child: Text(
                        'Date: ${date}' + ' at ' + '${time}',
                        style: TextStyle(
                            //fontSize: 20,
                            //letterSpacing: .5,
                            ),
                      ),
                    ),
                    SizedBox(height: 40),
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
                ),
              ),
            ])));
  }
}

class EventView extends StatefulWidget {
  const EventView({
    super.key,
    required this.trip,
    required this.tripevent,
  });

  final Trip trip;
  final tripEvent tripevent;

  @override
  State<EventView> createState() => _EventViewState();
}

class _EventViewState extends State<EventView> {
  late List dateTimeList = widget.tripevent.dateTime.split('T');

  late var _date = DateFormat("yyyy-MM-dd").parse(dateTimeList[0]);

  late var date = DateFormat("MM/dd/yyyy").format(_date);

  late var _time = DateFormat.Hm().parse(dateTimeList[1].substring(0, 5));

  late var time = DateFormat.jm().format(_time);

  @override
  Widget build(BuildContext context) {
    //return InkWell(
    //child:
    return Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: Text(
            '${widget.tripevent.name}',
            style: TextStyle(
              color: Colors.white,
              letterSpacing: 2.0,
            ),
          ),
        ),
        body: Center(
          child: Container(
            height: 700,
            width: 300,
            margin: EdgeInsets.fromLTRB(0, 0, 0, 0),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black),
                borderRadius: BorderRadius.all(Radius.circular(15))),
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
                SizedBox(height: 20),
                Container(
                  child: Text(
                    'Date: ${date}' + ' at ' + '${time}',
                    style: TextStyle(
                        //fontSize: 20,
                        //letterSpacing: .5,
                        ),
                  ),
                ),
                SizedBox(height: 20),
                Container(
                  child: Text(
                    'Location: ${widget.tripevent.location}',
                    style: TextStyle(
                        //fontSize: 20,
                        //letterSpacing: .5,
                        ),
                  ),
                ),
                SizedBox(height: 20),
                Container(
                  child: Text(
                    'Description: ${widget.tripevent.description}',
                    style: TextStyle(
                        //fontSize: 20,
                        //letterSpacing: .5,
                        ),
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
                        _alertBuilder(context, widget.trip, widget.tripevent);
                        setState(() {});
                      },
                      icon: Icon(Icons.delete),
                      label: Text('Delete')),
                ),
              ],
            ),
          ),
        ));
  }
}

Future<List<tripEvent>> sortedList() async {
  String currentDay =
      DateTime.now().toIso8601String().split('T')[0].toString() +
          'T00:00:00.000';
  eventSortedDates.clear();
  eventPassedDates.clear();
  Database db = await UserDatabase.instance.database;
  int count =
      Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM users'))
              ?.toInt() ??
          0;
  for (int i = 1; i <= count; i++) {
    final maps =
        await db.query(UserDatabase.table, where: 'id=?', whereArgs: [i]);
    eventSortedDates.add(tripEvent(
        name: maps[0]['name'].toString(),
        description: maps[0]['description'].toString(),
        dateTime: maps[0]['dateTime'].toString(),
        location: maps[0]['location'].toString()));
  }
  eventSortedDates.sort((a, b) {
    return a.dateTime.compareTo(b.dateTime);
  });
  for (var each in eventSortedDates) {
    if (each.dateTime.compareTo(currentDay) < 1) {
      eventPassedDates.add(each);
    }
  }
  List<tripEvent> sentEvents = [];
  eventSortedDates.removeWhere((e) => eventPassedDates.contains(e));
  for (var each in eventPassedDates) {
    eventSortedDates.add(each);
  }
  for (var each in eventSortedDates) {
    sentEvents.add(each);
  }
  return sentEvents;
}

List<tripEvent> eventSortedDates = [];
List<tripEvent> eventPassedDates = [];

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
                  tripevent.description.toString(),
                  tripevent.dateTime.toString(),
                  tripevent.location.toString());
              sortedList();
              //getTime(trip.title.toString(), trip.location.toString());
              //print(startEndList);
              compareTimes(trip.title.toString(), trip.location.toString());
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

Future delete(String tripName, String description, String datetime,
    String location) async {
  Database db = await UserDatabase.instance.database;
  final maps = await db.rawDelete(
      'DELETE FROM users WHERE name = ? AND description = ? AND dateTime = ? AND location = ?',
      [tripName, description, datetime, location]);
}
