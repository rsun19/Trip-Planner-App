import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:trip_reminder/database/user_info.dart';
import 'package:intl/intl.dart';
import 'package:trip_reminder/main.dart';
import 'package:trip_reminder/api-ORS/openRouteService.dart';
import 'package:trip_reminder/TripClass.dart';

class UserFormCase extends StatelessWidget {
  const UserFormCase({
    super.key,
    required this.trip,
  });
  final Trip trip;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'User Info',
          style: TextStyle(
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
      ),
      body: Column(
        children: <Widget>[
          SizedBox(
            height: 20,
          ),
          Container(
            child: Text(
              'Enter a New Event',
              style: TextStyle(
                fontSize: 20,
                letterSpacing: 2,
              ),
            ),
          ),
          UserBasicInfo(trip: trip),
        ],
      ),
    );
  }
}

class UserBasicInfo extends StatefulWidget {
  const UserBasicInfo({super.key, required this.trip});
  final Trip trip;
  @override
  State<UserBasicInfo> createState() => _UserBasicInfoState();
}

class _UserBasicInfoState extends State<UserBasicInfo> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _controllerDescription = TextEditingController();
  final TextEditingController _controllerLocation = TextEditingController();
  final TextEditingController _dateInput = TextEditingController();
  TextEditingController _timeinput = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  @override
  State<UserBasicInfo> createState() => _UserBasicInfoState();

  @override
  void initState() {
    _timeinput.text = "";
    _dateInput.text = "";
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        scrollDirection: Axis.vertical,
        shrinkWrap: true,
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        children: <Widget>[
          Container(
            child: TextFormField(
                controller: _controller,
                decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  labelText: "Enter the Name of the Event",
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter some text';
                  }
                  return null;
                }),
          ),
          SizedBox(height: 5),
          Container(
            child: TextFormField(
              controller: _timeinput,
              decoration: const InputDecoration(
                border: UnderlineInputBorder(),
                labelText: "Enter The Time",
              ),
              onTap: () async {
                TimeOfDay? eventTime = await showTimePicker(
                  initialTime: TimeOfDay.now(),
                  context: context,
                );
                validator:
                (value) {
                  if (value == null) {
                    return 'Please enter a time';
                  }
                };
                if (eventTime != null) {
                  String time = eventTime.format(context);
                  DateTime militaryTime = DateFormat.jm().parse(time);
                  String _militaryTime =
                      DateFormat("HH:mm").format(militaryTime);
                  _timeinput.text = _militaryTime;
                }
                ;
              },
            ),
          ),
          SizedBox(height: 5),
          Container(
            child: TextFormField(
                controller: _dateInput,
                decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  labelText: "Enter The Date",
                ),
                onTap: () async {
                  showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(3000))
                      .then((selectedDate) {
                    if (selectedDate != null) {
                      _dateInput.text = selectedDate.toIso8601String();
                    }
                  });
                }),
          ),
          SizedBox(height: 5),
          Container(
            child: TextFormField(
                controller: _controllerLocation,
                decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  labelText: "Enter a location",
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter some text';
                  }
                  return null;
                }),
          ),
          SizedBox(height: 5),
          Container(
            child: TextFormField(
              controller: _controllerDescription,
              decoration: const InputDecoration(
                border: UnderlineInputBorder(),
                labelText: "Enter an Event Description",
              ),
            ),
          ),
          ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final String name = _controller.text;
                  final String description = _controllerDescription.text;
                  final String location = _controllerLocation.text;
                  final String fullAddress = _controllerLocation.text;
                  final String date = _dateInput.text;
                  final String time = _timeinput.text;
                  final String tripName = widget.trip.title.toString();
                  final String tripLocation = widget.trip.location.toString();
                  final List hour_ISO = date.split('T');
                  final String ISO8601 = hour_ISO[0] + "T" + time + ":00.000";
                  await getJsonDataForCoordinates(
                      CoordinatesHelper(area: location));
                  final String locationCoordinates =
                      "${temp_locationCoordinates[0].toString()},${temp_locationCoordinates[1].toString()}";
                  _insert(name, description, ISO8601, locationCoordinates,
                      fullAddress, tripName, tripLocation);
                  compareTimes(tripName, tripLocation);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Home(),
                      ));
                }
              },
              child: const Text('Submit'))
        ],
      ),
    );
  }

  void _insert(name, description, dateTime, location, fullAddress, tripName,
      tripLocation) async {
    Database db = await UserDatabase.instance.database;

    Map<String, dynamic> row = {
      UserDatabase.columnName: name,
      UserDatabase.columnDescription: description,
      UserDatabase.columnDateTime: dateTime,
      UserDatabase.columnLocation: location,
      UserDatabase.fullAddress: fullAddress,
      UserDatabase.columnTripNameEvent: tripName,
      UserDatabase.columnTripLocationEvent: tripLocation
    };
    int id = await db.insert(UserDatabase.table, row);
    print(await db.query(UserDatabase.table));
  }
}

Future update(
    String TripName, String TripLocation, String TripStartDate) async {
  Database db = await UserDatabase.instance.database;
  await db.rawUpdate(
      'UPDATE eventPlanner SET tripStartDate = ? WHERE tripName = ? AND tripLocation = ?',
      [TripStartDate, TripName, TripLocation]);
}

Future _update(String TripName, String TripLocation, String TripEndDate) async {
  Database db = await UserDatabase.instance.database;
  await db.rawUpdate(
      'UPDATE eventPlanner SET tripEndDate = ? WHERE tripName = ? AND tripLocation = ?',
      [TripEndDate, TripName, TripLocation]);
}

Future<void> compareTimes(String tripName, String tripLocation) async {
  Database db = await UserDatabase.instance.database;
  int count =
      Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM users'))
              ?.toInt() ??
          0;
  times.clear();
  for (int i = 1; i <= count; i++) {
    final datetimes =
        await db.query(UserDatabase.table, where: 'id=?', whereArgs: [i]);
    times.add(datetimes[0]['dateTime'].toString());
  }
  times.sort();
  if (times.length > 0) {
    update(tripName, tripLocation, times[0]);
    _update(tripName, tripLocation, times[times.length - 1]);
  }
}

List<String> times = [];
List<String> startEndList = [];

Future<void> getTime(String TripName, String TripLocation) async {
  Database db = await UserDatabase.instance.database;
  int count =
      Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM users'))
              ?.toInt() ??
          0;
  times.clear();
  startEndList.clear();
  for (int i = 1; i <= count; i++) {
    final datetimes =
        await db.query(UserDatabase.table, where: 'id=?', whereArgs: [i]);
    times.add(datetimes[0]['dateTime'].toString());
  }
  times.sort();
  final maps = await db.query(UserDatabase.table2,
      where: 'tripName=? AND tripLocation=?',
      whereArgs: [TripName, TripLocation]);
  print(maps);
  startEndList.add(maps[0]['tripStartDate'].toString());
  startEndList.add(maps[0]['tripEndDate'].toString());
}
