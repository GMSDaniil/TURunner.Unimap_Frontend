import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:auth_app/data/models/get_weather_info_req_params.dart';
import 'package:auth_app/data/models/weather_response.dart';
import '../../domain/repository/weather.dart';
import '../source/weather_api_service.dart';
import '../../service_locator.dart';
import 'package:dartz/dartz.dart';

class WeatherRepositoryImpl implements WeatherRepository {
  @override
  Future<Either<String, WeatherResponse>> getWeatherInfo(
    GetWeatherInfoReqParams params,
  ) async {
    final result = await sl<WeatherApiService>().fetchWeather(params);

    return result.fold(
      (errorMessage) {
        //print('WeatherApiService error: $errorMessage');
        return Left(errorMessage);
      },
      (response) {
        //print('WeatherApiService response: ${response.data}');
        try {
          final data = response.data is String
              ? jsonDecode(response.data)
              : response.data;
          final menu = WeatherResponse.fromJson(data);
          return Right(menu);
        } catch (e) {
          //print('Error parsing weather data: $e');
          return Left('Failed to parse waether data');
        }
      },
    );
  }
}
