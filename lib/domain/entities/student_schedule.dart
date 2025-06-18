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
}