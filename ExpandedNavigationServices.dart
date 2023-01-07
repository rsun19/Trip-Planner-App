import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:trip_reminder/api-ORS/openRouteService.dart';
import 'package:trip_reminder/main.dart';
import 'package:trip_reminder/profile/event_listings.dart';
import 'package:flutter_compass/flutter_compass.dart';

class TurnNavigation {
  TurnNavigation({
    required this.distance,
    required this.duration,
    required this.instruction,
  });
  var distance;
  var duration;
  String instruction;
}

class HomeMap extends StatefulWidget {
  const HomeMap({super.key});
  @override
  State<HomeMap> createState() => _HomeMapState();
}

class _HomeMapState extends State<HomeMap> {
  StreamSubscription<Position>? _positionStream;
  bool shouldPop = false;
  final map_controller = MapController();
  double distance = (directions[0][0]['distance'] * 0.000621371);
  double total_distance = (directions[0][0]['distance'] * 0.000621371);
  double time = (directions[0][0]['duration'] / 60);
  String timeDisplay = '';
  List<dynamic>? getDirections;
  final Map<dynamic, int> _getDirections = {};
  TurnNavigation? turnNavigation;
  StreamSubscription<CompassEvent>? _heading;
  double? directionHeading;
  IconData? directionIcon;
  int followLocation = 0;
  String shownDistance = '';
  String turningInstructions = '';

