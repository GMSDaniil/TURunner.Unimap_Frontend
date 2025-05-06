import 'package:auth_app/core/usecase/usecase.dart';
import 'package:auth_app/domain/repository/auth.dart';
import 'package:auth_app/service_locator.dart';

class IsLoggedInUseCase implements UseCase<bool, dynamic> {

  @override
  Future<bool> call({dynamic param}) async {
    return await sl<AuthRepository>().isLoggedIn();
  }
  
}