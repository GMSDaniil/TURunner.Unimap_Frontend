import 'package:auth_app/data/models/signin_req_params.dart';
import 'package:auth_app/data/models/signin_response.dart';
import 'package:auth_app/data/models/signup_req_params.dart';
import 'package:dartz/dartz.dart';

abstract class AuthRepository {
  
  Future<Either<String, SignInResponse>> signup(SignupReqParams signupReq);
  Future<Either<String, SignInResponse>> signin(SigninReqParams signinReq);
  Future<bool> isLoggedIn();
  Future<Either> getUser();
  Future<Either> logout();
}