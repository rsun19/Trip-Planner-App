import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:trip_reminder/MtaApi/Subway.dart';
import 'package:trip_reminder/auth/secrets.dart';
import 'package:gtfs_realtime_bindings/gtfs_realtime_bindings.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class MtaApiCaller {
  final String API_KEY = MTAApiKey;
  final lineApi = <String, String>{
    'ACE':
        'https://api-endpoint.mta.info/Dataservice/mtagtfsfeeds/nyct%2Fgtfs-ace',
    'BDFM':
        'https://api-endpoint.mta.info/Dataservice/mtagtfsfeeds/nyct%2Fgtfs-bdfm',
    'G': 'https://api-endpoint.mta.info/Dataservice/mtagtfsfeeds/nyct%2Fgtfs-g',
    'JZ':
        'https://api-endpoint.mta.info/Dataservice/mtagtfsfeeds/nyct%2Fgtfs-jz',
    'NQRW':
        'https://api-endpoint.mta.info/Dataservice/mtagtfsfeeds/nyct%2Fgtfs-nqrw',
    'L': 'https://api-endpoint.mta.info/Dataservice/mtagtfsfeeds/nyct%2Fgtfs-l',
    '1234567':
        'https://api-endpoint.mta.info/Dataservice/mtagtfsfeeds/nyct%2Fgtfs',
    'SIR':
        'https://api-endpoint.mta.info/Dataservice/mtagtfsfeeds/nyct%2Fgtfs-si'
  };
  List<String> lineCaller;
  List<dynamic> lineReturner = [];
  String apiStation;
  MtaApiCaller({required this.lineCaller, required this.apiStation});

  final lineCounter = <String, int>{
    'ACE': 0,
    'BDFM': 0,
    'G': 0,
    'JZ': 0,
    'NQRW': 0,
    'L': 0,
    '1234567': 0,
    'SIR': 0
  };

  Future<List<Subway>> ApiIterator() async {
    print(lineCaller);
    List<Subway> masterList = [];
    for (String line in lineCaller) {
      for (String possibleLine in lineCounter.keys) {
        if (possibleLine.contains(line)) {
          lineCounter.update(possibleLine, (value) => value + 1);
          if (lineCounter[possibleLine]! <= 1) {
            List<Subway> topFourArrivals = await ApiCaller(possibleLine);
            masterList.addAll(topFourArrivals);
          }
        }
      }
    }
    return masterList;
  }

  Future<List<Subway>> ApiCaller(String line) async {
    final url = Uri.parse(lineApi[line]!);
    final response = await http.get(url, headers: {"x-api-key": API_KEY});
    if (response.statusCode == 200) {
      final message = FeedMessage.fromBuffer(response.bodyBytes);
      var messageData = message.toProto3Json();
      //debugPrint(messageData.toString(), wrapWidth: 1024);
      print(messageData);
      // var messageData1 = jsonDecode(messageData);
      return await GTFSParser(messageData);
    } else {
      throw HttpException("Failed to get a proper response.");
    }
  }

  Future<List<Subway>> GTFSParser(var message) async {
    int baselineTime = int.parse(message['header']['timestamp'].toString());
    List<dynamic> entities = message['entity'];
    List<Subway> lineInformation = [];
    for (int i = 0; i < entities.length; i += 2) {
      String tripId = entities[i]['tripUpdate']['trip']['tripId'];
      String routeId = entities[i]['tripUpdate']['trip']['routeId'].toString();
      String stopSequencePosition =
          entities[i + 1]['vehicle']['currentStopSequence'].toString();
      String stopId = entities[i + 1]['vehicle']['stopId'].toString();
      List<String> prelimInfo = [tripId, routeId, stopSequencePosition, stopId];
      if (entities[i]['tripUpdate']['stopTimeUpdate'] != null) {
        for (int stop = 0;
            stop < entities[i]['tripUpdate']['stopTimeUpdate'].length;
            stop++) {
          var baseline = entities[i]['tripUpdate']['stopTimeUpdate'];
          int arrivalTime =
              (int.parse(baseline[stop]['arrival']['time'].toString()) -
                  baselineTime);
          String stopId = baseline[stop]['stopId'];
          if (stopId.toString().contains(this.apiStation.toString()) &&
              arrivalTime > 0) {
            print('true');
            prelimInfo.add(arrivalTime.toString());
          }
        }
      }
      if (prelimInfo.length == 5) {
        Subway trainInfo = Subway(
            tripId: prelimInfo[0],
            routeId: prelimInfo[1],
            stopSequencePosition: prelimInfo[2],
            stopId: prelimInfo[3],
            arrivalTime: prelimInfo[4]);
        lineInformation.add(trainInfo);
      }
    }
    return await sortResults(lineInformation);
  }

  Future<List<Subway>> sortResults(List<Subway> lineInformation) async {
    lineInformation.sort(
      (a, b) {
        return int.parse(a.arrivalTime.toString()) -
            int.parse(b.arrivalTime.toString());
      },
    );
    if (lineInformation.length < 5) {
      return lineInformation;
    }
    List<Subway> topFourArrivals = lineInformation.sublist(0, 5);
    return topFourArrivals;
  }
}
