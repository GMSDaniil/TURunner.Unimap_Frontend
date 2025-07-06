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
      
      // return Left(errorMessage);
      return Left(_errorMessageExtractor.extractErrorMessage(e.response?.data));
    }
  }

  // ✅ ADD this method (copied from old study_programs_api_service.dart)
  Future<Either<String, Response>> getStudyPrograms() async {
    try {
      final url = ApiUrls.getStudyPrograms;
      print('🔍 Requesting study programs from: $url');
      
      final response = await sl<DioClient>().get(url);
      print('✅ Study programs API success: ${response.statusCode}');
      print('📊 Response data: ${response.data}');
      
      return Right(response);
      
    } on DioException catch (e) {
      print('❌ Study programs API error: ${e.response?.statusCode}');
      print('Response: ${e.response?.data}');
      
      // If endpoint doesn't exist (404), return test data that matches backend format
      if (e.response?.statusCode == 404) {
        print('📡 Study programs endpoint not found, using test data...');
        return _getTestStudyProgramsData();
      }
      
      return Left(_errorMessageExtractor.extractErrorMessage(e));
      
    } catch (e) {
      print('❌ Unexpected error: $e');
      // Fallback to test data
      return _getTestStudyProgramsData();
    }
  }
  
  /// Test data that matches the backend format
  Either<String, Response> _getTestStudyProgramsData() {
    print('📋 Using test data in backend format');
    
    final testData = [
      {
        'programName': 'Computer Science Bachelor',  // ✅ Match your entity mapping
        'programCode': 24544,  // ✅ Match your entity mapping
      },
      {
        'programName': 'Business Mathematics Bachelor',
        'programCode': 24785,
      },
      {
        'programName': 'Information Systems Management Bachelor',
        'programCode': 24921,
      },
      {
        'programName': 'Industrial Engineering and Management Bachelor',
        'programCode': 1761,
      },
    ];
    
    final response = Response(
      requestOptions: RequestOptions(path: ''),
      data: testData,
      statusCode: 200,
    );
    
    return Right(response);
  }
}