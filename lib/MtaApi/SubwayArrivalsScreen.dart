import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:trip_reminder/api-ORS/openRouteService.dart';
import 'package:trip_reminder/main.dart';
import 'package:trip_reminder/profile/event_listings.dart';
import 'package:flutter_compass/flutter_compass.dart';

class SubwayScreen extends StatelessWidget {
  const SubwayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightBlue,
        title: Text(
          "Real-Time Subway Arrival and Departures",
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
    );
  }
}
