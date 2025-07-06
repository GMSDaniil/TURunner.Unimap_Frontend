import 'package:auth_app/domain/entities/study_program.dart';

class StudyProgramResponse {
  final List<StudyProgramEntity> studyPrograms;

  StudyProgramResponse({required this.studyPrograms});

  factory StudyProgramResponse.fromJson(Map<String, dynamic> json) {
    return StudyProgramResponse(
      studyPrograms: (json['study_programs'] as List)
          .map((e) => StudyProgramEntity(
                name: e['name'],
                stupoNumber: e['stupo_number'],
              ))
          .toList(),
    );
  }
}