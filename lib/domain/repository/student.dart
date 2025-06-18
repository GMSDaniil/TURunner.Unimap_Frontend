import 'package:auth_app/data/models/schedule_req_params.dart';
import 'package:auth_app/data/models/student_schedule_response.dart';
import 'package:dartz/dartz.dart';

abstract class StudentRepository {
  Future<Either<String, StudentScheduleResponse>> getStudentSchedule(
    GetStudentScheduleReqParams params,
  );
}