  @override
  void initState() {
    getDirections = directions[0][0]['steps'];
    _getDirections.clear();
    for (int i = 0; i < nav_points.length; i++) {
      _getDirections[nav_points[i]] = i;
    }
    turnNavigation = TurnNavigation(
        distance: (getDirections![0]['distance'] * 0.000621371),
        duration: (getDirections![0]['duration'] / 60),
        instruction: getDirections![0]['instruction']);
    if (turnNavigation!.distance < .1) {
      shownDistance =
          '${(turnNavigation!.distance * 5280).toStringAsFixed(0)} feet';
    } else {
      shownDistance = '${(turnNavigation!.distance).toStringAsFixed(1)} miles';
    }
    turningInstructions = turnNavigation!.instruction;
    getDirectionIcon();
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
              top: 0,
              child: Center(
                child: Container(
                    width: MediaQuery.of(context).size.width - 10,
                    margin: EdgeInsets.fromLTRB(5, 50, 0, 0),
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        color: Colors.green,
                        //border: Border.all(color: Colors.black),
                        borderRadius: BorderRadius.all(Radius.circular(15))),
                    child: Row(children: [
                      Icon(
                        key: ObjectKey(directionIcon),
                        directionIcon,
                        color: Colors.white,
                      ),
                      SizedBox(
                        width: 20,
                      ),
                      Column(
                        children: [
                          Text(
                            key: ValueKey(turningInstructions),
                            '${turningInstructions}',
                            overflow: TextOverflow.fade,
                            style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                          Text('$shownDistance',
                              key: ValueKey(shownDistance),
                              style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold))
                        ],
                      )
                    ])),
              )),
          Positioned(
              bottom: 0,
              child: Container(
                  margin: EdgeInsets.fromLTRB(40, 0, 0, 20),
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      color: Colors.lightBlue,
                      //border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.all(Radius.circular(15))),
                  child: Column(
                    children: [
                      Text(
                        key: ValueKey(distance),
                        'Distance: ${distance.truncate().toString()} miles',
                        style: TextStyle(fontSize: 18),
                      ),
                      Text(
                        'Time: ${time.truncate().toString()} minutes',
                        style: TextStyle(fontSize: 18),
                      )
                    ],
                  )))
        ]),
        floatingActionButton:
            Column(mainAxisAlignment: MainAxisAlignment.end, children: [
          FloatingActionButton(
            backgroundColor: Colors.blue,
            child: Icon(Icons.location_on),
            onPressed: () {
              followLocation++;
            },
            heroTag: null,
          ),
          SizedBox(height: 20),
          FloatingActionButton(
            backgroundColor: Colors.red,
            child: Text('Exit'),
            onPressed: () {
              Navigator.push(this.context,
                  MaterialPageRoute(builder: (context) => const Home()));
            },
            heroTag: null,
          )
        ]));
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
        zoom: 17.0,
        maxZoom: 19.0,
        keepAlive: true,
        onMapReady: () {
          final LocationSettings locationSettings = LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
          );
          _heading = FlutterCompass.events!.listen(
            (event) {
              setState(() {
                directionHeading = event.heading;
              });
              if (directionHeading != null && followLocation.isEven) {
                map_controller.rotate(directionHeading!);
              }
            },
          );
          _positionStream =
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
              if (followLocation.isEven) {
                map_controller.move(
                    LatLng(position.latitude, position.longitude), 17);
              }
              if (nav_points.isNotEmpty == true) {
                turnNavigation!.distance = Geolocator.distanceBetween(
                        position.latitude,
                        position.longitude,
                        nav_points[getDirections![0]['way_points'][0]].latitude,
                        nav_points[getDirections![0]['way_points'][0]]
                            .longitude) *
                    0.000621371;
                if (turnNavigation!.distance < .1) {
                  shownDistance =
                      '${(turnNavigation!.distance * 5280).toStringAsFixed(0)} feet';
                } else {
                  shownDistance =
                      '${(turnNavigation!.distance).toStringAsFixed(1)} miles';
                }
                if (getDirections![0]['instruction'].toString().length > 29) {
                  turningInstructions = getDirections![0]['instruction']
                          .toString()
                          .substring(0, 30) +
                      "...";
                } else {
                  turningInstructions =
                      getDirections![0]['instruction'].toString();
                }
                distance = total_distance -
                    (getDirections![0]['distance'] * 0.000621371) -
                    (getDirections![0]['distance'] * 0.000621371 -
                        turnNavigation!.distance);
              }
              if (nav_points.isNotEmpty &&
                  turnNavigation!.distance * 5280 < 50) {
                total_distance -= getDirections![0]['distance'] * 0.000621371;
                distance = total_distance;
                time -= turnNavigation!.duration;
                getDirections!.removeAt(0);
                nav_points.removeAt(0);
                turnNavigation = TurnNavigation(
                    distance: (getDirections![0]['distance'] * 0.000621371),
                    duration: (getDirections![0]['duration'] / 60),
                    instruction: getDirections![0]['instruction'].toString());
                if (turnNavigation!.distance < .1) {
                  shownDistance =
                      '${(turnNavigation!.distance * 5280).toStringAsFixed(0)} feet';
                } else {
                  shownDistance =
                      '${(turnNavigation!.distance).toStringAsFixed(1)} miles';
                }
                if (getDirections![0]['instruction'].toString().length > 29) {
                  turningInstructions = getDirections![0]['instruction']
                          .toString()
                          .substring(0, 30) +
                      "...";
                } else {
                  turningInstructions =
                      getDirections![0]['instruction'].toString();
                }
                getDirectionIcon();
              } else if (nav_points.isEmpty == true) {
                turnNavigation = TurnNavigation(
                    distance: 0, duration: 0, instruction: 'You have arrived');
                distance = 0;
                time = 0;
                total_distance = 0;
                shownDistance = '';
                turningInstructions = 'You have arrived';
                getDirectionIcon();
              }
            });
          });
        },
      ),
      children: [
        TileLayer(
          urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
          userAgentPackageName: 'com.trip_reminder.app',
        ),
        PolylineLayer(
          polylineCulling: false,
          polylines: [
            Polyline(strokeWidth: 5, points: points, color: Colors.blue)
          ],
        ),
        MarkerLayer(key: UniqueKey(), markers: markers),
      ],
    );
  }

  void getDirectionIcon() {
    List<String> instructions =
        turnNavigation!.instruction.toLowerCase().split(' ');
    if (instructions.contains('sharp')) {
      if (instructions.contains('left')) {
        directionIcon = turnIcons['sharpleft'];
      } else if (instructions.contains('right')) {
        directionIcon = turnIcons['sharpright'];
      }
    } else if (instructions.contains('slight')) {
      if (instructions.contains('left')) {
        directionIcon = turnIcons['slightleft'];
      } else if (instructions.contains('right')) {
        directionIcon = turnIcons['slightright'];
      }
    } else if (instructions.contains('left')) {
      directionIcon = turnIcons['left'];
    } else if (instructions.contains('right')) {
      directionIcon = turnIcons['right'];
    } else if (instructions.contains('arrived') ||
        instructions.contains('arriving')) {
      directionIcon = turnIcons['arrived'];
    } else {
      directionIcon = turnIcons['straight'];
    }
  }

  Map<String, IconData> turnIcons = {
    "left": Icons.turn_left,
    "right": Icons.turn_right,
    "sharpleft": Icons.turn_sharp_left,
    "sharpright": Icons.turn_sharp_right,
    "slightleft": Icons.turn_slight_left,
    "slightright": Icons.turn_slight_right,
    "straight": Icons.arrow_upward,
    "arrived": Icons.location_pin
  };
}
