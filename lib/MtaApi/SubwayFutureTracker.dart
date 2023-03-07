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
import 'package:intl/intl.dart';

class FutureSubwayTracker extends StatefulWidget {
  const FutureSubwayTracker({
    super.key,
    required this.subwayData,
    required this.stationData,
    required this.fullStationData,
  });
  final Subway subwayData;
  final StationName stationData;
  final List<List<dynamic>> fullStationData;
  @override
  State<FutureSubwayTracker> createState() => _FutureSubwayTrackerState();
}

class _FutureSubwayTrackerState extends State<FutureSubwayTracker> {
  List<List<dynamic>> stopTimes = [];

  @override
  Widget build(BuildContext context) {
    return InkWell();
  }

  Widget TimeBuilder() {
    return FutureBuilder<List<dynamic>>(
      future: loadArrivalTimes(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return ListView.builder(
              itemCount: snapshot.data!.length,
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              itemBuilder: (context, index) {
                return Center(
                    child: DisplayArrivalTimes(
                        parsedData: snapshot.data![index],
                        fullStationData: widget.fullStationData));
              });
        } else {
          return CircularProgressIndicator(
            backgroundColor: Colors.white,
          );
        }
      },
    );
  }

  Future<List<dynamic>> loadArrivalTimes() async {
    List<String> currentDates = findDay();
    await readCSVFile();
    return await compareData(currentDates);
  }

  List<String> findDay() {
    DateTime date = DateTime.now();
    String weekday = DateFormat.EEEE(date).toString();
    String weekdayCase =
        "${weekday[0].toUpperCase()}${weekday.substring(1).toLowerCase()}";
    String currentTime = DateFormat("h:mm:ss a").format(date).toString();
    return [weekdayCase, currentTime];
  }

  Future<void> readCSVFile() async {
    stopTimes.clear();
    var data = await rootBundle.loadString("lib/assets/stopTimes.csv");
    List<List<dynamic>> csvTable = CsvToListConverter().convert(data);
    stopTimes = csvTable;
    stopTimes.removeAt(0);
  }

  Future<List<List<dynamic>>> compareData(List<String> currentData) async {
    stopTimes.retainWhere((station) =>
        currentData[0].toString() == station[0].toString() &&
        widget.subwayData.tripId == station[2].toString().substring(3, 14));
    DateTime addedTime = DateTime.parse(widget.subwayData.baselineTime)
        .add(Duration(seconds: int.parse(widget.subwayData.arrivalTime)));
    String stopTime = '';
    stopTimes.forEach((station) {
      if (station[5].toString() == widget.subwayData.fullStopId) {
        stopTime = station[3].toString();
        int index = stopTimes.indexOf(station);
        stopTimes = stopTimes.sublist(index + 1);
      }
    });
    final comparedTime = DateTime.parse(stopTime).difference(addedTime);
    int difference = comparedTime.inSeconds;
    stopTimes.forEach((times) {
      times[3] = DateTime.parse(times[3].toString())
          .add(Duration(minutes: difference));
      times[3] = DateFormat.Hm(times[3].toString());
    });
    return stopTimes;
  }
}

class DisplayArrivalTimes extends StatefulWidget {
  const DisplayArrivalTimes(
      {super.key, required this.parsedData, required this.fullStationData});

  final List<dynamic> parsedData;
  final List<List<dynamic>> fullStationData;

  @override
  State<DisplayArrivalTimes> createState() => _DisplayArrivalTimesState();
}

class _DisplayArrivalTimesState extends State<DisplayArrivalTimes> {
  @override
  Widget build(BuildContext context) {
    return Container(
        child: SizedBox(
      height: 50,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Row(children: [
          Column(
            children: [findEquivalentStations()],
          ),
          Spacer(),
          Icon(Icons.wifi),
          SizedBox(width: 10),
          Text(
            "${widget.parsedData[3]} min",
            style: TextStyle(color: Colors.red),
          ),
        ])
      ]),
    ));
  }

  Widget findEquivalentStations() {
    for (int i = 0; i < widget.fullStationData.length; i++) {
      if (widget.parsedData[5]
          .toString()
          .contains(widget.fullStationData[i][0].toString())) {
        return Text(widget.fullStationData[i][1]);
      }
    }
    return SizedBox();
  }
}
