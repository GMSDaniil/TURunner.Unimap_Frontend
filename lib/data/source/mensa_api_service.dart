import 'package:auth_app/core/constants/api_urls.dart';
import 'package:auth_app/core/network/dio_client.dart';
import 'package:auth_app/data/models/add_favourite_meals_req_params.dart';
import 'package:auth_app/data/models/get_menu_req_params.dart';
import 'package:auth_app/data/source/error_message_extractor.dart';
import 'package:auth_app/service_locator.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MensaApiService {
  final ErrorMessageExtractor _errorMessageExtractor = ErrorMessageExtractor();
  Future<Either> fetchMensaMeals(GetMenuReqParams params) async {
    try {
      final url = '${ApiUrls.baseURL}mensa/${params.mensaName}/menu';
      //print('MensaApiService: URL = $url'); // Zum Debuggen
      final response = await sl<DioClient>().get(url);
      return Right(response);
    } on DioException catch (e) {
      return Left(_errorMessageExtractor.extractErrorMessage(e.response?.data));
    }
  }

  Future<Either> addFavouriteMeal(AddFavouriteMealReqParams params) async {
    try {
      final url = ApiUrls.addFavouriteMeal;
      //print('MensaApiService: URL = $url'); // Zum Debuggen
      final sharedPreferences = await SharedPreferences.getInstance();
      var token = sharedPreferences.getString('accessToken');
      final response = await sl<DioClient>().post(
        
        url,
        data: params.toJson(),
        options: Options(
          headers: {
            'Authorization' : 'Bearer $token'
          }
        ),
      );
      return Right(response);
    } on DioException catch (e) {
      return Left(_errorMessageExtractor.extractErrorMessage(e.response?.data));
    }
  }

  Future<Either> deleteFavouriteMeal(int mealId) async {
    try {
      final url = '${ApiUrls.removeFavouriteMeal}/$mealId';
      //print('MensaApiService: URL = $url'); // Zum Debuggen
      final sharedPreferences = await SharedPreferences.getInstance();
      var token = sharedPreferences.getString('accessToken');
      final response = await sl<DioClient>().delete(
        url,
        options: Options(
          headers: {
            'Authorization' : 'Bearer $token'
          }
        ),
      );
      return Right(response);
    } on DioException catch (e) {
      return Left(_errorMessageExtractor.extractErrorMessage(e.response?.data));
    }
  }
}
