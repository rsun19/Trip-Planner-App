import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:latlong2/latlong.dart';
import 'package:trip_reminder/main.dart';

class ORSCaller {
  ORSCaller({
    required this.latStart,
    required this.longStart,
    required this.latEnd,
    required this.longEnd,
    required this.tripRoute,
  });

  final String url = 'https://api.openrouteservice.org/v2/directions/';
  final String apiKey =
      'INSERT_API_KEY_HERE';
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
    print(directions.length);
    print(directions.toString());
    for (int i = 0; i < line.directions.length; i++) {
      points.add(LatLng(line.directions[i][1], line.directions[i][0]));
    }
    points.add(LatLng(locationCoordinates[2], locationCoordinates[3]));
  } catch (e) {
    print(e);
  }
}

List<dynamic> directions = [];
//access distance (seconds): directions[0]['distance']
//access duration (meters): directions[0]['duration']
//access steps: directions[0]['steps']

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
  final String apiKey =
      'INSERT API KEY HERE';
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

Future getJsonDataForCoordinates(CoordinatesHelper address) async {
  CoordinatesHelper coordinates = CoordinatesHelper(area: address.area);
  try {
    var data = await coordinates.getData();
    print(data);
    Directions coordinatesResponse =
        Directions(data['features'][0]['geometry']['coordinates']);
    temp_locationCoordinates.add(coordinatesResponse.directions[1]);
    temp_locationCoordinates.add(coordinatesResponse.directions[0]);
  } catch (e) {
    print(e);
  }
}
