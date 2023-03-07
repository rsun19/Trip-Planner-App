class Subway {
  final String tripId;
  final String routeId;
  final String stopSequencePosition;
  final String stopId;
  final String direction;
  final String arrivalTime;
  const Subway(
      {required this.tripId,
      required this.routeId,
      required this.stopSequencePosition,
      required this.stopId,
      required this.direction,
      required this.arrivalTime});
}

class Station {
  final List<List<String>> routeId;
  final List<String> stopId;
  final List<String> stationName;
  const Station(
      {required this.routeId, required this.stopId, required this.stationName});
}

class StationName {
  final List<String> routeId;
  final String stopId;
  final String stationName;
  const StationName(
      {required this.routeId, required this.stopId, required this.stationName});
}
