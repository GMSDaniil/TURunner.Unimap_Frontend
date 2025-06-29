import 'dart:convert';
import 'package:auth_app/data/models/schedule_req_params.dart';
import 'package:auth_app/data/source/student_api_service.dart';
import 'package:auth_app/data/models/student_schedule_response.dart';
import 'package:auth_app/domain/repository/student.dart';
import 'package:dartz/dartz.dart';

class StudentRepositoryImpl implements StudentRepository {
  final StudentApiService apiService;

  StudentRepositoryImpl(this.apiService);

  @override
  Future<Either<String, StudentScheduleResponse>> getStudentSchedule(
    GetStudentScheduleReqParams params,
  ) async {
    final result = await apiService.fetchStudentSchedule(params);

    return result.fold(
      (errorMessage) => Left(errorMessage),
      (response) {
        try {
          final scheduleResponse = StudentScheduleResponse.fromJson(response.data);
          return Right(scheduleResponse);
        } catch (e) {
          print('❌ Parsing error: $e');
          print('📄 Response data: ${response.data}');
          return Left('Failed to parse student schedule data: $e');
        }
      },
    );
  }
}