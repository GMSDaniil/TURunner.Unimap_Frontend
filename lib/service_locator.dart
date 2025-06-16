import 'package:auth_app/core/network/dio_client.dart';
import 'package:auth_app/data/repository/auth.dart';
import 'package:auth_app/data/repository/pointers.dart';
import 'package:auth_app/data/source/auth_api_service.dart';
import 'package:auth_app/data/source/auth_local_service.dart';
import 'package:auth_app/data/source/pointer_api_service.dart';
import 'package:auth_app/data/source/student_api_service.dart';
import 'package:auth_app/data/source/weather_api_service.dart';
import 'package:auth_app/domain/repository/auth.dart';
import 'package:auth_app/domain/repository/pointers.dart';
import 'package:auth_app/domain/usecases/find_bus_route.dart';
import 'package:auth_app/domain/usecases/find_scooter_route.dart';
import 'package:auth_app/domain/usecases/get_pointers_usecase.dart';
import 'package:auth_app/domain/usecases/get_user.dart';
import 'package:auth_app/domain/usecases/get_weather_info.dart';
import 'package:auth_app/domain/usecases/is_logged_in.dart';
import 'package:auth_app/domain/usecases/logout.dart';
import 'package:auth_app/domain/usecases/signin.dart';
import 'package:auth_app/domain/usecases/signup.dart';
import 'package:auth_app/data/source/find_route_api_service.dart';
import 'package:auth_app/data/repository/route_repository_impl.dart';
import 'package:auth_app/domain/usecases/find_walking_route.dart';
import 'package:auth_app/domain/repository/route_repository.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import 'package:auth_app/domain/repository/mensa.dart';
import 'package:auth_app/data/repository/mensa.dart';
import 'package:auth_app/data/source/mensa_api_service.dart';
import 'package:auth_app/domain/usecases/get_mensa_menu.dart';

import 'package:auth_app/data/source/building_data_source.dart';
import 'package:auth_app/data/repository/building_repository_impl.dart';
import 'package:auth_app/domain/usecases/find_building_at_point.dart';

import 'package:auth_app/domain/repository/weather.dart';
import 'package:auth_app/data/repository/weather.dart';
import 'package:auth_app/domain/usecases/get_weather_info.dart';

import 'package:auth_app/data/repository/student_repository_impl.dart';
import 'package:auth_app/domain/repository/student.dart';
import 'package:auth_app/domain/usecases/get_student_schedule.dart';

final sl = GetIt.instance;

void setupServiceLocator() {
  sl.registerSingleton<DioClient>(DioClient());

  // Services
  sl.registerSingleton<AuthApiService>(AuthApiServiceImpl());

  sl.registerSingleton<AuthLocalService>(AuthLocalServiceImpl());

  sl.registerSingleton<FindRouteApiService>(FindRouteApiService());
  sl.registerSingleton<MensaApiService>(MensaApiService());
  sl.registerSingleton<PointerApiService>(PointerApiService());

  sl.registerSingleton<WeatherApiService>(WeatherApiService());
  sl.registerSingleton<StudentApiService>(StudentApiService());

  // Repositories
  sl.registerSingleton<AuthRepository>(AuthRepositoryImpl());

  sl.registerSingleton<RouteRepository>(RouteRepositoryImpl());

  sl.registerSingleton<MensaRepository>(MensaRepositoryImpl());

  sl.registerSingleton<PointersRepository>(PointersRepositoryImpl());

  sl.registerLazySingleton<BuildingDataSource>(() => BuildingDataSource());
  sl.registerLazySingleton<BuildingRepositoryImpl>(
    () => BuildingRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<FindBuildingAtPoint>(
    () => FindBuildingAtPoint(),
  );

  sl.registerSingleton<WeatherRepository>(WeatherRepositoryImpl());

  sl.registerSingleton<StudentRepository>(
    StudentRepositoryImpl(sl<StudentApiService>()),
  );

  // Usecases
  sl.registerSingleton<SignupUseCase>(SignupUseCase());

  sl.registerSingleton<IsLoggedInUseCase>(IsLoggedInUseCase());

  sl.registerSingleton<GetUserUseCase>(GetUserUseCase());

  sl.registerSingleton<LogoutUseCase>(LogoutUseCase());

  sl.registerSingleton<SigninUseCase>(SigninUseCase());

  sl.registerSingleton<FindWalkingRouteUseCase>(FindWalkingRouteUseCase());
  sl.registerSingleton<GetMensaMenuUseCase>(GetMensaMenuUseCase());

  sl.registerSingleton<GetPointersUseCase>(GetPointersUseCase());

  sl.registerSingleton<FindBusRouteUseCase>(FindBusRouteUseCase());

  sl.registerSingleton<FindScooterRouteUseCase>(FindScooterRouteUseCase());

  sl.registerSingleton<GetWeatherInfoUseCase>(GetWeatherInfoUseCase());

  sl.registerSingleton<GetStudentScheduleUseCase>(GetStudentScheduleUseCase());
}
