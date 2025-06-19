import 'package:auth_app/data/models/signin_req_params.dart';
import 'package:auth_app/data/models/signin_response.dart';
import 'package:auth_app/data/models/user.dart';
import 'package:auth_app/data/source/auth_api_service.dart';
import 'package:auth_app/data/source/auth_local_service.dart';
import 'package:auth_app/domain/repository/auth.dart';
import 'package:auth_app/service_locator.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/signup_req_params.dart';

class AuthRepositoryImpl extends AuthRepository {

  
 @override
  Future<Either<String, SignInResponse>> signup(SignupReqParams signUpReq) async {
    Either result = await sl < AuthApiService > ().signup(signUpReq);
    return result.fold(
      (error) {
        return Left(error);
      },
      (data) async {
        Response response = data;
        SignInResponse signinResponse = SignInResponse.fromJson(response.data);
        SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
        sharedPreferences.setString('accessToken', signinResponse.accessToken);
        sharedPreferences.setString('refreshToken', signinResponse.refreshToken);
        return Right(signinResponse);
      }
    );
  }
  
  @override
  Future<bool> isLoggedIn() async {
    return await sl<AuthLocalService>().isLoggedIn();
  }
  
  @override
  Future<Either> getUser() async {
    Either result = await sl<AuthApiService>().getUser();
    return result.fold(
      (error){
        
        logout();
        
        return Left(error);
      },
      (data) {
        Response response = data;
        var userModel = UserModel.fromMap(response.data);
        var userEntity = userModel.toEntity();
        return Right(userEntity);
      }
     );
  }
  
  @override
  Future<Either> logout() async {
    return await sl<AuthLocalService>().logout();
  }

  @override
  Future<Either<String, SignInResponse>> signin(SigninReqParams signinReq) async {
    Either result = await sl < AuthApiService > ().signin(signinReq);
    return result.fold(
      (error) {
        return Left(error);
      },
      (data) async {
        Response response = data;
        SignInResponse signinResponse = SignInResponse.fromJson(response.data);
        SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
        sharedPreferences.setString('accessToken', signinResponse.accessToken);
        sharedPreferences.setString('refreshToken', signinResponse.refreshToken);
        return Right(signinResponse);
      }
    );
  }
  
}