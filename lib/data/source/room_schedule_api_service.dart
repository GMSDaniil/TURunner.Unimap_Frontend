import 'package:auth_app/core/network/dio_client.dart';
import 'package:auth_app/data/source/error_message_extractor.dart';
import 'package:auth_app/core/constants/api_urls.dart';
import 'package:auth_app/service_locator.dart';
import 'package:dio/dio.dart';
import 'package:dartz/dartz.dart';

class RoomScheduleApiService {
  final _errorMessageExtractor = ErrorMessageExtractor();
  final _dioClient = sl<DioClient>();

  Future<Either<String, Response>> getRoomSchedule(String roomId, String date) async {
    try {
      final encodedRoomId = Uri.encodeComponent(roomId);
      print('Fetching schedule for room: $encodedRoomId, date: $date'); // Debug log

      final response = await _dioClient.dio.get(
        '${ApiUrls.getRoomSchedule}/$encodedRoomId',
        queryParameters: {'date': date},
        options: Options(
          headers: {'Content-Type': 'application/json'},
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      print('Response status: ${response.statusCode}'); // Debug log
      print('Response data: ${response.data}'); // Debug log

      // Return empty response for 404 instead of error
      if (response.statusCode == 404) {
        return Right(Response(
          requestOptions: response.requestOptions,
          statusCode: 200,
          data: [], // Empty list as response data
        ));
      }

      if (response.statusCode != 200) {
        return Left('Failed to fetch room schedule: ${response.statusCode}');
      }

      return Right(response);
    } on DioException catch (e) {
      print('DioException: ${e.message}'); // Debug log
      // Return empty response for network errors
      return Right(Response(
        requestOptions: RequestOptions(path: ''),
        statusCode: 200,
        data: [],
      ));
    } catch (e) {
      print('Unexpected error: $e'); // Debug log
      return Right(Response(
        requestOptions: RequestOptions(path: ''),
        statusCode: 200,
        data: [],
      ));
    }
  }
}
