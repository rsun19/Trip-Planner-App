import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:trip_reminder/database/user_info.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:async';
import 'package:intl/date_symbol_data_local.dart';
import 'package:trip_reminder/main.dart';

class EventTrip extends StatelessWidget {
  const EventTrip({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'Add a Trip',
          style: TextStyle(
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
      ),
      //backgroundColor: Colors.lightBlue,
      body: Column(
        children: <Widget>[
          SizedBox(
            height: 20,
          ),
          Container(
            child: Text(
              'Enter a New Trip',
              style: TextStyle(
                fontSize: 20,
                letterSpacing: 2,
              ),
            ),
          ),
          const EventTripInfo(),
        ],
      ),
    );
  }
}

class EventTripInfo extends StatefulWidget {
  const EventTripInfo({super.key});
  @override
  State<EventTripInfo> createState() => _EventTripInfoState();
}

class _EventTripInfoState extends State<EventTripInfo> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _locationinput = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  @override
  State<EventTripInfo> createState() => _EventTripInfoState();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
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
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            child: TextFormField(
                controller: _locationinput,
                decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  labelText: "Where are you traveling?",
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
                  _insert(tripName, tripLocation);
                  Navigator.pop(context);
                }
              },
              child: const Text('Submit'))
        ],
      ),
    );
  }

  void _insert(tripName, tripLocation) async {
    Database db = await UserDatabase.instance.database;
    String startDate = '0000-00-00T00:00:00.000';
    String endDate = '0000-00-00T00:00:00.000';
    Map<String, dynamic> row = {
      UserDatabase.columnTripName: tripName,
      UserDatabase.columnTripLocation: tripLocation,
      UserDatabase.columnTripStartDate: startDate,
      UserDatabase.columnTripEndDate: endDate,
    };
    int id = await db.insert(UserDatabase.table2, row);
    print(await db.query(UserDatabase.table2));
  }
}
