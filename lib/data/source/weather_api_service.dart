import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:auth_app/core/network/dio_client.dart';
import 'package:auth_app/service_locator.dart';
import 'package:auth_app/core/constants/api_urls.dart';
import 'package:auth_app/data/models/get_weather_info_req_params.dart';

class WeatherApiService {
  Future<Either<String, Response>> fetchWeather(
    GetWeatherInfoReqParams params,
  ) async {
    try {
      final url =
          '${ApiUrls.baseURL}weather?lat=${params.lat}&lon=${params.lon}';
      final response = await sl<DioClient>().get(url);
      return Right(response);
    } on DioException catch (e) {
      return Left(e.response?.data['message'] ?? e.message ?? 'Unknown error');
    }
  }
}
