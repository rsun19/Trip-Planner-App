import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:trip_reminder/SearchResults.dart';
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
import 'package:trip_reminder/SearchResults.dart';
import 'package:trip_reminder/globals.dart' as globals;
import 'TripClass.dart';
import 'main.dart';

class SignInScreen extends StatefulWidget {
  SignInScreen({super.key, this.googleSignIn});
  GoogleSignIn? googleSignIn;
  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  GoogleSignInAccount? _currentUser;
  GoogleSignInAuthentication? googleAuth;
  FirebaseAuth? firebaseUser;
  String loginText = '';

  @override
  void initState() {
    globals.currentUser = null;
    globals.googleSignIn = null;
    globals.firebaseUser = null;
    if (widget.googleSignIn == null) {
      widget.googleSignIn = GoogleSignIn();
    }
    widget.googleSignIn!.onCurrentUserChanged
        .listen((GoogleSignInAccount? account) {
      setState(() {
        _currentUser = account;
        globals.currentUser = account;
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
    //}
  }

  Future<void> handleSignIn() async {
    try {
      _currentUser = await widget.googleSignIn!.signIn();
      googleAuth = await _currentUser!.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth!.accessToken, idToken: googleAuth!.idToken);
      firebaseUser = FirebaseAuth.instance;
      await firebaseUser!.signInWithCredential(credential);
      await checkIfNewUser();
      globals.currentUser = _currentUser;
      globals.firebaseUser = firebaseUser;
      globals.googleSignIn = widget.googleSignIn;
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => Home(
                    firebaseUser: firebaseUser,
                    googleSignIn: widget.googleSignIn,
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
      print(documents);
      if (documents.length == 0) {
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
}
