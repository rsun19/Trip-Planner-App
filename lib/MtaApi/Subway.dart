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
  final List<dynamic> routeId;
  final List<dynamic> stopId;
  const Station({required this.routeId, required this.stopId});
}
