import 'package:auth_app/core/usecase/usecase.dart';
import 'package:auth_app/data/models/signup_req_params.dart';
import 'package:auth_app/domain/repository/auth.dart';
import 'package:auth_app/service_locator.dart';
import 'package:dartz/dartz.dart';

class SignupUseCase implements UseCase<Either, SignupReqParams> {

  @override
  Future<Either> call({SignupReqParams ? param}) async {
    return await sl<AuthRepository>().signup(param!);
  }
  
}