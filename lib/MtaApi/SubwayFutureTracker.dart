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

class FutureSubwayTracker extends StatefulWidget {
  const FutureSubwayTracker({super.key});

  @override
  State<FutureSubwayTracker> createState() => _FutureSubwayTrackerState();
}

class _FutureSubwayTrackerState extends State<FutureSubwayTracker> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
