import 'package:auth_app/data/models/get_weather_info_req_params.dart';
import 'package:auth_app/data/models/weather_response.dart';
import 'package:auth_app/domain/repository/weather.dart';
import 'package:auth_app/core/usecase/usecase.dart';
import 'package:auth_app/service_locator.dart';
import 'package:dartz/dartz.dart';

class GetWeatherInfoUseCase
    implements
        UseCase<Either<String, WeatherResponse>, GetWeatherInfoReqParams> {
  @override
  Future<Either<String, WeatherResponse>> call({
    GetWeatherInfoReqParams? param,
  }) async {
    if (param == null) return Left("Parameters can't be null");
    try {
      return await sl<WeatherRepository>().getWeatherInfo(param);
      //print('WeatherUseCase result: $result');
    } catch (e) {
      return Left('Unexpected error: ${e.toString()}');
    }
  }
}
