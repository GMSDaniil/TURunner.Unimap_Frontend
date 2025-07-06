class GetStudentScheduleReqParams {
  final String studyProgram;
  final String semester;
  final bool? filterDates;

  GetStudentScheduleReqParams({
    required this.studyProgram,
    required this.semester,
    this.filterDates,
  });

  Map<String, dynamic> toMap() {
    final map = {
      'stupo': studyProgram,
      'semester': semester,
    };
    
    if (filterDates != null) {
      map['filter_dates'] = filterDates.toString();
    }
    
    return map;
  }
}