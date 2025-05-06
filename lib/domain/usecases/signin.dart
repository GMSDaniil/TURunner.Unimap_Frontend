import 'package:auth_app/core/usecase/usecase.dart';
import 'package:auth_app/data/models/signin_req_params.dart';
import 'package:auth_app/domain/repository/auth.dart';
import 'package:auth_app/service_locator.dart';
import 'package:dartz/dartz.dart';

class SigninUseCase implements UseCase<Either, SigninReqParams> {

  @override
  Future<Either> call({SigninReqParams ? param}) async {
    return await sl<AuthRepository>().signin(param!);
  }
  
}