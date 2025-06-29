import 'package:auth_app/domain/entities/student_schedule.dart';

class StudentScheduleResponse {
  final List<StudentLectureEntity> lectures;

  StudentScheduleResponse({required this.lectures});

  factory StudentScheduleResponse.fromJson(Map<String, dynamic> json) {
    return StudentScheduleResponse(
      lectures: (json['lectures'] as List<dynamic>? ?? [])
          .map((lectureJson) => StudentLectureEntity.fromJson(lectureJson))
          .toList(),
    );
  }
}