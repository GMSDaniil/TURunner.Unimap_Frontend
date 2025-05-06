import 'package:auth_app/core/usecase/usecase.dart';
import 'package:auth_app/domain/repository/auth.dart';
import 'package:auth_app/service_locator.dart';
import 'package:dartz/dartz.dart';

class GetUserUseCase implements UseCase<Either, dynamic> {

  @override
  Future<Either> call({dynamic param}) async {
    return await sl<AuthRepository>().getUser();
  }
  
}