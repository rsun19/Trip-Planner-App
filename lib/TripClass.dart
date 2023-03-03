abstract class AbstractTrip {
  final String title;
  final String location;
  const AbstractTrip({required this.title, required this.location});
}

class Trip extends AbstractTrip {
  final String title;
  final String location;
  final String start_date;
  final String end_date;
  String visibility;
  final String email;
  Trip(
      {required this.title,
      required this.location,
      required this.start_date,
      required this.end_date,
      required this.visibility,
      required this.email})
      : super(title: title, location: location);
}

class TripEvent extends AbstractTrip {
  const TripEvent(
      {required this.name,
      required this.description,
      required this.dateTime,
      required this.location,
      required this.fullAddress})
      : super(title: name, location: location);

  final String name;
  final String description;
  final String dateTime;
  final String location;
  final String fullAddress;
}
