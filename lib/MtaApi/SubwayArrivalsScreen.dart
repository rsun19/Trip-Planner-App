import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:trip_reminder/api-ORS/openRouteService.dart';
import 'package:trip_reminder/main.dart';
import 'package:trip_reminder/profile/event_listings.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'dart:convert' show LineSplitter, utf8;
import 'package:csv/csv.dart';
import 'dart:io';

class SubwayScreen extends StatefulWidget {
  SubwayScreen({super.key});

  @override
  State<SubwayScreen> createState() => _SubwayScreenState();
}

class _SubwayScreenState extends State<SubwayScreen> {
  Position? position;

  StreamSubscription<Position>? positionStream;

  List<double> coordinates = [];

  List<List<dynamic>> subwayData = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getCurrentPosition();
  }

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

  void getCurrentPosition() async {
    final LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
    );
    positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position? position) async {
      coordinates.clear();
      coordinates.add(position!.latitude);
      coordinates.add(position.longitude);
      readCSVFile();
      findClosestPosition();
      await Future.delayed(Duration(seconds: 60));
    });
  }

  void findClosestPosition() async {
    subwayData.sort((a, b) {
      return Geolocator.distanceBetween(
                  a[1], a[2], position!.latitude, position!.longitude)
              .toInt() -
          Geolocator.distanceBetween(
                  b[1], b[2], position!.latitude, position!.longitude)
              .toInt();
    });
  }

  void readCSVFile() async {
    subwayData.clear();
    var data = await rootBundle
        .loadString("lib/assets/DOITT_SUBWAY_STATION_01_13SEPT2010.csv");
    List<List<dynamic>> csvTable = CsvToListConverter().convert(data);
    setState(() {
      subwayData = csvTable;
      subwayData.removeAt(0);
    });
  }
}
