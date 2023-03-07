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

  List<List<Subway>> masterList = [];

  List<StationName> stationNames = [];

  List<List<dynamic>> fullStationData = [];

  List<String> distanceFromPosition = [];

  late Station station; //= Station(routeId: [], stopId: [], stationName: []);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.lightBlue,
          title: Text(
            "Real-Time Subway Tracker",
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
                    label: Text('Click to refresh'))),
          ]),
          stationBuilder(),
        ]));
  }

  Widget stationBuilder() {
    return FutureBuilder<List<StationName>>(
      key: ObjectKey(masterList),
      future: getCurrentPositionUtilityMethod(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return ListView.builder(
              itemCount: snapshot.data!.length,
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              itemBuilder: (context, index) {
                return Center(
                    child: SubwayRoute(
                  station: station,
                  subwayData: masterList[index],
                  stationNames: snapshot.data![index],
                  fullStationData: fullStationData,
                  distanceData: distanceFromPosition[index],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => SubwayListBuilder(
                              station: station,
                              masterList: masterList[index],
                              stationName: snapshot.data![index],
                              fullStationData: fullStationData)),
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

  Future<List<StationName>> getCurrentPositionUtilityMethod() async {
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
    return stationNames;
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
    List<List<String>> sortedSubwayData = subwayComparator(subwayData);
    List<String> stationData = returnStations(subwayData, sortedSubwayData);
    List<String> stationName = returnStationNames(subwayData, sortedSubwayData);
    List<List<String>> stationCoordinates =
        findClosestFromPosition(sortedSubwayData, subwayData);
    sortedSubwayData.removeLast();
    station = Station(
        routeId: sortedSubwayData,
        stopId: stationData,
        stationName: stationName);
    await callApi(station);
    stationNames.clear();
    for (int i = 0; i < station.stationName.length; i++) {
      StationName stationInfo = StationName(
          routeId: station.routeId[i],
          stopId: station.stopId[i],
          stationName: station.stationName[i],
          stationCoordinates: stationCoordinates[i]);
      stationNames.add(stationInfo);
    }
    // } catch (e) {
    //   print('failure');
    //   return failedAlertBuilder(
    //       context,
    //       "Real-time Subway Data is not available at this moment.",
    //       "Refresh page",
    //       "Return home");
    // }
    return SizedBox();
  }

  List<List<String>> findClosestFromPosition(
      List<List<String>> sortedSubwayData, List<List<dynamic>> _subwayData) {
    int iterator = int.parse(sortedSubwayData.last[0]);
    distanceFromPosition.clear();
    List<List<String>> _coordinates = [];
    for (int i = 0; i <= iterator; i++) {
      String distanceBetween = (Geolocator.distanceBetween(
                  double.parse(coordinates[0].toString()),
                  double.parse(coordinates[1].toString()),
                  _subwayData[i][3],
                  _subwayData[i][4]) *
              0.000621371)
          .toString();
      distanceFromPosition.add(distanceBetween);
      _coordinates.addAll([
        [_subwayData[i][3], _subwayData[i][4]]
      ]);
    }
    return _coordinates;
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
          600) {
        subwayDataSorted.addAll([subwayData[i][2].toString().split("-")]);
        sortedStationsCount.add(i);
      }
    }
    subwayDataSorted.toSet().toList();
    List<String> max = [sortedStationsCount.last.toString()];
    subwayDataSorted.add(max);
    return subwayDataSorted;
  }

  List<String> returnStations(
      List<dynamic> subwayData, List<List<String>> sortedSubwayData) {
    int iterator = int.parse(sortedSubwayData.last[0]);
    List<String> output = [];
    for (int i = 0; i <= iterator; i++) {
      output.add(subwayData[i][0].toString());
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
    masterList.clear();
    masterList = await MTACaller.ApiIterator();
  }

  Future<void> readCSVFile() async {
    subwayData.clear();
    var data = await rootBundle.loadString("lib/assets/Stations.csv");
    List<List<dynamic>> csvTable = CsvToListConverter().convert(data);
    subwayData = csvTable;
    fullStationData = csvTable;
    subwayData.removeAt(0);
  }
}
