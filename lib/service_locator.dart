import 'package:auth_app/core/network/dio_client.dart';
import 'package:auth_app/data/repository/auth.dart';
import 'package:auth_app/data/source/auth_api_service.dart';
import 'package:auth_app/data/source/auth_local_service.dart';
import 'package:auth_app/domain/repository/auth.dart';
import 'package:auth_app/domain/usecases/get_user.dart';
import 'package:auth_app/domain/usecases/is_logged_in.dart';
import 'package:auth_app/domain/usecases/logout.dart';
import 'package:auth_app/domain/usecases/signin.dart';
import 'package:auth_app/domain/usecases/signup.dart';
import 'package:dio/dio.dart';
import 'package:auth_app/data/source/find_route_api_service.dart';
import 'package:auth_app/data/repository/route_repository_impl.dart';
import 'package:auth_app/domain/usecases/find_route.dart';
import 'package:auth_app/domain/repository/route_repository.dart';
import 'package:get_it/get_it.dart';

/* import 'package:auth_app/domain/repository/mensa.dart';
import 'package:auth_app/data/repository/mensa.dart';
import 'package:auth_app/data/source/mensa_api_service.dart';
import 'package:auth_app/domain/usecases/get_mensa_menu.dart';*/

final sl = GetIt.instance;

void setupServiceLocator() {
  sl.registerSingleton<DioClient>(DioClient());

  // Services
  sl.registerSingleton<AuthApiService>(AuthApiServiceImpl());

  sl.registerSingleton<AuthLocalService>(AuthLocalServiceImpl());

  // Repositories
  sl.registerSingleton<AuthRepository>(AuthRepositoryImpl());

  // Usecases
  sl.registerSingleton<SignupUseCase>(SignupUseCase());

  sl.registerSingleton<IsLoggedInUseCase>(IsLoggedInUseCase());

  sl.registerSingleton<GetUserUseCase>(GetUserUseCase());

  sl.registerSingleton<LogoutUseCase>(LogoutUseCase());

  sl.registerSingleton<SigninUseCase>(SigninUseCase());

  // Register DioClient if not already – for simplicity, here we create a Dio instance
  final dio = Dio();

  // Register FindRouteApiService
  sl.registerSingleton<FindRouteApiService>(FindRouteApiService(dio));

  // Register RouteRepository implementation
  sl.registerSingleton<RouteRepository>(
    RouteRepositoryImpl(apiService: sl<FindRouteApiService>()),
  );

  // Register FindRouteUseCase
  sl.registerSingleton<FindRouteUseCase>(
    FindRouteUseCase(sl<RouteRepository>()),
  );

  /*Mensa API service to handle HTTP calls
  sl.registerSingleton<MensaApiService>(MensaApiService(sl<DioClient>().dio));

  // MensaRepo implementation
  sl.registerSingleton<MensaRepository>(
    MensaRepositoryImpl(sl<MensaApiService>()),
  );

  // Use case to fetch meals from a specific mensa
  sl.registerSingleton<GetMensaMenuUseCase>(
    GetMensaMenuUseCase(sl<MensaRepository>()),
  );*/
}
