import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:trip_reminder/database/user_info.dart';
import 'package:intl/intl.dart';
import 'package:trip_reminder/main.dart';
import 'package:trip_reminder/api-ORS/openRouteService.dart';
import 'package:trip_reminder/TripClass.dart';

class ChangeTripName extends StatefulWidget {
  const ChangeTripName({super.key, required this.trip});
  final Trip trip;
  @override
  State<ChangeTripName> createState() => _ChangeTripNameState();
}

class _ChangeTripNameState extends State<ChangeTripName> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _locationinput = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    // TODO: implement initState
    _controller.text = widget.trip.title;
    _locationinput.text = widget.trip.location;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Form(
      key: _formKey,
      child: ListView(
        scrollDirection: Axis.vertical,
        shrinkWrap: true,
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        children: <Widget>[
          Container(
              margin: EdgeInsets.only(top: 60),
              child: Text(
                "Change your Itinerary Name",
                style: TextStyle(fontSize: 25),
              )),
          Container(
            margin: EdgeInsets.only(top: 10),
            child: TextFormField(
                controller: _controller,
                decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  labelText: "What do you want to name your trip?",
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
                controller: _locationinput,
                decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  labelText:
                      "Where are you traveling? Input City, State or City, Country.",
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter some text';
                  }
                  return null;
                }),
          ),
          SizedBox(height: 5),
          ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final String tripName = _controller.text;
                  final String tripLocation = _locationinput.text;
                  Database db = await UserDatabase.instance.database;
                  print(tripName);
                  print(tripLocation);
                  print(widget.trip.title);
                  print(widget.trip.location);
                  await db.rawUpdate(
                      'UPDATE eventPlanner SET tripName = ? AND tripLocation = ? WHERE tripName = ? AND tripLocation = ?',
                      [
                        tripName,
                        tripLocation,
                        widget.trip.title,
                        widget.trip.location
                      ]);
                  Navigator.push(
                      context, MaterialPageRoute(builder: (context) => Home()));
                }
              },
              child: const Text('Submit'))
        ],
      ),
    ));
  }
}
