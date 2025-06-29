class StudentScheduleEntity {
  final List<StudentLectureEntity> lectures;

  StudentScheduleEntity({required this.lectures});
}

class StudentLectureEntity {
  final String courseName;
  final String instructor;
  final String location;
  final String timeSchedule;

  StudentLectureEntity({
    required this.courseName,
    required this.instructor,
    required this.location,
    required this.timeSchedule,
  });

  factory StudentLectureEntity.fromJson(Map<String, dynamic> json) {
    return StudentLectureEntity(
      courseName: json['course_name'] ?? '',
      instructor: json['instructor'] ?? '',
      location: json['location'] ?? '',
      timeSchedule: json['time_schedule'] ?? '',
    );
  }

  @override
  String toString() {
    return 'StudentLectureEntity(courseName: $courseName, instructor: $instructor, location: $location, timeSchedule: $timeSchedule)';
  }
}