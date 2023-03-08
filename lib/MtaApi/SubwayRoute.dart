import 'package:flutter/material.dart';
import 'package:trip_reminder/MtaApi/SubwayFutureTracker.dart';
import 'package:trip_reminder/main.dart';
import 'package:trip_reminder/MtaApi/Subway.dart';
import 'package:trip_reminder/MtaApi/SubwayArrivalsScreen.dart';

import 'package:geolocator/geolocator.dart';
import 'package:trip_reminder/AlertDialog.dart';

import 'MTAAPI.dart';
import 'package:flutter_map/flutter_map.dart';

import 'package:latlong2/latlong.dart';
import 'package:trip_reminder/api-ORS/openRouteService.dart';
import 'package:trip_reminder/main.dart';
import 'package:trip_reminder/ExpandedNavigationServices.dart';

class SubwayRoute extends StatefulWidget {
  const SubwayRoute(
      {super.key,
      required this.subwayData,
      this.onTap,
      required this.station,
      required this.stationNames,
      // required this.fullStationData,
      required this.distanceData});
  final onTap;
  final List<Subway> subwayData;
  final Station station;
  final StationName stationNames;
  //final List<List<dynamic>> fullStationData;
  final String distanceData;

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
                    stationName: widget.stationNames,
                    //fullStationData: widget.fullStationData
                  )),
        );
      },
      child: SizedBox(
          height: 175,
          child: Container(
              margin: EdgeInsets.only(bottom: 20),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.white),
                  borderRadius: BorderRadius.all(Radius.circular(20))),
              child: Column(children: [
                Text(
                  "${widget.stationNames.stationName}",
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                ),
                Text(
                  "Lines: ${widget.stationNames.routeId}",
                  style: TextStyle(color: Colors.black),
                ),
                Text("Distance: ${widget.distanceData.substring(0, 4)} miles"),
                TextButton.icon(
                    onPressed: () async {
                      Position position = await Geolocator.getCurrentPosition(
                        desiredAccuracy: LocationAccuracy.best,
                      );
                      markers.clear();
                      points.clear();
                      if (locationCoordinates.isEmpty) {
                        locationCoordinates.add(position.latitude);
                        locationCoordinates.add(position.longitude);
                      }
                      markers.add(
                        Marker(
                            point:
                                LatLng(position.latitude, position.longitude),
                            builder: ((context) => Icon(Icons.navigation))),
                      );
                      points.add(LatLng(position.latitude, position.longitude));
                      await getJsonData(ORSCaller(
                          latStart: points[0].latitude,
                          longStart: points[0].longitude,
                          latEnd: double.parse(
                              widget.stationNames.stationCoordinates[0]),
                          longEnd: double.parse(
                              widget.stationNames.stationCoordinates[1]),
                          tripRoute: 'foot-walking'));
                      markers.add(
                        Marker(
                            point: LatLng(
                                double.parse(
                                    widget.stationNames.stationCoordinates[0]),
                                double.parse(
                                    widget.stationNames.stationCoordinates[1])),
                            builder: ((context) => Icon(Icons.circle))),
                      );
                      points.add(
                        LatLng(
                            double.parse(
                                widget.stationNames.stationCoordinates[0]),
                            double.parse(
                                widget.stationNames.stationCoordinates[1])),
                      );
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HomeMap(),
                          ));
                    },
                    icon: Icon(Icons.navigation),
                    label: Text('Navigate')),
              ]))),
    );
  }
}

class SubwayListBuilder extends StatefulWidget {
  SubwayListBuilder({
    super.key,
    required this.masterList,
    required this.station,
    required this.stationName,
    //required this.fullStationData
  });
  List<Subway> masterList;
  Station station;
  final StationName stationName;
  //final List<List<dynamic>> fullStationData;

  @override
  State<SubwayListBuilder> createState() => _SubwayListBuilderState();
}

class _SubwayListBuilderState extends State<SubwayListBuilder> {
  List<List<dynamic>> subwayData = [];
  List<String> coordinates = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue,
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
                      icon: Icon(
                        Icons.subway,
                        color: Colors.white,
                      ),
                      label: Text('Click to refresh',
                          style: TextStyle(color: Colors.white)))),
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
          return Expanded(
              child: ListView.builder(
                  key: ObjectKey(widget.masterList),
                  itemCount: snapshot.data!.length,
                  shrinkWrap: true,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  itemBuilder: (context, index) {
                    return Center(
                        key: ObjectKey(widget.masterList),
                        child: SubwayRouteDetails(
                          stationData: widget.stationName,
                          subwayData: widget.masterList[index],
                          //fullStationData: widget.fullStationData,
                          //onTap: () {
                          // Navigator.push(
                          //   context,
                          //   MaterialPageRoute(
                          //       builder: (context) => FutureSubwayTracker(
                          //           subwayData: snapshot.data![index],
                          //           stationData: widget.stationName,
                          //           fullStationData: widget.fullStationData)),
                          // );
                          //},
                        ));
                  }));
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
    try {
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
    } catch (e) {}
  }
}

class SubwayRouteDetails extends StatefulWidget {
  const SubwayRouteDetails({
    super.key,
    required this.subwayData,
    required this.stationData,
    //required this.onTap,
    //required this.fullStationData
  });
  final Subway subwayData;
  final StationName stationData;
  //final List<List<dynamic>> fullStationData;
  //final onTap;
  @override
  State<SubwayRouteDetails> createState() => _SubwayRouteDetailsState();
}

class _SubwayRouteDetailsState extends State<SubwayRouteDetails> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: 75,
        child: Container(
          margin: EdgeInsets.only(bottom: 20),
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.white),
              borderRadius: BorderRadius.all(Radius.circular(20))),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Row(key: ObjectKey(widget.subwayData), children: [
              Column(
                children: [
                  Text(
                    "${widget.subwayData.direction} ${widget.subwayData.routeId} train",
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Spacer(),
              Icon(Icons.wifi),
              SizedBox(width: 10),
              Text(
                "${widget.subwayData.arrivalTime} min",
                style: TextStyle(color: Colors.red),
              ),
            ])
          ]),
        ));
  }
}
