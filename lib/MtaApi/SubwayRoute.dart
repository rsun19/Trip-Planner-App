import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:trip_reminder/database/user_info.dart';
import 'package:trip_reminder/main.dart';
import 'package:trip_reminder/MtaApi/Subway.dart';
import 'package:trip_reminder/MtaApi/SubwayArrivalsScreen.dart';

import 'package:geolocator/geolocator.dart';
import 'package:trip_reminder/AlertDialog.dart';

import 'MTAAPI.dart';

class SubwayRoute extends StatefulWidget {
  const SubwayRoute(
      {super.key,
      required this.subwayData,
      this.onTap,
      required this.station,
      required this.stationName,
      required this.index});
  final onTap;
  final List<List<Subway>> subwayData;
  final Station station;
  final String stationName;
  final int index;

  @override
  State<SubwayRoute> createState() => _SubwayRouteState();
}

class _SubwayRouteState extends State<SubwayRoute> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        widget.onTap;
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => SubwayListBuilder(
                  index: widget.index,
                  station: widget.station,
                  subwayData: widget.subwayData,
                  stationName: widget.stationName)),
        );
      },
      child: SizedBox(
          height: 75,
          child: Column(children: [
            Text(
              "${widget.stationName}",
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
            Text(
              "Lines: ${widget.station.routeId[widget.index]}",
              style: TextStyle(color: Colors.black),
            ),
            SizedBox(height: 20)
          ])),
    );
  }
}

class SubwayListBuilder extends StatefulWidget {
  SubwayListBuilder(
      {super.key,
      required this.subwayData,
      required this.station,
      required this.stationName,
      required this.index});
  final List<List<Subway>> subwayData;
  Station station;
  final String stationName;
  final int index;

  late List<Subway> masterList = subwayData[index];

  @override
  State<SubwayListBuilder> createState() => _SubwayListBuilderState();
}

class _SubwayListBuilderState extends State<SubwayListBuilder> {
  Position? position;

  List<double> coordinates = [];

  List<List<dynamic>> subwayData = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.stationName)),
      body: SizedBox(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: Column(children: [
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
            subwayArrivalsBuilder()
          ])),
    );
  }

  Widget subwayArrivalsBuilder() {
    return FutureBuilder<List<Subway>>(
      future: subwayArrivals(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return ListView.builder(
              key: ObjectKey(widget.masterList),
              itemCount: snapshot.data!.length,
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              itemBuilder: (context, index) {
                return Center(
                    key: ObjectKey(widget.masterList),
                    child: SubwayRouteDetails(
                      station: widget.station,
                      subwayData: widget.masterList,
                      index: index,
                    ));
              });
        } else {
          return CircularProgressIndicator(
            backgroundColor: Colors.white,
          );
        }
      },
    );
  }

  Future<List<Subway>> subwayArrivals() async {
    return widget.masterList;
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

  Future<List<String>> getCurrentPositionUtilityMethod() async {
    final LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
    );
    try {
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
    } catch (e) {}
    coordinates.clear();
    coordinates.add(position!.latitude);
    coordinates.add(position!.longitude);
    await readCSVFile();
    await findClosestPosition();
    print(widget.station.stationName);
    return widget.station.stationName;
  }

  Future<Widget> findClosestPosition() async {
    try {
      subwayData.sort((a, b) {
        return Geolocator.distanceBetween(a[3], a[4], coordinates[0].toDouble(),
                    coordinates[1].toDouble())
                .toInt() -
            Geolocator.distanceBetween(b[3], b[4], coordinates[0].toDouble(),
                    coordinates[1].toDouble())
                .toInt();
      });
      List<List<String>> sortedSubwayData = subwayComparator(subwayData);
      List<String> stationData = returnStations(subwayData, sortedSubwayData);
      List<String> stationName =
          returnStationNames(subwayData, sortedSubwayData);
      sortedSubwayData.removeLast();
      widget.station = Station(
          routeId: sortedSubwayData,
          stopId: stationData,
          stationName: stationName);
      await callApi(widget.station);
    } catch (e) {
      print('failure');
      return failedAlertBuilder(
          context,
          "Real-time Subway Data is not available at this moment.",
          "Refresh page",
          "Return home");
    }
    return SizedBox();
  }

  List<List<String>> subwayComparator(List<List<dynamic>> subwayData) {
    List<List<String>> subwayDataSorted = [
      subwayData[0][2].toString().split('-')
    ];
    List<int> sortedStationsCount = [];
    for (int i = 1; i < subwayData.length; i++) {
      if (Geolocator.distanceBetween(
              subwayData[0][3].toDouble(),
              subwayData[0][4].toDouble(),
              subwayData[i][3].toDouble(),
              subwayData[i][4].toDouble()) <
          100) {
        subwayDataSorted.addAll([subwayData[i][2].toString().split("-")]);
        sortedStationsCount.add(i);
      }
    }
    List<String> max = [sortedStationsCount.last.toString()];
    subwayDataSorted.add(max);
    return subwayDataSorted;
  }

  List<String> returnStations(
      List<dynamic> subwayData, List<List<String>> sortedSubwayData) {
    int iterator = int.parse(sortedSubwayData.last[0]);
    List<String> output = [];
    for (int i = 0; i <= iterator; i++) {
      output.add(subwayData[i][0]);
    }
    return output;
  }

  List<String> returnStationNames(
      List<dynamic> subwayData, List<List<String>> sortedSubwayData) {
    int iterator = int.parse(sortedSubwayData.last[0]);
    print(sortedSubwayData);
    List<String> output = [];
    for (int i = 0; i <= iterator; i++) {
      output.add(subwayData[i][1]);
    }
    return output;
  }

  Future<void> callApi(Station station) async {
    final lineCounter = <String, int>{
      'ACE': 0,
      'BDFM': 0,
      'G': 0,
      'JZ': 0,
      'NQRW': 0,
      'L': 0,
      '1234567': 0,
      'SIR': 0
    };
    List<String> lineCaller = [];
    station.routeId.forEach((element) {
      element.forEach((element) {
        lineCaller.add(element);
      });
    });

    MtaApiCaller MTACaller = MtaApiCaller(
        lineCaller: lineCaller,
        apiStation: station.stopId,
        lineCounter: lineCounter);
    widget.masterList.clear();
    List<List<Subway>> output = await MTACaller.ApiIterator();
    widget.masterList = output[0];
  }

  Future<void> readCSVFile() async {
    subwayData.clear();
    var data = await rootBundle.loadString("lib/assets/Stations.csv");
    List<List<dynamic>> csvTable = CsvToListConverter().convert(data);
    subwayData = csvTable;
    subwayData.removeAt(0);
  }
}

class SubwayRouteDetails extends StatefulWidget {
  const SubwayRouteDetails(
      {super.key,
      required this.subwayData,
      required this.station,
      required this.index});
  final List<Subway> subwayData;
  final Station station;
  final int index;

  @override
  State<SubwayRouteDetails> createState() => _SubwayRouteDetailsState();
}

class _SubwayRouteDetailsState extends State<SubwayRouteDetails> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Row(children: [
          Column(
            children: [
              Text(
                "${widget.subwayData[widget.index].direction} ${widget.subwayData[widget.index].routeId} train",
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Spacer(),
          Icon(Icons.wifi),
          SizedBox(width: 10),
          Text(
            "${widget.subwayData[widget.index].arrivalTime} min",
            style: TextStyle(color: Colors.red),
          ),
        ])
      ]),
    );
  }
}
