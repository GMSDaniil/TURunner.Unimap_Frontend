import 'package:auth_app/data/models/schedule_req_params.dart';
import 'package:auth_app/data/models/student_schedule_response.dart';
import 'package:auth_app/domain/repository/student.dart';
import 'package:auth_app/core/usecase/usecase.dart';
import 'package:auth_app/service_locator.dart';
import 'package:dartz/dartz.dart';

class GetStudentScheduleUseCase
    implements UseCase<Either<String, StudentScheduleResponse>, GetStudentScheduleReqParams> {
  @override
  Future<Either<String, StudentScheduleResponse>> call({
    GetStudentScheduleReqParams? param,
  }) async {
    if (param == null) return Left("Parameters can't be null");
    try {
      return await sl<StudentRepository>().getStudentSchedule(param);
    } catch (e) {
      return Left('Unexpected error: ${e.toString()}');
    }
  }
}