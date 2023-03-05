import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:trip_reminder/auth/secrets.dart';
import 'package:gtfs_realtime_bindings/gtfs_realtime_bindings.dart';

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

  Future<void> ApiIterator() async {
    print(lineCaller);
    for (String line in lineCaller) {
      for (String possibleLine in lineCounter.keys) {
        if (possibleLine.contains(line)) {
          lineCounter.update(possibleLine, (value) => value + 1);
          if (lineCounter[possibleLine]! <= 1) {
            await ApiCaller(possibleLine);
            print(possibleLine);
          }
        }
      }
    }
  }

  Future<void> ApiCaller(String line) async {
    final url = Uri.parse(lineApi[line]!);
    final response = await http.get(url, headers: {"x-api-key": API_KEY});
    if (response.statusCode == 200) {
      final message = FeedMessage.fromBuffer(response.bodyBytes);
      var messageData = message.toProto3Json();
      print(messageData);
    } else {
      throw HttpException("Failed to get a proper response.");
    }
  }

  void GTFSParser(var message) {
    List<dynamic> entities = message['entity'];
    for (int i = 0; i < entities.length; i += 2) {}
  }
}
