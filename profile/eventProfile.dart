import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:sqflite/sqflite.dart';
import 'package:trip_reminder/database/user_info.dart';
import 'package:trip_reminder/main.dart';
import 'package:trip_reminder/profile/user_profile.dart';
import 'package:trip_reminder/forms/user_form.dart';

class EventProfile extends StatelessWidget {
  const EventProfile(
      {super.key,
      required this.trip,
      required this.tripevent,
      this.name,
      this.description,
      this.dateTime,
      this.location});

  final tripEvent tripevent;
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
          TextButton.icon(
              onPressed: () {
                delete(tripevent.name.toString(), trip.title.toString(),
                    trip.location.toString());
                compareTimes(trip.title, trip.location);
              },
              icon: Icon(Icons.minimize, color: Colors.white),
              label: Text('Delete'))
        ],
      ),
      body: Column(
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Name: ${tripevent.name}',
                      style: TextStyle(
                        fontSize: 20,
                        letterSpacing: .5,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Date: ${tripevent.dateTime}' +
                          ' at ' +
                          '${tripevent.dateTime}',
                      style: TextStyle(
                        fontSize: 20,
                        letterSpacing: .5,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Location: ${tripevent.location}',
                      style: TextStyle(
                        fontSize: 20,
                        letterSpacing: .5,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Description: ${tripevent.description}',
                      style: TextStyle(
                        fontSize: 20,
                        letterSpacing: .5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

Future delete(String tripName, String tripNameEvent, String location) async {
  Database db = await UserDatabase.instance.database;
  final maps = await db.rawDelete(
      'DELETE FROM users WHERE name = ?, tripNameEvent = ?, tripNameLocation = ?',
      [tripName, tripNameEvent, location]);
}
