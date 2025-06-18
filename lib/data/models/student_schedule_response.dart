import 'package:auth_app/domain/entities/student_schedule.dart';

class StudentScheduleResponse {
  final List<StudentLectureEntity> lectures;

  StudentScheduleResponse({
    required this.lectures,
  });

  factory StudentScheduleResponse.fromJson(List<dynamic> json) {
    return StudentScheduleResponse(
      lectures: json.map((e) => StudentLectureEntity(
        courseName: e['course_name'] ?? '',
        instructor: e['instructor'] ?? '',
        location: e['location'] ?? '',
        timeSchedule: e['time_schedule'] ?? '',
      )).toList(),
    );
  }
}