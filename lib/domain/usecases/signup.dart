import 'package:auth_app/core/usecase/usecase.dart';
import 'package:auth_app/data/models/signin_response.dart';
import 'package:auth_app/data/models/signup_req_params.dart';
import 'package:auth_app/domain/repository/auth.dart';
import 'package:auth_app/service_locator.dart';
import 'package:dartz/dartz.dart';

class SignupUseCase implements UseCase<Either, SignupReqParams> {

  @override
  Future<Either<String, SignInResponse>> call({SignupReqParams ? param}) async {
    if (param == null) {
      return Left("Signup parameters cannot be null");
    }
    try {
      return await sl<AuthRepository>().signup(param);
    } catch (e) {
      print("Error during signup: $e");
      // return Left("An error occurred during signup: ${e.toString()}");
      return Left("An unexpected error occurred during signup");
    }
  }
  
}