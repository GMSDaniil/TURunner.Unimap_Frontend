class GetRoomScheduleParams {
  final String roomId;
  final String date;

  GetRoomScheduleParams({
    required this.roomId,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'roomId': roomId,
      'date': date,
    };
  }
}