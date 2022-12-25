import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:trip_reminder/database/user_info.dart';
import 'package:trip_reminder/forms/event_trip.dart';
import 'package:trip_reminder/forms/event_form.dart';
import 'profile/event_listings.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:trip_reminder/api-ORS/openRouteService.dart';

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
  late Position _currentPosition;
  RouteTaken? _routeTaken = RouteTaken.driving;
  final TextEditingController _controller = TextEditingController();
  @override
  void initState() {
    _controller.text = "current location";
    super.initState();
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
                      Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                          child: ListTile(
                              title: const Text('Driving'),
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
                      Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20,
                          ),
                          child: ListTile(
                              title: const Text('Walking'),
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
                      Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20,
                          ),
                          child: ListTile(
                              title: const Text('Biking'),
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
                              await coordinates(tripName, tripLocation);
                              await getJsonData(ORSCaller(
                                  latStart: locationCoordinates[0],
                                  longStart: locationCoordinates[1],
                                  latEnd: locationCoordinates[2],
                                  longEnd: locationCoordinates[3],
                                  tripRoute: route));
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => HomeMap(),
                                  ));
                            }
                          })
                    ],
                  ),
                ),
                //flutter_map()
              ),
              //Expanded(child: flutter_osm_map()),
            ]),
          ]),
        ));
  }
}

List<LatLng> points = [];

class HomeMap extends StatefulWidget {
  const HomeMap({super.key});

  @override
  State<HomeMap> createState() => _HomeMapState();
}

class _HomeMapState extends State<HomeMap> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.lightBlue,
          elevation: 0,
          title: Text('Map',
              style: TextStyle(
                color: Colors.white,
                letterSpacing: 2.0,
              ))),
      body: flutter_osm_map(),
    );
  }
}

Widget flutter_osm_map() {
  return FlutterMap(
    //mapController: mapController,
    options: MapOptions(
      center: LatLng(locationCoordinates[0], locationCoordinates[1]),
      zoom: 13.0,
      maxZoom: 19.0,
      keepAlive: true,
    ),
    children: [
      TileLayer(
        urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
        userAgentPackageName: 'com.trip_reminder.app',
      ),
      MarkerLayer(
        markers: [
          Marker(
            point: LatLng(locationCoordinates[0], locationCoordinates[1]),
            width: 80,
            height: 80,
            builder: (context) => Icon(Icons.circle),
          ),
          Marker(
            point: LatLng(locationCoordinates[2], locationCoordinates[3]),
            width: 80,
            height: 80,
            builder: (context) => Icon(Icons.navigation),
          ),
        ],
      ),
      PolylineLayer(
        polylineCulling: false,
        polylines: [
          Polyline(strokeWidth: 5, points: points, color: Colors.blue)
        ],
      ),
    ],
  );
}

List<double> locationCoordinates = [];

Future<void> coordinates(tripName, tripLocation) async {
  locationCoordinates.clear();
  if (tripName.replaceAll(' ', '').toLowerCase() != 'currentlocation') {
    List<Location> locations = await locationFromAddress(tripName);
    locationCoordinates.add(locations[0].latitude);
    locationCoordinates.add(locations[0].longitude);
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
  List<Location> _locations = await locationFromAddress(tripLocation);
  locationCoordinates.add(_locations[0].latitude);
  locationCoordinates.add(_locations[0].longitude);
  points.clear();
  // points.add(LatLng(locationCoordinates[0], locationCoordinates[1]));
  // points.add(LatLng(locationCoordinates[2], locationCoordinates[3]));
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
  final VoidCallback onTap;

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
