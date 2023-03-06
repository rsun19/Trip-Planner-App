import 'dart:async';
import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:csv/csv.dart';
import 'package:trip_reminder/MtaApi/MTAAPI.dart';
import 'package:trip_reminder/AlertDialog.dart';
import 'package:trip_reminder/MtaApi/Subway.dart';
import 'package:trip_reminder/MtaApi/SubwayRoute.dart';

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

  bool apiCallSuccess = true;

  List<Subway> masterList = [];

  late Station station;

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
              key: ObjectKey(Station),
              'Station: ${station.stationName ?? ''}. Lines: ${station.routeId.toString() ?? ''}'),
          SizedBox(height: 20),
          subwayArrivalsBuilder(),
          alertBuilderController(),
        ]));
  }

  Widget subwayArrivalsBuilder() {
    return FutureBuilder<List<Subway>>(
      future: getCurrentPositionUtilityMethod(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return ListView.builder(
              key: ObjectKey(masterList),
              itemCount: snapshot.data!.length,
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              itemBuilder: (context, index) {
                return Center(
                    key: ObjectKey(masterList),
                    child: SubwayRoute(
                      subway: snapshot.data![index],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SubwayRouteDetails(
                                  subway: snapshot.data![index])),
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
    );
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

  Future<List<Subway>> getCurrentPositionUtilityMethod() async {
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
    return masterList;
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
    List<String> sortedSubwayData = subwayComparator(subwayData);
    List<String> stationData = returnStations(sortedSubwayData);
    station = Station(
        routeId: sortedSubwayData,
        stopId: stationData,
        stationName: subwayData[0][1].toString());
    await callApi(station);
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

  List<String> subwayComparator(List<List<dynamic>> subwayData) {
    List<String> subwayDataSorted = subwayData[0][2].toString().split('-');
    List<int> sortedStationsCount = [];
    for (int i = 0; i < subwayData.length; i++) {
      if (subwayData[0][3] == subwayData[i][3] &&
          subwayData[0][4] == subwayData[i][4]) {
        subwayDataSorted.addAll(subwayData[i][2].toString().split("-"));
        sortedStationsCount.add(i);
      }
    }
    String max = sortedStationsCount[-1].toString();
    subwayDataSorted.add(max);
    return subwayDataSorted;
  }

  List<String> returnStations(List<String> sortedSubwayData) {
    int iterator = int.parse(sortedSubwayData[-1]);
    List<String> output = [];
    for (int i = 0; i <= iterator; i++) {
      output.add(sortedSubwayData[i][0]);
    }
    return output;
  }

  Future<void> callApi(Station station) async {
    MtaApiCaller MTACaller =
        MtaApiCaller(lineCaller: station.routeId, apiStation: station.stopId);
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
