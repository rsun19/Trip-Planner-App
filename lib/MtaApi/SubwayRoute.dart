import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:trip_reminder/database/user_info.dart';
import 'package:trip_reminder/main.dart';
import 'package:trip_reminder/MtaApi/Subway.dart';
import 'package:trip_reminder/MtaApi/SubwayArrivalsScreen.dart';

class SubwayRoute extends StatefulWidget {
  const SubwayRoute({super.key, required this.subway, this.onTap});
  final onTap;
  final Subway subway;

  @override
  State<SubwayRoute> createState() => _SubwayRouteState();
}

class _SubwayRouteState extends State<SubwayRoute> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: () {
          widget.onTap;
        },
        child: Column(children: [
          Row(children: [
            Column(
              children: [
                Text(
                  "${widget.subway.direction} ${widget.subway.routeId} train",
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Spacer(),
            Text(
              "${widget.subway.arrivalTime} min",
              style: TextStyle(color: Colors.red),
            ),
          ]),
          SizedBox(height: 20)
        ]));
  }
}

class SubwayRouteDetails extends StatefulWidget {
  const SubwayRouteDetails({super.key, required this.subway});
  final Subway subway;

  @override
  State<SubwayRouteDetails> createState() => _SubwayRouteDetailsState();
}

class _SubwayRouteDetailsState extends State<SubwayRouteDetails> {
  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}
