import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:trip_reminder/database/user_info.dart';
import 'package:trip_reminder/forms/event_trip.dart';
import 'package:trip_reminder/forms/event_form.dart';
import 'profile/event_listings.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:trip_reminder/api-ORS/openRouteService.dart';
import 'package:trip_reminder/ExpandedNavigationServices.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; //show json;
import "package:firebase_core/firebase_core.dart";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MaterialApp(home: SignInScreen()));
}

enum RouteTaken { driving, walking, biking }

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  GoogleSignInAccount? _currentUser;
  GoogleSignInAuthentication? googleAuth;
  FirebaseAuth? firebaseUser;
  String loginText = '';
  GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  void initState() {
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
      setState(() {
        _currentUser = account;
      });
    });
    _signInSilently();
    super.initState();
  }

  void _signInSilently() async {
    try {
      await handleSignIn();
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.lightBlue, body: buildLogInScreen());
  }

  Widget buildLogInScreen() {
    final GoogleSignInAccount? user = _currentUser;
    if (firebaseUser?.currentUser != null) {
      return Home(
        firebaseUser: firebaseUser,
        googleSignIn: _googleSignIn,
        currentUser: _currentUser,
      );
    } else {
      return ConstrainedBox(
          constraints: const BoxConstraints.expand(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Welcome to Trip Reminder',
                style: TextStyle(fontSize: 30, color: Colors.white),
              ),
              SizedBox(height: 30),
              Text(
                'Manage, Find, and Navigate Trip Itineraries',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
              SizedBox(height: 30),
              Container(
                  color: Colors.green,
                  child: TextButton(
                      child: Text(
                        'Google Log In',
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: handleSignIn)),
              SizedBox(height: 30),
              Container(
                  color: Colors.green,
                  child: TextButton(
                      child: Text(
                        'Continue As Guest',
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) => Home()));
                      })),
            ],
          ));
    }
  }

  Future<void> handleSignIn() async {
    try {
      _currentUser = await _googleSignIn.signIn();
      googleAuth = await _currentUser!.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth!.accessToken, idToken: googleAuth!.idToken);
      firebaseUser = FirebaseAuth.instance;
      await firebaseUser!.signInWithCredential(credential);
      await checkIfNewUser();
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => Home(
                    firebaseUser: firebaseUser,
                    googleSignIn: _googleSignIn,
                    currentUser: _currentUser,
                  )));
    } catch (e) {
      loginText = 'Login failed';
    }
  }

  Future<void> checkIfNewUser() async {
    if (firebaseUser != null) {
      final QuerySnapshot result = await FirebaseFirestore.instance
          .collection('users')
          .where('id', isEqualTo: firebaseUser!.currentUser!.uid)
          .get();
      final List<DocumentSnapshot> documents = result.docs;
      print(documents[0].data());
      List<DocumentSnapshot<Object?>> userData = [];
      if (documents.isEmpty) {
        FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser!.currentUser!.uid)
            .set({
          'nickname': firebaseUser!.currentUser!.displayName,
          'photoURL': firebaseUser!.currentUser!.photoURL,
          'id': firebaseUser!.currentUser!.uid
        });
      }
    }
  }

  Future<void> handleSignOut() async {
    await FirebaseAuth.instance.signOut();
    await _googleSignIn.disconnect();
    await _googleSignIn.signOut();
  }
}

