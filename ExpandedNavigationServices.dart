import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:trip_reminder/database/user_info.dart';
import 'package:trip_reminder/forms/event_trip.dart';
import 'package:trip_reminder/forms/event_form.dart';
import 'profile/event_listings.dart';
import 'package:geocoding/geocoding.dart';
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
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          if (shouldPop == false) {
            //map_controller.dispose();
            positionStream!.pause();
          }
          shouldPop = true;
          return shouldPop;
        },
        child: Scaffold(
            appBar: AppBar(
                backgroundColor: Colors.lightBlue,
                elevation: 0,
                title: Text('Navigation',
                    style: TextStyle(
                      color: Colors.white,
                      letterSpacing: 2.0,
                    ))),
            body: flutter_osm_map_big()));
  }

  Widget flutter_osm_map_big() {
    setState(() {
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
              point: LatLng(
                  position!.latitude.toDouble(), position.longitude.toDouble()),
              builder: ((context) => Icon(Icons.circle)),
            ),
          );
          map_controller.center;
        });
      });
    });
    return FlutterMap(
      mapController: map_controller,
      options: MapOptions(
        center: LatLng(locationCoordinates[0], locationCoordinates[1]),
        zoom: 7.0,
        maxZoom: 19.0,
        keepAlive: true,
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
