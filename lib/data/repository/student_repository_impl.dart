import 'dart:convert';
import 'package:auth_app/data/models/schedule_req_params.dart';
import 'package:auth_app/data/source/student_api_service.dart';
import 'package:auth_app/data/models/student_schedule_response.dart';
import 'package:auth_app/domain/repository/student.dart';
import 'package:auth_app/service_locator.dart';
import 'package:dartz/dartz.dart';

class StudentRepositoryImpl implements StudentRepository {
  
  @override
  Future<Either<String, StudentScheduleResponse>> getStudentSchedule(
    GetStudentScheduleReqParams params,
  ) async {
    // Use service locator instead of constructor injection
    final result = await sl<StudentApiService>().getStudentSchedule(params);

    return result.fold(
      (errorMessage) => Left(errorMessage),
      (response) {
        try {
          print('✅ API Response received');
          print('📊 Response type: ${response.data.runtimeType}');
          
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