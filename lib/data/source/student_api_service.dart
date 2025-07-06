import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:auth_app/core/network/dio_client.dart';
import 'package:auth_app/service_locator.dart';
import 'package:auth_app/core/constants/api_urls.dart';
import 'package:auth_app/data/models/schedule_req_params.dart';

class StudentApiService {
  Future<Either<String, Response>> getStudentSchedule(
    GetStudentScheduleReqParams params,
  ) async {
    try {
      final url = '${ApiUrls.baseURL}student-schedule';
      final queryParameters = params.toMap();
      
      final response = await sl<DioClient>().get(
        url,
        queryParameters: queryParameters,
      );
      
      return Right(response);
    } on DioException catch (e) {
      String errorMessage = 'Unknown error';
      if (e.response?.data != null) {
        if (e.response?.data is Map) {
          errorMessage = e.response?.data['message'] ?? 
                        e.response?.data['error'] ?? 
                        'Request failed with status ${e.response?.statusCode}';
        } else {
          errorMessage = e.response?.data.toString() ?? 'Request failed';
        }
      } else {
        errorMessage = e.message ?? 'Network error';
      }
      
      return Left(errorMessage);
    }
  }
}