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
import 'package:auth_app/data/source/find_route_api_service.dart';
import 'package:auth_app/data/repository/route_repository_impl.dart';
import 'package:auth_app/domain/usecases/find_route.dart';
import 'package:auth_app/domain/repository/route_repository.dart';
import 'package:get_it/get_it.dart';

import 'package:auth_app/domain/repository/mensa.dart';
import 'package:auth_app/data/repository/mensa.dart';
import 'package:auth_app/data/source/mensa_api_service.dart';
import 'package:auth_app/domain/usecases/get_mensa_menu.dart';

final sl = GetIt.instance;

void setupServiceLocator() {
  sl.registerSingleton<DioClient>(DioClient());

  // Services
  sl.registerSingleton<AuthApiService>(AuthApiServiceImpl());

  sl.registerSingleton<AuthLocalService>(AuthLocalServiceImpl());

  sl.registerSingleton<FindRouteApiService>(FindRouteApiService());
  sl.registerSingleton<MensaApiService>(MensaApiService());

  // Repositories
  sl.registerSingleton<AuthRepository>(AuthRepositoryImpl());

  sl.registerSingleton<RouteRepository>(RouteRepositoryImpl());

  sl.registerSingleton<MensaRepository>(
    MensaRepositoryImpl(),
  );

  // Usecases
  sl.registerSingleton<SignupUseCase>(SignupUseCase());

  sl.registerSingleton<IsLoggedInUseCase>(IsLoggedInUseCase());

  sl.registerSingleton<GetUserUseCase>(GetUserUseCase());

  sl.registerSingleton<LogoutUseCase>(LogoutUseCase());

  sl.registerSingleton<SigninUseCase>(SigninUseCase());

  sl.registerSingleton<FindRouteUseCase>(FindRouteUseCase());
  sl.registerSingleton<GetMensaMenuUseCase>(
    GetMensaMenuUseCase(),
  );
}
