import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:trip_reminder/database/user_info.dart';
import 'package:trip_reminder/main.dart';
import 'package:trip_reminder/MtaApi/Subway.dart';
import 'package:trip_reminder/MtaApi/SubwayArrivalsScreen.dart';

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
  final Station station;
  final String stationName;
  final int index;

  late List<Subway> masterList = subwayData[index];

  @override
  State<SubwayListBuilder> createState() => _SubwayListBuilderState();
}

class _SubwayListBuilderState extends State<SubwayListBuilder> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.stationName)),
      body: SizedBox(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: subwayArrivalsBuilder()),
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
      child: Column(children: [
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
          Text(
            "${widget.subwayData[widget.index].arrivalTime} min",
            style: TextStyle(color: Colors.red),
          ),
        ])
      ]),
    );
  }
}
