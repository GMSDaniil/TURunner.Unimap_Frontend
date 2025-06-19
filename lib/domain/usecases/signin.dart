import 'package:auth_app/core/usecase/usecase.dart';
import 'package:auth_app/data/models/signin_req_params.dart';
import 'package:auth_app/data/models/signin_response.dart';
import 'package:auth_app/domain/repository/auth.dart';
import 'package:auth_app/service_locator.dart';
import 'package:dartz/dartz.dart';

class SigninUseCase implements UseCase<Either<String, SignInResponse>, SigninReqParams> {
  @override
  Future<Either<String, SignInResponse>> call({SigninReqParams? param}) async {
    if (param == null) {
      return Left("Signin parameters cannot be null");
    }
    try {
      return await sl<AuthRepository>().signin(param);
    } catch (e) {
      print("Error during signin: $e");
      return Left("An unexpected error occurred during signin");
    }
  }
}