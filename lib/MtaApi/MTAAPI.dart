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
  List<String> apiStation;
  MtaApiCaller(
      {required this.lineCaller,
      required this.apiStation,
      required this.lineCounter});

  Map<String, int> lineCounter;

  Future<List<List<Subway>>> ApiIterator() async {
    print(lineCaller);
    for (String each in lineCounter.keys) {
      lineCounter[each] = 0;
    }
    List<List<Subway>> masterList = [];
    for (String line in lineCaller) {
      for (String possibleLine in lineCounter.keys) {
        if (possibleLine.contains(line)) {
          lineCounter.update(possibleLine, (value) => value + 1);
          if (lineCounter[possibleLine]! <= 1) {
            List<Subway> topFourArrivals = await ApiCaller(possibleLine);
            masterList.addAll([topFourArrivals]);
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
      try {
        String tripId = entities[i]['tripUpdate']['trip']['tripId'];
        String routeId =
            entities[i]['tripUpdate']['trip']['routeId'].toString();

        String stopSequencePosition = entities[i + 1]['vehicle']['trip']
                ['currentStopSequence']
            .toString();
        String stopId = entities[i + 1]['vehicle']['stopId'].toString();
        List<String> prelimInfo = [
          tripId,
          routeId,
          stopSequencePosition,
          stopId
        ];
        if (entities[i]['tripUpdate']['stopTimeUpdate'] != null) {
          for (int stop = 0;
              stop < entities[i]['tripUpdate']['stopTimeUpdate'].length;
              stop++) {
            var baseline = entities[i]['tripUpdate']['stopTimeUpdate'];
            int arrivalTime =
                (int.parse(baseline[stop]['arrival']['time'].toString()) -
                    baselineTime);
            String stopId = baseline[stop]['stopId'];
            apiStation.forEach((station) {
              if (stopId.toString().contains(station.toString()) &&
                  arrivalTime > 0) {
                prelimInfo.add(arrivalTime.toString());
              }
            });
          }
        }
        if (prelimInfo.length == 5) {
          String direction;
          String arrivalTimeMinutes =
              (int.parse(prelimInfo[4]) / 60).round().toString();
          if (prelimInfo[3].substring(3, 4) == 'N') {
            direction = "Uptown";
          } else {
            direction = "Downtown";
          }
          Subway trainInfo = Subway(
              tripId: prelimInfo[0],
              routeId: prelimInfo[1],
              stopSequencePosition: prelimInfo[2],
              stopId: prelimInfo[3],
              direction: direction,
              arrivalTime: arrivalTimeMinutes);
          lineInformation.add(trainInfo);
        }
      } catch (e) {}
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
    if (lineInformation.length < 10) {
      return lineInformation;
    }
    List<Subway> topFourArrivals = lineInformation.sublist(0, 10);
    return topFourArrivals;
  }
}
