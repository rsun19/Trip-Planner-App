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
  const SubwayRoute({
    super.key,
    required this.subwayData,
    this.onTap,
    required this.station,
    required this.stationNames,
  });
  final onTap;
  final List<Subway> subwayData;
  final Station station;
  final StationName stationNames;

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
                  station: widget.station,
                  masterList: widget.subwayData,
                  stationName: widget.stationNames)),
        );
      },
      child: SizedBox(
          height: 75,
          child: Column(children: [
            Text(
              "${widget.stationNames.stationName}",
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
            Text(
              "Lines: ${widget.stationNames.routeId}",
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
      required this.masterList,
      required this.station,
      required this.stationName});
  List<Subway> masterList;
  Station station;
  final StationName stationName;

  @override
  State<SubwayListBuilder> createState() => _SubwayListBuilderState();
}

class _SubwayListBuilderState extends State<SubwayListBuilder> {
  List<List<dynamic>> subwayData = [];
  List<String> coordinates = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.stationName.stationName)),
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
      key: ObjectKey(widget.masterList),
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
    await getCurrentPosition();
    return widget.masterList;
  }

  Future<Widget> getCurrentPosition() async {
    //await readCSVFile();
    await findClosestPosition();
    return SizedBox();
  }

  Future<Widget> findClosestPosition() async {
    try {
      await callApi();
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
      subwayData[0][2].toString().split('-').toSet().toList()
    ];
    return subwayDataSorted;
  }

  List<String> returnStations(
      List<dynamic> subwayData, List<List<String>> sortedSubwayData) {
    return subwayData[0][0];
  }

  List<String> returnStationNames(
      List<dynamic> subwayData, List<List<String>> sortedSubwayData) {
    return subwayData[0][1];
  }

  Future<void> callApi() async {
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
    MtaApiCaller MTACaller = MtaApiCaller(
        lineCaller: widget.stationName.routeId,
        apiStation: [widget.stationName.stopId],
        lineCounter: lineCounter);
    widget.masterList.clear();
    List<List<Subway>> output = await MTACaller.ApiIterator();
    widget.masterList = output[0];
    print(output[0]);
    print(widget.masterList);
  }

  Future<void> readCSVFile() async {
    subwayData.clear();
    coordinates.clear();
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
        Row(key: ObjectKey(widget.subwayData), children: [
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
