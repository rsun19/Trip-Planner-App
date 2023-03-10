import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:latlong2/latlong.dart';
import 'package:trip_reminder/main.dart';
import 'package:trip_reminder/auth/secrets.dart';

class ORSCaller {
  ORSCaller({
    required this.latStart,
    required this.longStart,
    required this.latEnd,
    required this.longEnd,
    required this.tripRoute,
  });

  final String url = 'https://api.openrouteservice.org/v2/directions/';
  final String apiKey = secretApiKey;
  final String tripRoute;
  final double latStart;
  final double longStart;
  final double latEnd;
  final double longEnd;

  Future getData() async {
    http.Response response = await http.get(Uri.parse(
        '$url$tripRoute?api_key=$apiKey&start=$longStart,$latStart&end=$longEnd,$latEnd'));
    print(
        '$url$tripRoute?api_key=$apiKey&start=$longStart,$latStart&end=$longEnd,$latEnd');
    if (response.statusCode == 200) {
      String data = response.body;
      return jsonDecode(data);
    } else {
      print(response.statusCode);
    }
  }
}

Future getJsonData(ORSCaller orsCaller) async {
  directions.clear();
  nav_points.clear();
  ORSCaller directionsInfo = ORSCaller(
      latStart: orsCaller.latStart,
      longStart: orsCaller.longStart,
      latEnd: orsCaller.latEnd,
      longEnd: orsCaller.longEnd,
      tripRoute: orsCaller.tripRoute);
  try {
    var data = await directionsInfo.getData();
    print(data);
    Directions line =
        Directions(data['features'][0]['geometry']['coordinates']);
    NavigtionDirections turns =
        NavigtionDirections(data['features'][0]['properties']['segments']);
    directions.add(turns.turns);
    for (int i = 0; i < line.directions.length; i++) {
      points.add(LatLng(line.directions[i][1], line.directions[i][0]));
      nav_points.add(LatLng(line.directions[i][1], line.directions[i][0]));
    }
  } catch (e) {
    print(e);
  }
}

List<LatLng> nav_points = [];
List<dynamic> directions = [];

class Directions {
  Directions(this.directions);
  List<dynamic> directions;
}

class NavigtionDirections {
  NavigtionDirections(this.turns);
  List<dynamic> turns;
}

class CoordinatesHelper {
  CoordinatesHelper({required this.area});
  final String area;
  final String apiKey = secretApiKey;
  final String url = 'https://api.openrouteservice.org/geocode/search';

  Future getData() async {
    http.Response response =
        await http.get(Uri.parse('$url?api_key=$apiKey&text=$area'));
    if (response.statusCode == 200) {
      String data = response.body;
      return jsonDecode(data);
    } else {
      print(response.statusCode);
    }
  }
}

Future<bool> getJsonDataForCoordinates(CoordinatesHelper address) async {
  CoordinatesHelper coordinates = CoordinatesHelper(area: address.area);
  temp_locationCoordinates.clear();
  try {
    var data = await coordinates.getData();
    Directions coordinatesResponse =
        Directions(data['features'][0]['geometry']['coordinates']);

    temp_locationCoordinates.add(coordinatesResponse.directions[1]);
    temp_locationCoordinates.add(coordinatesResponse.directions[0]);
    return true;
  } catch (e) {
    return false;
  }
}
