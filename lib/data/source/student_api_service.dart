import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:auth_app/core/network/dio_client.dart';
import 'package:auth_app/service_locator.dart';
import 'package:auth_app/core/constants/api_urls.dart';
import 'package:auth_app/data/models/schedule_req_params.dart';

class StudentApiService {
  Future<Either<String, Response>> fetchStudentSchedule(
    GetStudentScheduleReqParams params,
  ) async {
    try {
      final url =
          '${ApiUrls.getStudentSchedule}?stupo=${params.stupo}&semester=${params.semester}'
          '${params.filterDates != null ? '&filter_dates=${params.filterDates}' : ''}';
      final response = await sl<DioClient>().get(url);
      return Right(response);
    } on DioException catch (e) {
      return Left(e.response?.data['message'] ?? e.message ?? 'Unknown error');
    }
  }
}