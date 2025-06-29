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
      print('🔍 Request params: ${params.toMap()}');
      
      final response = await sl<DioClient>().get(
        ApiUrls.getStudentSchedule,
        queryParameters: params.toMap(),
      );
      
      print('✅ API Response received');
      print('📊 Response type: ${response.data.runtimeType}');
      
      return Right(response);
    } on DioException catch (e) {
      print('❌ DioException: ${e.message}');
      return Left(e.response?.data['message'] ?? e.message ?? 'Network error');
    } catch (e) {
      print('❌ Unknown error: $e');
      return Left('Unknown error occurred');
    }
  }
}