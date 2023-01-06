import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:trip_reminder/api-ORS/openRouteService.dart';
import 'package:trip_reminder/main.dart';

class HomeMap extends StatefulWidget {
  const HomeMap({super.key});
  @override
  State<HomeMap> createState() => _HomeMapState();
}

class _HomeMapState extends State<HomeMap> {
  StreamSubscription<Position>? positionStream;
  bool shouldPop = false;
  final map_controller = MapController();
  double distance = (directions[0][0]['distance'] * 0.000621371);
  double time = (directions[0][0]['duration'] / 60);

  @override
  void initState() {
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   Future.delayed(Duration(seconds: 3), () => positionStreaming());
    // });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: <Widget>[
        flutter_osm_map_big(),
        Positioned(
            bottom: 0,
            child: Container(
                margin: EdgeInsets.fromLTRB(40, 0, 0, 20),
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: Colors.lightBlue,
                    border: Border.all(color: Colors.black),
                    borderRadius: BorderRadius.all(Radius.circular(15))),
                child: Column(
                  children: [
                    Text(
                      'Distance: ${distance.truncate()} miles',
                      style: TextStyle(fontSize: 18),
                    ),
                    Text(
                      'Time: ${time.truncate()} minutes',
                      style: TextStyle(fontSize: 18),
                    )
                  ],
                )))
      ]),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.red,
        child: Text("Exit"),
        onPressed: () {
          Navigator.push(this.context,
              MaterialPageRoute(builder: (context) => const Home()));
        },
      ),
    );
  }

  Widget flutter_osm_map_big() {
    if (mounted) {
      setState(() {
        final LocationSettings locationSettings = LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
        );
      });
    }
    return FlutterMap(
      mapController: map_controller,
      options: MapOptions(
        center: LatLng(locationCoordinates[0], locationCoordinates[1]),
        zoom: 7.0,
        maxZoom: 19.0,
        keepAlive: true,
        onMapReady: () {
          final LocationSettings locationSettings = LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
          );
          positionStream =
              Geolocator.getPositionStream(locationSettings: locationSettings)
                  .listen((Position? position) {
            setState(() {
              markers.removeLast();
              markers.add(
                Marker(
                  point: LatLng(position!.latitude.toDouble(),
                      position.longitude.toDouble()),
                  builder: ((context) => Icon(Icons.circle)),
                ),
              );
              map_controller.move(
                  LatLng(position.latitude, position.longitude), 13);
            });
          });
        },
      ),
      children: [
        TileLayer(
          urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
          userAgentPackageName: 'com.trip_reminder.app',
        ),
        MarkerLayer(key: UniqueKey(), markers: markers),
        PolylineLayer(
          polylineCulling: false,
          polylines: [
            Polyline(strokeWidth: 5, points: points, color: Colors.blue)
          ],
        ),
      ],
    );
  }
}
