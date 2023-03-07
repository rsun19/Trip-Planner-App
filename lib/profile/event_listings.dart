import 'dart:async';
import 'package:trip_reminder/globals.dart' as globals;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:trip_reminder/database/user_info.dart';
import 'package:trip_reminder/forms/event_form.dart';
import 'package:sqflite/sqflite.dart';
import 'package:trip_reminder/main.dart';
import 'package:trip_reminder/ExpandedNavigationServices.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:trip_reminder/api-ORS/openRouteService.dart';
import 'package:trip_reminder/main.dart';
import 'package:trip_reminder/forms/changeItinerary.dart';
import 'package:trip_reminder/TripClass.dart';

const List<TripEvent> events = const <TripEvent>[];

Future<void> fetchRows() async {
  Database db = await UserDatabase.instance.database;
  int count =
      Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM users'))
              ?.toInt() ??
          0;
  events.clear();
  for (int i = 1; i <= count; i++) {
    TripEvent map = await get(i);
    events.add(map);
  }
}

Future<TripEvent> get(int id) async {
  Database db = await UserDatabase.instance.database;
  final maps =
      await db.query(UserDatabase.table, where: 'id2=?', whereArgs: [id]);
  return TripEvent(
      name: maps[0][0].toString(),
      description: maps[0][1].toString(),
      dateTime: maps[0][2].toString(),
      location: maps[0][3].toString(),
      fullAddress: maps[0][4].toString());
}

class Profile extends StatefulWidget {
  const Profile(
      {super.key,
      required this.trip,
      this.name,
      this.description,
      this.dateTime,
      this.location});
  final Trip trip;
  final String? name;
  final String? description;
  final String? dateTime;
  final String? location;

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  Position? _position;
  StreamSubscription<Position>? positionStream;
  ValueNotifier<int> just_started = ValueNotifier(0);

