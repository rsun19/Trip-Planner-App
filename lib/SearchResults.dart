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
import 'package:trip_reminder/firebase interactions/view_searched_events.dart';
import 'package:trip_reminder/firebase interactions/view_event_trips';

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
