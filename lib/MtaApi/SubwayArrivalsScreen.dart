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
import 'package:csv/csv.dart';
import 'package:trip_reminder/MtaApi/MTAAPI.dart';

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

  List<dynamic> apiCaller = [];

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
        body: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            SizedBox(
                height: 100,
                child: TextButton.icon(
                    onPressed: () {
                      getCurrentPosition();
                    },
                    icon: Icon(Icons.subway),
                    label: Text('Click for real-time data'))),
          ]),
          showText()
        ]));
  }

  Widget showText() {
    if (apiCaller.isNotEmpty) {
      return Text(
          key: ValueKey(apiCaller[0]),
          'Station: ${apiCaller[1]}. Lines: ${apiCaller[2].toString().replaceAll("-", ", ")}');
    } else {
      return SizedBox();
    }
  }

  void getCurrentPosition() async {
    final LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
    );
    positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position? position) async {
      if (mounted) {
        coordinates.clear();
        coordinates.add(position!.latitude);
        coordinates.add(position.longitude);
        await readCSVFile();
        await findClosestPosition();
        await Future.delayed(Duration(seconds: 60));
      }
    });
  }

  Future<void> findClosestPosition() async {
    //try {
    subwayData.sort((a, b) {
      return Geolocator.distanceBetween(
                  a[3], a[4], coordinates[0], coordinates[1])
              .toInt() -
          Geolocator.distanceBetween(b[3], b[4], coordinates[0], coordinates[1])
              .toInt();
    });
    // if (apiCaller.isNotEmpty && apiCaller[0] != subwayData[0]) {
    //   apiCaller.clear();
    //   apiCaller.addAll(subwayData[0]);
    //   callApi();
    // } else if (apiCaller.isEmpty) {
    //   apiCaller.addAll(subwayData[0]);
    //   callApi();
    // }
    apiCaller.clear();
    apiCaller.addAll(subwayData[0]);
    await callApi();
    // } catch (e) {
    //   Text('Cannot get data');
    //   print("failed");
    // }
  }

  Future<void> callApi() async {
    List<String> lineCaller =
        apiCaller[3].toString().replaceAll(" ", "").split("-");
    String stopName = apiCaller[0].toString();
    MtaApiCaller MTACaller =
        MtaApiCaller(lineCaller: lineCaller, apiStation: stopName);
    try {
      MTACaller.ApiIterator();
    } catch (e) {
      Text('Real-time data not available. Please try again later.');
    }
  }

  Future<void> readCSVFile() async {
    subwayData.clear();
    var data = await rootBundle.loadString("lib/assets/Stations.csv");
    List<List<dynamic>> csvTable = CsvToListConverter().convert(data);
    subwayData = csvTable;
    subwayData.removeAt(0);
  }
}
