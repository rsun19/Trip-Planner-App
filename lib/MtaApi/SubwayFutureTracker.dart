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
  });
  final Subway subwayData;
  final StationName stationData;
  @override
  State<FutureSubwayTracker> createState() => _FutureSubwayTrackerState();
}

class _FutureSubwayTrackerState extends State<FutureSubwayTracker> {
  List<List<dynamic>> stopTimes = [];

  @override
  Widget build(BuildContext context) {
    return Container();
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
