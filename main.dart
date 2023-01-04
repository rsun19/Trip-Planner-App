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
import 'package:trip_reminder/ExpandedNavigationServices.dart';

void main() {
  runApp(MaterialApp(home: Home()));
}

enum RouteTaken { driving, walking, biking }

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  RouteTaken? _routeTaken = RouteTaken.driving;
  ValueNotifier<int> just_started = ValueNotifier(0);
  final TextEditingController _controller = TextEditingController();
  StreamSubscription<Position>? positionStream;
  StreamSubscription<Position>? positionStream1;
  Position? _position;
  //final initialMapController = MapController();
  final currentMapController = MapController();
  @override
  void initState() {
    _controller.text = "current location";
    just_started.value = 0;
    loadingLocation();
    super.initState();
  }

  void loadingLocation() async {
    if (just_started.value == 0) {
      initialMarkers.clear();
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.unableToDetermine) {
        LocationPermission permission = await Geolocator.requestPermission();
      } else if (permission == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
        await Geolocator.openLocationSettings();
      }
      _position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      initialMarkers.add(
        Marker(
          point: LatLng(
              _position!.latitude.toDouble(), _position!.longitude.toDouble()),
          builder: ((context) => Icon(Icons.circle)),
        ),
      );
      final LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
      );
      positionStream1 =
          Geolocator.getPositionStream(locationSettings: locationSettings)
              .listen((Position? position) {
        setState(() {
          initialMarkers.removeLast();
          _position = position;
          initialMarkers.add(
            Marker(
              point: LatLng(
                  position!.latitude.toDouble(), position.longitude.toDouble()),
              builder: ((context) => Icon(Icons.circle)),
            ),
          );
          // initialMapController.move(
          //     LatLng(_position!.latitude, _position!.longitude), 15.0);
        });
      });
    }
  }

  final TextEditingController _locationinput = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
              backgroundColor: Colors.lightBlue,
              elevation: 0,
              title: Text('Trip Planner',
                  style: TextStyle(
                    color: Colors.white,
                    letterSpacing: 2.0,
                  )),
              actions: <Widget>[
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                      return const EventTripInfo();
                    })).then((_) {
                      sortList();
                    });
                  },
                  icon: Icon(
                    Icons.add,
                    color: Colors.white,
                  ),
                  label: Text(
                    'Add a Trip',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ]),
          backgroundColor: Colors.blue,
          bottomNavigationBar: menu(),
          body: TabBarView(children: [
            FutureBuilder<List<Trip>>(
              //key: UniqueKey(),
              future: sortList(),
              builder: (context, snapshot) {
                if (snapshot.hasData &&
                    snapshot.connectionState == ConnectionState.done) {
                  return ListView.builder(
                      itemCount: snapshot.data!.length,
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                      itemBuilder: (context, index) {
                        return Center(
                            key: new Key(index.toString()),
                            child: TripRoute(
                              trip: snapshot.data![index],
                              onTap: () {
                                compareTimes(snapshot.data![index].title,
                                    snapshot.data![index].location);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          Profile(trip: snapshot.data![index])),
                                );
                              },
                            ));
                      });
                } else {
                  return CircularProgressIndicator();
                }
              },
            ),
            Column(children: [
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    scrollDirection: Axis.vertical,
                    shrinkWrap: true,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    children: <Widget>[
                      Container(
                        child: TextFormField(
                            controller: _controller,
                            decoration: const InputDecoration(
                              border: UnderlineInputBorder(),
                              labelText: "Where are you coming from?",
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter some text';
                              }
                              return null;
                            }),
                      ),
                      SizedBox(height: 5),
                      Container(
                        child: TextFormField(
                            controller: _locationinput,
                            decoration: const InputDecoration(
                              border: UnderlineInputBorder(),
                              labelText:
                                  "Where are you going? Enter as much information as possible.",
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter some text';
                              }
                              return null;
                            }),
                      ),
                      SizedBox(height: 5),
                      Row(children: [
                        Expanded(
                            child: ListTile(
                                title: Icon(Icons.directions_car),
                                leading: Radio<RouteTaken>(
                                  value: RouteTaken.driving,
                                  groupValue: _routeTaken,
                                  activeColor: Colors.white,
                                  onChanged: (RouteTaken? value) {
                                    setState(() {
                                      _routeTaken = value;
                                    });
                                  },
                                ))),
                        Expanded(
                            child: ListTile(
                                title: Icon(Icons.directions_walk),
                                leading: Radio<RouteTaken>(
                                  value: RouteTaken.walking,
                                  groupValue: _routeTaken,
                                  activeColor: Colors.white,
                                  onChanged: (RouteTaken? value) {
                                    setState(() {
                                      _routeTaken = value;
                                    });
                                  },
                                ))),
                        Expanded(
                            child: ListTile(
                                title: Icon(Icons.directions_bike),
                                leading: Radio<RouteTaken>(
                                  value: RouteTaken.biking,
                                  groupValue: _routeTaken,
                                  activeColor: Colors.white,
                                  onChanged: (RouteTaken? value) {
                                    setState(() {
                                      _routeTaken = value;
                                    });
                                  },
                                ))),
                      ]),
                      ElevatedButton(
                          child: const Text('Submit'),
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              final String tripName = _controller.text;
                              final String tripLocation = _locationinput.text;
                              String route = '';
                              if (_routeTaken == RouteTaken.driving) {
                                route = 'driving-car';
                              } else if (_routeTaken == RouteTaken.walking) {
                                route = 'foot-walking';
                              } else {
                                route = 'cycling-road';
                              }
                              LocationPermission permission =
                                  await Geolocator.checkPermission();
                              if (permission == LocationPermission.denied ||
                                  permission ==
                                      LocationPermission.unableToDetermine) {
                                LocationPermission permission =
                                    await Geolocator.requestPermission();
                              } else if (permission ==
                                  LocationPermission.deniedForever) {
                                await Geolocator.openAppSettings();
                                await Geolocator.openLocationSettings();
                              }
                              await coordinates(tripName, tripLocation);
                              await getJsonData(ORSCaller(
                                  latStart: locationCoordinates[0],
                                  longStart: locationCoordinates[1],
                                  latEnd: locationCoordinates[2],
                                  longEnd: locationCoordinates[3],
                                  tripRoute: route));
                              Position position =
                                  await Geolocator.getCurrentPosition(
                                      desiredAccuracy: LocationAccuracy.high);
                              final LocationSettings locationSettings =
                                  LocationSettings(
                                accuracy: LocationAccuracy.bestForNavigation,
                              );
                              markers.add(Marker(
                                point: LatLng(locationCoordinates[0],
                                    locationCoordinates[1]),
                                width: 80,
                                height: 80,
                                builder: (context) => Icon(Icons.location_pin),
                              ));
                              markers.add(
                                Marker(
                                  point: LatLng(locationCoordinates[2],
                                      locationCoordinates[3]),
                                  width: 80,
                                  height: 80,
                                  builder: (context) =>
                                      Icon(Icons.location_pin),
                                ),
                              );
                              just_started.value++;
                              //positionStream1!.pause();
                              //positionStream1!.cancel();
                              //initialMapController.dispose();
                              positionStream = Geolocator.getPositionStream(
                                      locationSettings: locationSettings)
                                  .listen((Position? position) {
                                setState(() {
                                  markers.removeLast();
                                  markers.add(
                                    Marker(
                                      point: LatLng(
                                          position!.latitude.toDouble(),
                                          position.longitude.toDouble()),
                                      builder: ((context) =>
                                          Icon(Icons.circle)),
                                    ),
                                  );
                                  //currentMapController.center;
                                });
                              });
                            }
                          }),
                      ValueListenableBuilder(
                        valueListenable: just_started,
                        builder: (context, value, widget) {
                          return Column(children: [
                            Container(
                                height:
                                    MediaQuery.of(context).size.height - 475,
                                child: flutter_osm_map()),
                            full_navigation_button()
                          ]);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ]),
          ]),
        ));
  }

  Widget full_navigation_button() {
    if (just_started.value == 0) {
      return SizedBox();
    } else {
      return ElevatedButton(
        onPressed: () {
          //positionStream!.cancel();
          Navigator.push(
              this.context,
              MaterialPageRoute(
                builder: (context) => const HomeMap(),
              ));
        },
        child: Text(
          style: TextStyle(color: Colors.white),
          'See full map and directions',
        ),
      );
    }
  }

  Widget flutter_osm_map() {
    if (just_started.value == 0) {
      try {
        return FlutterMap(
          // mapController: initialMapController,
          options: MapOptions(
            center: LatLng(_position!.latitude.toDouble(),
                _position!.longitude.toDouble()),
            zoom: 15.0,
            maxZoom: 19.0,
            keepAlive: true,
          ),
          children: [
            TileLayer(
              urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
              userAgentPackageName: 'com.trip_reminder.app',
            ),
            MarkerLayer(key: UniqueKey(), markers: initialMarkers),
          ],
        );
      } catch (e) {
        return Center(child: Text("Enter a valid address"));
      }
    } else {
      return FlutterMap(
        mapController: currentMapController,
        options: MapOptions(
          center: LatLng(locationCoordinates[0], locationCoordinates[1]),
          zoom: 10.0,
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
}

List<Marker> initialMarkers = [];
List<Marker> markers = [];
List<LatLng> points = [];
List<double> locationCoordinates = [];
List<double> temp_locationCoordinates = [];

Future<void> coordinates(tripName, tripLocation) async {
  locationCoordinates.clear();
  if (tripName.replaceAll(' ', '').toLowerCase() != 'currentlocation') {
    await getJsonDataForCoordinates(CoordinatesHelper(area: tripName));
    locationCoordinates.add(temp_locationCoordinates[0]);
    locationCoordinates.add(temp_locationCoordinates[1]);
  } else {
    Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            forceAndroidLocationManager: true)
        .then((Position position) {
      locationCoordinates.add(position.latitude.toDouble());
      locationCoordinates.add(position.longitude.toDouble());
    }).catchError((e) {
      print(e);
      print('an error occured above');
    });
  }
  temp_locationCoordinates.clear();
  await getJsonDataForCoordinates(CoordinatesHelper(area: tripLocation));
  points.clear();
  points.add(LatLng(locationCoordinates[0], locationCoordinates[1]));
  locationCoordinates.add(temp_locationCoordinates[0]);
  locationCoordinates.add(temp_locationCoordinates[1]);
  print(locationCoordinates);
}

Widget menu() {
  return Container(
      color: Colors.white,
      child: TabBar(
        labelColor: Colors.black,
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: EdgeInsets.all(5),
        tabs: [
          Tab(text: "Home", icon: Icon(Icons.home)),
          Tab(text: "Navigation", icon: Icon(Icons.navigation))
        ],
      ));
}

List<Trip> sortedDates = [];
List<Trip> passedDates = [];

Future<List<Trip>> sortList() async {
  String currentDay = DateTime.now().toIso8601String();
  sortedDates.clear();
  passedDates.clear();
  Database db = await UserDatabase.instance.database;
  int count = Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM eventPlanner'))
          ?.toInt() ??
      0;
  for (int i = 1; i <= count; i++) {
    final maps =
        await db.query(UserDatabase.table2, where: 'id2=?', whereArgs: [i]);
    sortedDates.add(Trip(
        title: maps[0]['tripName'].toString(),
        location: maps[0]['tripLocation'].toString(),
        start_date: maps[0]['tripStartDate'].toString(),
        end_date: maps[0]['tripEndDate'].toString()));
  }
  sortedDates.sort((a, b) {
    return a.start_date.compareTo(b.start_date);
  });
  for (var each in sortedDates) {
    if (each.end_date.compareTo(currentDay) < 1) {
      passedDates.add(each);
    }
  }
  sortedDates.removeWhere((e) => passedDates.contains(e));
  for (var each in passedDates) {
    sortedDates.add(each);
  }
  List<Trip> sentDates = [];
  for (var each in sortedDates) {
    sentDates.add(each);
  }
  return sentDates;
}

class Trip {
  final String title;
  final String location;
  final String start_date;
  final String end_date;
  const Trip(
      {required this.title,
      required this.location,
      required this.start_date,
      required this.end_date});
}

class TripRoute extends StatefulWidget {
  const TripRoute({
    super.key,
    required this.trip,
    required this.onTap,
  });
  final Trip trip;
  final onTap;

  @override
  State<TripRoute> createState() => _TripRouteState();
}

class _TripRouteState extends State<TripRoute> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: () {
          widget.onTap();
        },
        child: Container(
            margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black),
                borderRadius: BorderRadius.all(Radius.circular(15))),
            child: Row(
              children: <Widget>[
                Container(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      child: Text('Name: ${widget.trip.title}'),
                    ),
                    SizedBox(height: 20),
                    Container(
                      child: Text('Location: ${widget.trip.location}'),
                    ),
                    SizedBox(height: 20),
                    Container(child: dateChecker()),
                  ],
                )),
                Spacer(),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black),
                    borderRadius: BorderRadius.all(Radius.circular(15)),
                  ),
                  child: TextButton.icon(
                      onPressed: () {
                        _alertBuilder(context, widget.trip);
                        setState(() {});
                      },
                      icon: Icon(Icons.delete),
                      label: Text('Delete')),
                ),
              ],
            )));
  }

  Widget dateChecker() {
    if (widget.trip.start_date != '0000-00-00T00:00:00.000') {
      late var _start_date =
          DateFormat("yyyy-MM-dd").parse(widget.trip.start_date.split('T')[0]);
      late String start_date =
          DateFormat("MM/dd/yyyy").format(_start_date).toString();
      late var _end_date =
          DateFormat("yyyy-MM-dd").parse(widget.trip.end_date.split('T')[0]);
      late String end_date =
          DateFormat("MM/dd/yyyy").format(_end_date).toString();
      return Text('Dates: ${start_date} - ${end_date}');
    }
    return Text('Add an event!');
  }
}

Future delete(String tripName, String tripLocation) async {
  Database db = await UserDatabase.instance.database;
  final maps = await db.rawDelete(
      'DELETE FROM eventPlanner WHERE tripName = ? AND tripLocation = ?',
      [tripName, tripLocation]);
  await db.rawDelete(
      'DELETE FROM users WHERE tripNameEvent = ? AND tripLocationEvent = ?',
      [tripName, tripLocation]);
}

Future deleteFromList(Trip trip) async {
  if (sortedDates.contains(trip)) {
    sortedDates.remove(trip);
  }
}

Future<void> _alertBuilder(BuildContext context, trip) async {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Are you sure you want to delete this trip?'),
        actions: <Widget>[
          TextButton(
            child: const Text('Yes'),
            onPressed: () {
              delete(
                trip.title.toString(),
                trip.location.toString(),
              );
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Home(),
                  ));
            },
          ),
          TextButton(
            child: const Text('No'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}