  @override
  void initState() {
    eventParser();
    just_started.value++;
    //sortedList();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            elevation: 0,
            title: Text(
              '${widget.trip.title}',
              style: TextStyle(
                color: Colors.white,
                letterSpacing: 2.0,
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return UserFormCase(trip: widget.trip);
                  }));
                },
                child: Text(
                  'Add More Events',
                  style: TextStyle(
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.lightBlue,
          bottomNavigationBar: eventMenu(),
          body: TabBarView(children: [
            SizedBox(
                height: 1000,
                width: 1000,
                child: FutureBuilder<List<TripEvent>>(
                    future: sortedList(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Column(children: [
                          SizedBox(height: 10),
                          Text(
                            "Upcoming Events",
                            style: TextStyle(color: Colors.white, fontSize: 25),
                          ),
                          Expanded(
                              child: ListView.builder(
                                  //physics: AlwaysScrollableScrollPhysics(),
                                  key: ObjectKey(TripEvent),
                                  itemCount: eventSortedDates.length,
                                  shrinkWrap: true,
                                  padding:
                                      const EdgeInsets.fromLTRB(20, 0, 20, 0),
                                  itemBuilder: (context, index) {
                                    return Center(
                                      child: EventInfo(
                                        tripevent: eventSortedDates[index],
                                        trip: widget.trip,
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) => EventView(
                                                    trip: widget.trip,
                                                    tripevent: eventSortedDates[
                                                        index])),
                                          );
                                        },
                                      ),
                                    );
                                  })),
                          Text(
                            "Passed Events",
                            style: TextStyle(color: Colors.white, fontSize: 25),
                          ),
                          Expanded(
                              child: ListView.builder(
                                  //physics: AlwaysScrollableScrollPhysics(),
                                  key: ObjectKey(TripEvent),
                                  itemCount: eventPassedDates.length,
                                  shrinkWrap: true,
                                  padding:
                                      const EdgeInsets.fromLTRB(20, 0, 20, 0),
                                  itemBuilder: (context, index) {
                                    return Center(
                                      child: EventInfo(
                                        tripevent: eventPassedDates[index],
                                        trip: widget.trip,
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) => EventView(
                                                    trip: widget.trip,
                                                    tripevent: eventPassedDates[
                                                        index])),
                                          );
                                        },
                                      ),
                                    );
                                  }))
                        ]);
                      } else {
                        return CircularProgressIndicator();
                      }
                    })),
            ValueListenableBuilder(
                valueListenable: just_started,
                builder: ((context, value, widget) {
                  return flutter_osm_map_big();
                }))
          ]),
          floatingActionButton: TextButton(
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all<Color>(Colors.red),
              padding:
                  MaterialStateProperty.all<EdgeInsets>(EdgeInsets.all(10)),
            ),
            child: Text(
              'Change itinerary name or location',
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChangeTripName(trip: widget.trip),
                  ));
            },
          ),
        ));
  }

  Future<List<TripEvent>> sortedList() async {
    String currentDay = DateTime.now().toIso8601String();
    eventSortedDates.clear();
    eventPassedDates.clear();
    Database db = await UserDatabase.instance.database;
    int count =
        Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM users'))
                ?.toInt() ??
            0;
    for (int i = 1; i <= count; i++) {
      final maps =
          await db.query(UserDatabase.table, where: 'id=?', whereArgs: [i]);
      if (maps[0]['tripNameEvent'] == widget.trip.title &&
          maps[0]["tripLocationEvent"] == widget.trip.location) {
        eventSortedDates.add(TripEvent(
            name: maps[0]['name'].toString(),
            description: maps[0]['description'].toString(),
            dateTime: maps[0]['dateTime'].toString(),
            location: maps[0]['location'].toString(),
            fullAddress: maps[0]['fullAddress'].toString()));
      }
    }
    eventSortedDates.sort((a, b) {
      return a.dateTime.compareTo(b.dateTime);
    });
    for (var each in eventSortedDates) {
      if (each.dateTime.compareTo(currentDay) < 0) {
        eventPassedDates.add(each);
      }
    }
    // List<TripEvent> sentEvents = [];
    eventSortedDates.removeWhere((e) => eventPassedDates.contains(e));
    // for (var each in eventPassedDates) {
    //   eventSortedDates.add(each);
    // }
    // for (var each in eventSortedDates) {
    //   sentEvents.add(each);
    // }
    // for (var each in eventPassedDates) {
    //   sentEvents.add(each);
    // }
    await eventParser();
    return eventSortedDates;
  }

  Widget eventMenu() {
    return Container(
        color: Colors.white,
        child: TabBar(
          labelColor: Colors.black,
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorPadding: EdgeInsets.all(5),
          tabs: [
            Tab(text: "Events", icon: Icon(Icons.notes)),
            Tab(text: "Maps", icon: Icon(Icons.map))
          ],
        ));
  }

  Widget flutter_osm_map_big() {
    if (allEvents.length == 0) {
      return Center(child: Text("Please enter some events"));
    } else {
      return FlutterMap(
        options: MapOptions(
          center: LatLng(_position!.latitude, _position!.longitude),
          zoom: 13.0,
          maxZoom: 19.0,
          keepAlive: true,
          onMapReady: () {
            final LocationSettings locationSettings = LocationSettings(
              accuracy: LocationAccuracy.bestForNavigation,
            );
            positionStream =
                Geolocator.getPositionStream(locationSettings: locationSettings)
                    .listen((Position? position) {
              if (this.mounted) {
                setState(() {
                  initialMarkers.removeLast();
                  _position = position;
                  globals.currentPosition = position;
                  initialMarkers.add(
                    Marker(
                      point: LatLng(position!.latitude.toDouble(),
                          position.longitude.toDouble()),
                      builder: ((context) => Icon(Icons.circle)),
                    ),
                  );
                });
              }
            });
          },
        ),
        children: [
          TileLayer(
            urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            userAgentPackageName: 'com.trip_reminder.app',
          ),
          MarkerLayer(key: ObjectKey(allEvents.last), markers: allEvents),
        ],
      );
    }
  }

  List<Marker> allEvents = [];

  Future<List<Marker>> eventParser() async {
    allEvents.clear();
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.unableToDetermine) {
      LocationPermission permission = await Geolocator.requestPermission();
    } else if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      await Geolocator.openLocationSettings();
    }
    Database db = await UserDatabase.instance.database;
    int count =
        Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM users'))
                ?.toInt() ??
            0;
    for (int i = 1; i <= count; i++) {
      final maps =
          await db.query(UserDatabase.table, where: 'id=?', whereArgs: [i]);
      if (maps[0]['tripNameEvent'] == widget.trip.title &&
          maps[0]['tripLocationEvent'] == widget.trip.location) {
        var location = maps[0]['location'].toString();
        List<dynamic> _location = location.split(",");
        print(_location);
        allEvents.add(Marker(
          point: LatLng(double.parse(_location[0]), double.parse(_location[1])),
          width: 80,
          height: 80,
          builder: (context) => Icon(Icons.location_pin),
        ));
      }
    }
    _position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    globals.currentPosition = _position;
    allEvents.add(
      Marker(
        point: LatLng(
            _position!.latitude.toDouble(), _position!.longitude.toDouble()),
        builder: ((context) => Icon(Icons.circle)),
      ),
    );
    print(allEvents);
    return allEvents;
  }
}