class Home extends StatefulWidget {
  Home(
      {super.key,
      FirebaseAuth? firebaseUser,
      GoogleSignIn? googleSignIn,
      GoogleSignInAccount? currentUser});
  FirebaseAuth? firebaseUser;
  GoogleSignIn? googleSignIn;
  GoogleSignInAccount? currentUser;
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
  bool? locationLookUp;
  bool? directionLookUp;
  final initialMapController = MapController();
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
    }
  }

  final TextEditingController _locationinput = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: 3,
        child: Scaffold(
          backgroundColor: Colors.blue,
          bottomNavigationBar: menu(),
          body: TabBarView(children: [
            Stack(children: [
              trip_list(),
              Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    margin: EdgeInsets.fromLTRB(0, 0, 20, 20),
                    padding: EdgeInsets.all(10),
                    child: ElevatedButton.icon(
                      style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all<Color>(Colors.lightBlue),
                        padding: MaterialStateProperty.all<EdgeInsets>(
                            EdgeInsets.all(10)),
                      ),
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
                  ))
            ]),
            ViewProfile(),
            Column(children: [
              Container(
                  alignment: Alignment.topLeft,
                  padding: EdgeInsets.fromLTRB(20, 50, 0, 0),
                  child: Text(
                    "Navigation",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                    ),
                  )),
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
                              directionLookUp = await getJsonData(ORSCaller(
                                  latStart: locationCoordinates[0],
                                  longStart: locationCoordinates[1],
                                  latEnd: locationCoordinates[2],
                                  longEnd: locationCoordinates[3],
                                  tripRoute: route));
                              if (locationLookUp == false ||
                                  directionLookUp == false) {
                                await AlertDialog(
                                    title: const Text(
                                        'Inquiry failed. Location or directions may not exist'),
                                    actions: <Widget>[
                                      TextButton(
                                        child: const Text('Ok'),
                                        onPressed: () {
                                          setState(() {});
                                        },
                                      )
                                    ]);
                              }
                              points.add(LatLng(locationCoordinates[2],
                                  locationCoordinates[3]));
                              Position position =
                                  await Geolocator.getCurrentPosition(
                                      desiredAccuracy: LocationAccuracy.high);
                              final LocationSettings locationSettings =
                                  LocationSettings(
                                accuracy: LocationAccuracy.bestForNavigation,
                              );
                              try {
                                markers.add(Marker(
                                  point: LatLng(locationCoordinates[0],
                                      locationCoordinates[1]),
                                  width: 80,
                                  height: 80,
                                  builder: (context) =>
                                      Icon(Icons.location_pin),
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
                              } catch (e) {
                                locationLookUp = false;
                              }
                              just_started.value++;
                              positionStream = Geolocator.getPositionStream(
                                      locationSettings: locationSettings)
                                  .listen((Position? position) {
                                if (mounted) {
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
                                    currentMapController.move(
                                        LatLng(position.latitude,
                                            position.longitude),
                                        13);
                                  });
                                }
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

  Widget trip_list() {
    if (sortedDates.isEmpty) {
      return Column(children: [
        Container(
            alignment: Alignment.topLeft,
            padding: EdgeInsets.fromLTRB(20, 50, 0, 0),
            child: Text(
              "Trips",
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
              ),
            )),
        Container(
            margin: EdgeInsets.symmetric(vertical: 40),
            child: Text(
              "Add a trip to get started",
              style: TextStyle(
                fontSize: 25,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ))
      ]);
    } else {
      return Column(children: [
        Container(
            alignment: Alignment.topLeft,
            padding: EdgeInsets.fromLTRB(20, 40, 0, 0),
            child: Text(
              "Trips",
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
              ),
            )),
        FutureBuilder<List<Trip>>(
          future: sortList(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return ListView.builder(
                  itemCount: snapshot.data!.length,
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  itemBuilder: (context, index) {
                    return Center(
                        key: ObjectKey(Trip),
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
        )
      ]);
    }
  }

  Widget ViewProfile() {
    // if (widget.firebaseUser == null) {
    //   return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    //     Container(
    //         padding: EdgeInsets.symmetric(vertical: 20),
    //         child: Text(
    //           "Please log in before accessing this page",
    //           style: TextStyle(
    //             fontSize: 20,
    //             color: Colors.white,
    //             fontWeight: FontWeight.bold,
    //           ),
    //         )),
    //     TextButton(
    //         style: ButtonStyle(
    //           backgroundColor:
    //               MaterialStateProperty.all<Color>(Colors.lightBlue),
    //           padding:
    //               MaterialStateProperty.all<EdgeInsets>(EdgeInsets.all(10)),
    //         ),
    //         onPressed: () {
    //           Navigator.push(
    //               context,
    //               MaterialPageRoute(
    //                 builder: (context) => const SignInScreen(),
    //               ));
    //         },
    //         child: Text(
    //           "Log in",
    //           style: TextStyle(color: Colors.white),
    //         )),
    //   ]);
    // } else {
    return Container(
        child: StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection('users')
                .limit(1)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return CircularProgressIndicator();
              } else {
                return Container(
                    padding: EdgeInsets.symmetric(vertical: 50, horizontal: 20),
                    child: Column(
                      children: [
                        Container(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "Profile",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                              ),
                            )),
                        Container(
                            alignment: Alignment.topLeft,
                            margin: EdgeInsets.symmetric(vertical: 10),
                            child: Text('Search for all public iternaries',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 15))),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Expanded(
                                  flex: 4,
                                  child: TextField(
                                    decoration: InputDecoration(
                                        fillColor: Colors.white,
                                        filled: true,
                                        hintText:
                                            'City, State or City, Country',
                                        hintStyle:
                                            TextStyle(color: Colors.black),
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            borderSide: BorderSide.none)),
                                  )),
                              Spacer(),
                              Expanded(
                                  flex: 1,
                                  child: TextButton.icon(
                                      style: ButtonStyle(
                                          backgroundColor:
                                              MaterialStatePropertyAll(
                                                  Colors.white),
                                          padding: MaterialStateProperty.all<
                                                  EdgeInsets>(
                                              EdgeInsets.symmetric(
                                                  vertical: 18)),
                                          shape: MaterialStateProperty.all(
                                              RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10)))),
                                      onPressed: () {},
                                      icon: Icon(Icons.search),
                                      label: Text('')))
                            ]),
                        SizedBox(height: 20),
                        CircleAvatar(
                            radius: 50,
                            backgroundImage: NetworkImage(
                              // snapshot.data?.docs.toString() ??
                              "https://www.shutterstock.com/image-vector/default-profile-picture-avatar-photo-260nw-1681253560.jpg",
                              scale: 5,
                            )),
                        SizedBox(
                          height: 10,
                        ),
                        Container(
                            alignment: Alignment.center,
                            child: Text(
                              'Hi ${snapshot.data ?? 'User log-in failed.'}',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            )),
                        TextButton(
                            style: ButtonStyle(
                              backgroundColor:
                                  MaterialStateProperty.all<Color>(Colors.red),
                            ),
                            onPressed: handleSignOut,
                            child: Text('Sign Out',
                                style: TextStyle(color: Colors.white)))
                      ],
                    ));
              }
            }));
    //}
  }

  Widget full_navigation_button() {
    if (just_started.value == 0) {
      return SizedBox();
    } else {
      return ElevatedButton(
        onPressed: () {
          // positionStream!.cancel();
          // currentMapController.dispose();
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
          mapController: initialMapController,
          options: MapOptions(
            center: LatLng(_position!.latitude.toDouble(),
                _position!.longitude.toDouble()),
            zoom: 15.0,
            maxZoom: 19.0,
            keepAlive: true,
            onMapReady: () {
              final LocationSettings locationSettings = LocationSettings(
                accuracy: LocationAccuracy.bestForNavigation,
              );
              positionStream1 = Geolocator.getPositionStream(
                      locationSettings: locationSettings)
                  .listen((Position position) {
                if (mounted) {
                  setState(() {
                    initialMarkers.removeLast();
                    initialMarkers.add(
                      Marker(
                        point: LatLng(position.latitude.toDouble(),
                            position.longitude.toDouble()),
                        builder: ((context) => Icon(Icons.circle)),
                      ),
                    );
                    initialMapController.move(
                        LatLng(position.latitude, position.longitude), 13);
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
            MarkerLayer(
                key: ObjectKey(initialMarkers.last), markers: initialMarkers),
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
          zoom: 13.0,
          maxZoom: 19.0,
          keepAlive: true,
        ),
        children: [
          TileLayer(
            urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            userAgentPackageName: 'com.trip_reminder.app',
          ),
          MarkerLayer(key: ObjectKey(markers.last), markers: markers),
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

  Future<void> coordinates(tripName, tripLocation) async {
    try {
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
          locationLookUp = false;
        });
      }
      temp_locationCoordinates.clear();
      await getJsonDataForCoordinates(CoordinatesHelper(area: tripLocation));
      points.clear();
      points.add(LatLng(locationCoordinates[0], locationCoordinates[1]));
      locationCoordinates.add(temp_locationCoordinates[0]);
      locationCoordinates.add(temp_locationCoordinates[1]);
      print(locationCoordinates);
      locationLookUp = true;
    } catch (e) {
      locationLookUp = false;
    }
  }

  Future<void> handleSignOut() async {
    await FirebaseAuth.instance.signOut();
    await widget.googleSignIn!.disconnect();
    await widget.googleSignIn!.signOut();
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SignInScreen(),
        ));
  }
}

List<Marker> initialMarkers = [];
List<Marker> markers = [];
List<LatLng> points = [];
List<double> locationCoordinates = [];
List<double> temp_locationCoordinates = [];

Widget menu() {
  return Container(
      color: Colors.white,
      child: TabBar(
        labelColor: Colors.black,
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: EdgeInsets.all(5),
        tabs: [
          Tab(text: "Home", icon: Icon(Icons.home)),
          Tab(text: "Search", icon: Icon(Icons.search)),
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
