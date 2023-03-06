import 'dart:async';
import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:csv/csv.dart';
import 'package:trip_reminder/MtaApi/MTAAPI.dart';
import 'package:trip_reminder/AlertDialog.dart';

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

  List<dynamic> apiCaller = ['', '', '', '', ''];

  bool apiCallSuccess = true;

  List<List<List<String>>> masterList = [];

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
          Text(
              key: ValueKey(apiCaller[0]),
              'Station: ${apiCaller[1] ?? ''}. Lines: ${apiCaller[2].toString().replaceAll("-", ", ") ?? ''}'),
          alertBuilderController(),
        ]));
  }

  Widget alertBuilderController() {
    ValueKey(apiCallSuccess);
    if (apiCallSuccess == false) {
      apiCallSuccess = true;
      return failedAlertBuilder(
          context,
          "Real-time Subway Data is not available at this moment.",
          "Refresh page",
          "Return home");
    } else {
      return SizedBox();
    }
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

  Future<Widget> getCurrentPosition() async {
    final LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
    );
    try {
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
    } catch (e) {
      return failedAlertBuilder(
          context,
          "Please turn your location on before continuing.",
          "Refresh page",
          "Return home");
    }
    coordinates.clear();
    coordinates.add(position!.latitude);
    coordinates.add(position!.longitude);
    await readCSVFile();
    await findClosestPosition();
    return SizedBox();
  }

  Future<Widget> findClosestPosition() async {
    //try {
    subwayData.sort((a, b) {
      return Geolocator.distanceBetween(a[3], a[4], coordinates[0].toDouble(),
                  coordinates[1].toDouble())
              .toInt() -
          Geolocator.distanceBetween(b[3], b[4], coordinates[0].toDouble(),
                  coordinates[1].toDouble())
              .toInt();
    });
    print(subwayData[0]);
    apiCaller.clear();
    apiCaller.addAll(subwayData[0]);
    await callApi();
    // } catch (e) {
    //   apiCallSuccess = false;
    //   print('failure');
    //   return failedAlertBuilder(
    //       context,
    //       "Real-time Subway Data is not available at this moment.",
    //       "Refresh page",
    //       "Return home");
    // }
    return SizedBox();
  }

  Future<void> callApi() async {
    List<String> lineCaller =
        apiCaller[2].toString().replaceAll(" ", "").split("-");
    String stopName = apiCaller[0].toString();
    MtaApiCaller MTACaller =
        MtaApiCaller(lineCaller: lineCaller, apiStation: stopName);
    masterList.clear();
    masterList = await MTACaller.ApiIterator();
  }

  Future<void> readCSVFile() async {
    subwayData.clear();
    var data = await rootBundle.loadString("lib/assets/Stations.csv");
    List<List<dynamic>> csvTable = CsvToListConverter().convert(data);
    subwayData = csvTable;
    subwayData.removeAt(0);
  }
}