class EventInfo extends StatefulWidget {
  const EventInfo({
    super.key,
    required this.tripevent,
    required this.trip,
    required this.onTap,
  });

  final TripEvent tripevent;
  final VoidCallback onTap;
  final Trip trip;

  @override
  State<EventInfo> createState() => _EventInfoState();
}

class _EventInfoState extends State<EventInfo> {
  @override
  late List dateTimeList = widget.tripevent.dateTime.split('T');
  late var _date = DateFormat("yyyy-MM-dd").parse(dateTimeList[0]);
  late var date = DateFormat("MM/dd/yyyy").format(_date);
  late var _time = DateFormat.Hm().parse(dateTimeList[1].substring(0, 5));
  late var time = DateFormat.jm().format(_time);
  late String location = widget.tripevent.location;
  late List destination_coordinates = widget.tripevent.location.split(",");
  late double lat = double.parse(destination_coordinates[0]);
  late double lng = double.parse(destination_coordinates[1]);
  late String fullAddress = widget.tripevent.fullAddress;
  Position? _position;

  Widget build(BuildContext context) {
    return InkWell(
        onTap: () {
          widget.onTap();
        },
        child: Container(
            height: 200,
            width: MediaQuery.of(context).size.height,
            margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.white),
                borderRadius: BorderRadius.all(Radius.circular(15))),
            child: Row(children: <Widget>[
              Container(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      child: Text(
                        'Name: ${widget.tripevent.name}',
                        style: TextStyle(
                            //fontSize: 20,
                            //letterSpacing: .5,
                            ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Container(
                      child: Text(
                        'Date: ${date}' + ' at ' + '${time}',
                        style: TextStyle(
                            //fontSize: 20,
                            //letterSpacing: .5,
                            ),
                      ),
                    ),
                    SizedBox(height: 40),
                    Row(children: [
                      Container(
                          decoration: BoxDecoration(
                              border: Border.all(color: Colors.black),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(15))),
                          child: TextButton.icon(
                              onPressed: () {
                                showModalBottomSheet(
                                    context: context,
                                    builder: (context) {
                                      return Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          ListTile(
                                              leading: Icon(Icons.navigation),
                                              title:
                                                  Text('Use In-App Navigation'),
                                              onTap: () {
                                                markers.clear();
                                                points.clear();
                                                if (locationCoordinates
                                                    .isEmpty) {
                                                  locationCoordinates.add(
                                                      globals.currentPosition!
                                                          .latitude);
                                                  locationCoordinates.add(
                                                      globals.currentPosition!
                                                          .longitude);
                                                }
                                                markers.add(
                                                  Marker(
                                                      point: LatLng(
                                                          globals
                                                              .currentPosition!
                                                              .latitude,
                                                          globals
                                                              .currentPosition!
                                                              .longitude),
                                                      builder: ((context) =>
                                                          Icon(Icons
                                                              .navigation))),
                                                );
                                                points.add(LatLng(
                                                    globals.currentPosition!
                                                        .latitude,
                                                    globals.currentPosition!
                                                        .longitude));
                                                _navigationChoice(
                                                    context, lat, lng);
                                              }),
                                          ListTile(
                                              leading: Icon(Icons.navigation),
                                              title: Text('Use Google Maps'),
                                              onTap: () {
                                                MapsLauncher.launchQuery(widget
                                                    .tripevent.fullAddress);
                                              })
                                        ],
                                      );
                                    });
                              },
                              icon: Icon(Icons.navigation),
                              label: Text('Navigate'))),
                      SizedBox(width: (MediaQuery.of(context).size.width) / 4),
                      Container(
                          decoration: BoxDecoration(
                              border: Border.all(color: Colors.black),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(15))),
                          child: TextButton.icon(
                              onPressed: () {
                                _alertBuilder(
                                    context, widget.trip, widget.tripevent);
                                setState(() {});
                              },
                              icon: Icon(Icons.delete),
                              label: Text('Delete'))),
                    ]),
                  ],
                ),
              ),
            ])));
  }
}

class EventView extends StatefulWidget {
  const EventView({
    super.key,
    required this.trip,
    required this.tripevent,
  });

  final Trip trip;
  final TripEvent tripevent;

  @override
  State<EventView> createState() => _EventViewState();
}

