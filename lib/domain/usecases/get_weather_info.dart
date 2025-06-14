import 'package:auth_app/data/models/weather_req_params.dart';
import 'package:auth_app/data/models/weather_info_response.dart';
import 'package:auth_app/domain/repository/weather.dart';
import 'package:auth_app/core/usecase/usecase.dart';
import 'package:auth_app/service_locator.dart';
import 'package:dartz/dartz.dart';

class GetWeatherInfoUseCase
    implements
        UseCase<Either<String, WeatherInfoResponse>, GetWeatherReqParams> {
  @override
  Future<Either<String, WeatherInfoResponse>> call({
    GetWeatherReqParams? param,
  }) async {
    if (param == null) return Left("Parameters can't be null");
    try {
      return await sl<WeatherRepository>().getWeatherInfo(param);
    } catch (e) {
      return Left('Unexpected error: ${e.toString()}');
    }
  }
}
