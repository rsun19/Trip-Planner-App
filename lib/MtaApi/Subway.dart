class Subway {
  final String tripId;
  final String routeId;
  final String stopSequencePosition;
  final String stopId;
  final String direction;
  final String arrivalTime;
  final String fullStopId;
  final String baselineTime;
  const Subway(
      {required this.tripId,
      required this.routeId,
      required this.stopSequencePosition,
      required this.stopId,
      required this.direction,
      required this.arrivalTime,
      required this.fullStopId,
      required this.baselineTime});
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
  final List<String> stationCoordinates;
  const StationName(
      {required this.routeId,
      required this.stopId,
      required this.stationName,
      required this.stationCoordinates});
}
