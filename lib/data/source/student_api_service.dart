import 'package:auth_app/data/source/error_message_extractor.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:auth_app/core/network/dio_client.dart';
import 'package:auth_app/service_locator.dart';
import 'package:auth_app/core/constants/api_urls.dart';
import 'package:auth_app/data/models/schedule_req_params.dart';

class StudentApiService {
  final ErrorMessageExtractor _errorMessageExtractor = ErrorMessageExtractor();
  
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
      return Left(_errorMessageExtractor.extractErrorMessage(e));
    }
  }

  Future<Either<String, Response>> getStudyPrograms() async {
    try {
      final url = ApiUrls.getStudyPrograms;
      final response = await sl<DioClient>().get(url);
      return Right(response);
      
    } on DioException catch (e) {
      return Left(_errorMessageExtractor.extractErrorMessage(e));
    }
  }
}