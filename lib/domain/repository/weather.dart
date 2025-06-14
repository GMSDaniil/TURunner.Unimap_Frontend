import 'package:auth_app/data/models/get_weather_info_req_params.dart';
import 'package:auth_app/data/models/weather_response.dart';
import 'package:dartz/dartz.dart';

abstract class WeatherRepository {
  Future<Either<String, WeatherResponse>> getWeatherInfo(
    GetWeatherInfoReqParams params,
  );
}