class _EventViewState extends State<EventView> {
  late List dateTimeList = widget.tripevent.dateTime.split('T');
  late var _date = DateFormat("yyyy-MM-dd").parse(dateTimeList[0]);
  late var date = DateFormat("MM/dd/yyyy").format(_date);
  late var _time = DateFormat.Hm().parse(dateTimeList[1].substring(0, 5));
  late var time = DateFormat.jm().format(_time);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          '${widget.tripevent.name}',
          style: TextStyle(
            color: Colors.white,
            letterSpacing: 2.0,
          ),
        ),
      ),
      body: Center(
        child: Container(
          height: 700,
          width: 300,
          margin: EdgeInsets.fromLTRB(0, 0, 0, 0),
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black),
              borderRadius: BorderRadius.all(Radius.circular(15))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                child: Text(
                  'Name: ${widget.tripevent.name}',
                  style: TextStyle(
                    fontSize: 20,
                    letterSpacing: .5,
                  ),
                ),
              ),
              SizedBox(height: 20),
              Container(
                child: Text(
                  'Date: ${date}' + ' at ' + '${time}',
                  style: TextStyle(
                      //fontSize: 20,
                      //letterSpacing: .5,
                      ),
                ),
              ),
              SizedBox(height: 20),
              Container(
                child: Text(
                  'Location: ${widget.tripevent.fullAddress}',
                  style: TextStyle(
                      //fontSize: 20,
                      //letterSpacing: .5,
                      ),
                ),
              ),
              SizedBox(height: 20),
              Container(
                child: Text(
                  'Description: ${widget.tripevent.description}',
                  style: TextStyle(
                      //fontSize: 20,
                      //letterSpacing: .5,
                      ),
                ),
              ),
              Spacer(),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.all(Radius.circular(15)),
                ),
                child: TextButton.icon(
                    onPressed: () {
                      _alertBuilder(context, widget.trip, widget.tripevent);
                      setState(() {});
                    },
                    icon: Icon(Icons.delete),
                    label: Text('Delete')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

List<TripEvent> eventSortedDates = [];
List<TripEvent> eventPassedDates = [];
List<Marker> temp_marker = [];
List<LatLng> temp_point = [];

Future<void> _navigationChoice(BuildContext context, lat, lng) async {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('How would you like to travel?'),
        actions: <Widget>[
          TextButton(
            child: const Text('Driving'),
            onPressed: () async {
              await getJsonData(ORSCaller(
                  latStart: points[0].latitude,
                  longStart: points[0].longitude,
                  latEnd: lat,
                  longEnd: lng,
                  tripRoute: 'driving-car'));
              markers.add(
                Marker(
                    point: LatLng(lat, lng),
                    builder: ((context) => Icon(Icons.circle))),
              );
              points.add(
                LatLng(lat, lng),
              );
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HomeMap(),
                  ));
            },
          ),
          TextButton(
            child: const Text('Walking'),
            onPressed: () async {
              await getJsonData(ORSCaller(
                  latStart: points[0].latitude,
                  longStart: points[0].longitude,
                  latEnd: lat,
                  longEnd: lng,
                  tripRoute: 'foot-walking'));
              markers.add(
                Marker(
                    point: LatLng(lat, lng),
                    builder: ((context) => Icon(Icons.circle))),
              );
              points.add(
                LatLng(lat, lng),
              );
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HomeMap(),
                  ));
            },
          ),
          TextButton(
            child: const Text('Biking'),
            onPressed: () async {
              await getJsonData(ORSCaller(
                  latStart: points[0].latitude,
                  longStart: points[0].longitude,
                  latEnd: lat,
                  longEnd: lng,
                  tripRoute: 'cycling-road'));
              markers.add(
                Marker(
                    point: LatLng(lat, lng),
                    builder: ((context) => Icon(Icons.circle))),
              );
              points.add(
                LatLng(lat, lng),
              );
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HomeMap(),
                  ));
            },
          ),
        ],
      );
    },
  );
}

Future<void> _alertBuilder(
    BuildContext context, Trip trip, TripEvent tripevent) async {
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
                  tripevent.name.toString(),
                  tripevent.description.toString(),
                  tripevent.dateTime.toString(),
                  tripevent.fullAddress.toString());
              compareTimes(trip.title.toString(), trip.location.toString());
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

Future delete(String tripName, String description, String datetime,
    String fullAddress) async {
  Database db = await UserDatabase.instance.database;
  final maps = await db.rawDelete(
      'DELETE FROM users WHERE name = ? AND description = ? AND dateTime = ? AND fullAddress = ?',
      [tripName, description, datetime, fullAddress]);
}
