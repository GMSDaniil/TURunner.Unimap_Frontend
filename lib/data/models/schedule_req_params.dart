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
      'study_program': studyProgram,  // e.g., "Computer Science"
      'semester': semester,           // e.g., "2"
    };
    if (filterDates != null) {
      map['filter_dates'] = filterDates.toString();
    }
    return map;
  }
}