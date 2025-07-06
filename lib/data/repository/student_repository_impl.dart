import 'dart:convert';
import 'package:auth_app/data/models/schedule_req_params.dart';
import 'package:auth_app/data/source/student_api_service.dart';
import 'package:auth_app/data/models/student_schedule_response.dart';
import 'package:auth_app/domain/entities/study_program.dart';
import 'package:auth_app/domain/repository/student.dart';
import 'package:auth_app/service_locator.dart';
import 'package:dartz/dartz.dart';

class StudentRepositoryImpl implements StudentRepository {
  
  @override
  Future<Either<String, StudentScheduleResponse>> getStudentSchedule(
    GetStudentScheduleReqParams params,
  ) async {
    final result = await sl<StudentApiService>().getStudentSchedule(params);

    return result.fold(
      (errorMessage) => Left(errorMessage),
      (response) {
        try {
          final data = response.data is String
              ? jsonDecode(response.data)
              : response.data;
          
          final scheduleResponse = StudentScheduleResponse.fromJson(data);
          return Right(scheduleResponse);
        } catch (e) {
          return Left('Failed to parse student schedule data: $e');
        }
      },
    );
  }

  @override
  Future<Either<String, List<StudyProgramEntity>>> getStudyPrograms() async {
    final result = await sl<StudentApiService>().getStudyPrograms();

    return result.fold(
      (errorMessage) => Left(errorMessage),
      (response) {
        try {
          final data = response.data is String
              ? jsonDecode(response.data)
              : response.data;

          if (data is! List) {
            return Left('Invalid study programs data format: expected list');
          }

          final programs = data
              .map((json) => StudyProgramEntity.fromJson(json as Map<String, dynamic>))
              .toList();
          
          return Right(programs);
        } catch (e) {
          return Left('Failed to parse study programs: $e');
        }
      },
    );
  }
}