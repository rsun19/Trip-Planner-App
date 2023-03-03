import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:trip_reminder/forms/event_form.dart';
import 'profile/event_listings.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:trip_reminder/api-ORS/openRouteService.dart';
import 'package:trip_reminder/ExpandedNavigationServices.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; //show json;
import "package:firebase_core/firebase_core.dart";
import 'package:intl/intl.dart';
import 'package:trip_reminder/database/user_info.dart';
import 'package:sqflite/sqflite.dart';
import 'package:trip_reminder/TripClass.dart';

class SearchResults extends StatefulWidget {
  const SearchResults({super.key, required this.searchQuery});
  final String searchQuery;
  @override
  State<SearchResults> createState() => _SearchResultsState();
}

class _SearchResultsState extends State<SearchResults> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Search Results"),
        ),
        backgroundColor: Colors.blue,
        body: StreamBuilder<dynamic>(
          stream: FirebaseFirestore.instance
              .collection("itineraries")
              //.where("tripLocationQuery",
              //  isGreaterThanOrEqualTo: widget.searchQuery)
              .where("tripLocationQuery",
                  isLessThanOrEqualTo: widget.searchQuery)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  itemBuilder: (context, index) {
                    return Center(
                        child: ItineraryRoute(
                      trip: snapshot.data!.docs[index],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  EventRoute(trip: snapshot.data!.docs[index])),
                        );
                      },
                    ));
                  });
            } else {
              return CircularProgressIndicator(
                backgroundColor: Colors.white,
              );
            }
          },
        ));
  }
}

class ItineraryRoute extends StatefulWidget {
  ItineraryRoute({super.key, required this.trip, required this.onTap});
  final trip;
  final onTap;
  FirebaseAuth? firebaseUser;

  @override
  State<ItineraryRoute> createState() => _ItineraryRouteState();
}

class _ItineraryRouteState extends State<ItineraryRoute> {
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
                border: Border.all(color: Colors.white),
                borderRadius: BorderRadius.all(Radius.circular(15))),
            child: Container(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    child: Text('Name: ${widget.trip["tripName"]}'),
                  ),
                  SizedBox(height: 20),
                  Container(
                    child: Text('Location: ${widget.trip["tripLocation"]}'),
                  ),
                  SizedBox(height: 20),
                  Container(
                    child: Text('By: ${widget.trip["poster"]}'),
                  ),
                ],
              ),
            )));
  }
}

class EventRoute extends StatefulWidget {
  const EventRoute({super.key, this.trip});
  final trip;

  @override
  State<EventRoute> createState() => _EventRouteState();
}

class _EventRouteState extends State<EventRoute> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.trip["tripName"]}"),
      ),
      backgroundColor: Colors.blue,
      body: SizedBox(
          height: 1000,
          width: 1000,
          child: StreamBuilder<dynamic>(
              stream: FirebaseFirestore.instance
                  .collection("events")
                  .where("email", isEqualTo: widget.trip["email"])
                  .where("tripName", isEqualTo: widget.trip["tripName"])
                  .where("tripLocation", isEqualTo: widget.trip["tripLocation"])
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return ListView.builder(
                      key: ObjectKey(TripEvent),
                      itemCount: snapshot.data!.docs.length,
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                      itemBuilder: (context, index) {
                        return Center(
                          child: ViewFirebaseEvent(
                            tripevent: snapshot.data!.docs[index],
                            trip: widget.trip,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        ViewFirebaseEventDetails(
                                            trip: widget.trip,
                                            tripevent:
                                                snapshot.data!.docs[index])),
                              );
                            },
                          ),
                        );
                      });
                } else {
                  return CircularProgressIndicator(
                    backgroundColor: Colors.white,
                  );
                }
              })),
    );
  }
}

class ViewFirebaseEvent extends StatefulWidget {
  const ViewFirebaseEvent(
      {super.key,
      required this.trip,
      required this.tripevent,
      required this.onTap});

  final trip;
  final tripevent;
  final VoidCallback onTap;

  @override
  State<ViewFirebaseEvent> createState() => _ViewFirebaseEventState();
}

class _ViewFirebaseEventState extends State<ViewFirebaseEvent> {
  late List dateTimeList = widget.tripevent["dateTime"].split('T');
  late var _time = DateFormat.Hm().parse(dateTimeList[1].substring(0, 5));
  late var time = DateFormat.jm().format(_time);

  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: () {
          widget.onTap();
        },
        child: Container(
            height: 175,
            width: MediaQuery.of(context).size.height,
            margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.white),
                borderRadius: BorderRadius.all(Radius.circular(15))),
            child: Row(children: <Widget>[
              Container(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      child: Text(
                        'Name: ${widget.tripevent["eventName"]}',
                        style: TextStyle(
                            //fontSize: 20,
                            //letterSpacing: .5,
                            ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Container(
                      child: Text(
                        'At ' + '${time}',
                        style: TextStyle(
                            //fontSize: 20,
                            //letterSpacing: .5,
                            ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Container(
                      child: Text(
                        'Location: ' +
                            '${widget.tripevent["eventFullAddress"]}',
                        style: TextStyle(
                            //fontSize: 20,
                            //letterSpacing: .5,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ])));
  }
}

class ViewFirebaseEventDetails extends StatefulWidget {
  const ViewFirebaseEventDetails({
    super.key,
    required this.trip,
    required this.tripevent,
  });

  final trip;
  final tripevent;

  @override
  State<ViewFirebaseEventDetails> createState() =>
      _ViewFirebaseEventDetailsState();
}

class _ViewFirebaseEventDetailsState extends State<ViewFirebaseEventDetails> {
  late List dateTimeList = widget.tripevent["dateTime"].split('T');
  late var _time = DateFormat.Hm().parse(dateTimeList[1].substring(0, 5));
  late var time = DateFormat.jm().format(_time);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          '${widget.tripevent["eventName"]}',
          style: TextStyle(
            color: Colors.white,
            letterSpacing: 2.0,
          ),
        ),
      ),
      backgroundColor: Colors.blue,
      body: Center(
        child: Container(
          height: 700,
          width: 300,
          margin: EdgeInsets.fromLTRB(0, 0, 0, 0),
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.white),
              borderRadius: BorderRadius.all(Radius.circular(15))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                child: Text(
                  'Name: ${widget.tripevent["eventName"]}',
                  style: TextStyle(
                    fontSize: 20,
                    letterSpacing: .5,
                  ),
                ),
              ),
              SizedBox(height: 20),
              Container(
                child: Text(
                  'Time ' + '${time}',
                  style: TextStyle(
                      //fontSize: 20,
                      //letterSpacing: .5,
                      ),
                ),
              ),
              SizedBox(height: 20),
              Container(
                child: Text(
                  'Location: ${widget.tripevent["eventFullAddress"]}',
                  style: TextStyle(
                      //fontSize: 20,
                      //letterSpacing: .5,
                      ),
                ),
              ),
              SizedBox(height: 20),
              Container(
                child: Text(
                  'Description: ${widget.tripevent["eventDescription"]}',
                  style: TextStyle(
                      //fontSize: 20,
                      //letterSpacing: .5,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
