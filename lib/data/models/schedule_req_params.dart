class GetStudentScheduleReqParams {
  final String stupo;
  final String semester;
  final bool? filterDates;

  GetStudentScheduleReqParams({
    required this.stupo,
    required this.semester,
    this.filterDates,
  });

  Map<String, dynamic> toMap() {
    final map = {
      'stupo': stupo,
      'semester': semester,
    };
    if (filterDates != null) {
      map['filter_dates'] = filterDates.toString();
    }
    return map;
  }
}