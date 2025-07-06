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

// STUDENT DOMAIN
import 'package:auth_app/data/repository/student_repository_impl.dart';
import 'package:auth_app/domain/repository/student.dart';
import 'package:auth_app/domain/usecases/get_student_schedule.dart';
import 'package:auth_app/domain/usecases/get_study_programs.dart';

// FAVOURITES DOMAIN
import 'package:auth_app/data/source/favourites_api_service.dart';
import 'package:auth_app/data/repository/favourites.dart';
import 'package:auth_app/domain/repository/favourites.dart';
import 'package:auth_app/domain/usecases/get_favourites.dart';
import 'package:auth_app/domain/usecases/add_favourite.dart';
import 'package:auth_app/domain/usecases/delete_favourite.dart';

final sl = GetIt.instance;

void setupServiceLocator() {
  sl.registerSingleton<DioClient>(DioClient());

  // ──────────────────── API SERVICES ────────────────────
  sl.registerSingleton<AuthApiService>(AuthApiServiceImpl());
  sl.registerSingleton<AuthLocalService>(AuthLocalServiceImpl());
  sl.registerSingleton<FindRouteApiService>(FindRouteApiService());
  sl.registerSingleton<MensaApiService>(MensaApiService());
  sl.registerSingleton<PointerApiService>(PointerApiService());
  sl.registerSingleton<WeatherApiService>(WeatherApiService());
  
  // Student API Service
  sl.registerSingleton<StudentApiService>(StudentApiService());
  
  // Favourites API Service
  sl.registerSingleton<FavouritesApiService>(FavouritesApiService());

  // ──────────────────── REPOSITORIES ────────────────────
  sl.registerSingleton<AuthRepository>(AuthRepositoryImpl());
  sl.registerSingleton<RouteRepository>(RouteRepositoryImpl());
  sl.registerSingleton<MensaRepository>(MensaRepositoryImpl());
  sl.registerSingleton<PointersRepository>(PointersRepositoryImpl());
  sl.registerSingleton<WeatherRepository>(WeatherRepositoryImpl());
  
  // Student Repository (unified - handles both schedule + study programs)
  sl.registerSingleton<StudentRepository>(StudentRepositoryImpl());
  
  // Favourites Repository (separate domain)
  sl.registerSingleton<FavouritesRepository>(FavouritesRepositoryImpl());

  // Building repository (lazy singleton pattern)
  sl.registerLazySingleton<BuildingDataSource>(() => BuildingDataSource());
  sl.registerLazySingleton<BuildingRepositoryImpl>(
    () => BuildingRepositoryImpl(sl()),
  );

  // ──────────────────── USE CASES ────────────────────
  
  // Auth Use Cases
  sl.registerSingleton<SignupUseCase>(SignupUseCase());
  sl.registerSingleton<IsLoggedInUseCase>(IsLoggedInUseCase());
  sl.registerSingleton<GetUserUseCase>(GetUserUseCase());
  sl.registerSingleton<LogoutUseCase>(LogoutUseCase());
  sl.registerSingleton<SigninUseCase>(SigninUseCase());

  // Route Use Cases
  sl.registerSingleton<FindWalkingRouteUseCase>(FindWalkingRouteUseCase());
  sl.registerSingleton<FindBusRouteUseCase>(FindBusRouteUseCase());
  sl.registerSingleton<FindScooterRouteUseCase>(FindScooterRouteUseCase());

  // Map & Pointers Use Cases
  sl.registerSingleton<GetPointersUseCase>(GetPointersUseCase());
  sl.registerLazySingleton<FindBuildingAtPoint>(() => FindBuildingAtPoint());

  // Mensa Use Cases
  sl.registerSingleton<GetMensaMenuUseCase>(GetMensaMenuUseCase());

  // Weather Use Cases
  sl.registerSingleton<GetWeatherInfoUseCase>(GetWeatherInfoUseCase());

  // Student Use Cases
  sl.registerSingleton<GetStudentScheduleUseCase>(GetStudentScheduleUseCase());
  sl.registerSingleton<GetStudyProgramsUseCase>(GetStudyProgramsUseCase());

  // Favourites Use Cases
  sl.registerSingleton<GetFavouritesUseCase>(GetFavouritesUseCase());
  sl.registerSingleton<AddFavouriteUseCase>(AddFavouriteUseCase());
  sl.registerSingleton<DeleteFavouriteUseCase>(DeleteFavouriteUseCase());
}
