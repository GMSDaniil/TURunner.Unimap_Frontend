import 'package:auth_app/core/constants/api_urls.dart';
import 'package:auth_app/core/network/dio_client.dart';
import 'package:auth_app/data/source/error_message_extractor.dart';
import 'package:auth_app/data/source/token_manager.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../service_locator.dart';
import '../models/signin_req_params.dart';
import '../models/signup_req_params.dart';

abstract class AuthApiService {

  Future<Either> signup(SignupReqParams signupReq);
  Future<Either> getUser();
  Future<Either> signin(SigninReqParams signinReq);
} 

class AuthApiServiceImpl extends AuthApiService {
  final ErrorMessageExtractor _errorMessageExtractor = ErrorMessageExtractor();
  

  @override
  Future<Either> signup(SignupReqParams signupReq) async {
    try {

     var response = await sl<DioClient>().post(
        ApiUrls.register,
        data: signupReq.toMap()
      );

      return Right(response);

    } on DioException catch(e) {
      return Left(_errorMessageExtractor.extractErrorMessage(e.response?.data));
    }
  }
  
  @override
  Future<Either> getUser() async {

    
    try {
       SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
       var token = sharedPreferences.getString('accessToken');
       var response = await sl<DioClient>().get(
        ApiUrls.userProfile,
        options: Options(
          headers: {
            'Authorization' : 'Bearer $token'
          }
        )
      );

      return Right(response);

    } on DioException catch(e) {
      if (e.response?.statusCode == 401) {
        final tokenManager = TokenManager();
        
        bool tokenRefreshed = await tokenManager.refreshToken();

        if (tokenRefreshed) {
            SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
            var newToken = sharedPreferences.getString('accessToken');

            var retryResponse = await sl<DioClient>().get(
              ApiUrls.userProfile,
              options: Options(
                headers: {
                  'Authorization': 'Bearer $newToken',
                },
              ),
            );

            return Right(retryResponse);
        } else {
            // Handle the case when the refresh token is also invalid
            return Left('Refresh token expired.');
        }
        
      }
      return Left(_errorMessageExtractor.extractErrorMessage(e.response?.data));
    }
  }
  
  @override
  Future<Either> signin(SigninReqParams signinReq) async {
    try {

     var response = await sl<DioClient>().post(
        ApiUrls.login,
        data: signinReq.toMap()
      );

      return Right(response);

    } on DioException catch(e) {
      return Left(_errorMessageExtractor.extractErrorMessage(e.response?.data));
    }
  }
  
}




