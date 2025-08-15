class RoomScheduleResponse {
  final List<RoomEvent> events;

  RoomScheduleResponse({
    required this.events,
  });

  factory RoomScheduleResponse.fromJson(List<dynamic> json) {
    return RoomScheduleResponse(
      events: json.map((e) => RoomEvent.fromJson(e)).toList(),
    );
  }
}

class RoomEvent {
  final String title;
  final String datetime;
  final String room;
  final String lecturer;

  RoomEvent({
    required this.title,
    required this.datetime,
    required this.room,
    required this.lecturer,
  });

  factory RoomEvent.fromJson(Map<String, dynamic> json) {
    return RoomEvent(
      title: json['title'] as String,
      datetime: json['datetime'] as String,
      room: json['room'] as String,
      lecturer: json['lecturer'] as String,
    );
  }
}