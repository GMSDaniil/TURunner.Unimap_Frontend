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
  Future<Either<String, StudentScheduleResponse>> getStudentSchedule(GetStudentScheduleReqParams params) async {
    final result = await apiService.fetchStudentSchedule(params);

    return result.fold(
      (errorMessage) => Left(errorMessage),
      (response) {
        try {
          final data = response.data is String
              ? jsonDecode(response.data)
              : response.data;
          final schedule = StudentScheduleResponse.fromJson(data);
          return Right(schedule);
        } catch (e) {
          return Left('Failed to parse student schedule data');
        }
      },
    );
  }
}