library trip_reminder.globals;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:latlong2/latlong.dart';

Position? currentPosition;
GoogleSignInAccount? currentUser;
GoogleSignIn? googleSignIn;
FirebaseAuth? firebaseUser;
