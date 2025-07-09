import 'dart:convert';
import 'package:auth_app/data/models/add_favourite_meals_req_params.dart';
import 'package:dio/dio.dart';
import 'package:auth_app/data/models/get_menu_req_params.dart';
import 'package:auth_app/data/models/mensa_menu_response.dart';
import '../../domain/repository/mensa.dart';
import '../source/mensa_api_service.dart';
import '../../service_locator.dart';
import 'package:dartz/dartz.dart';

class MensaRepositoryImpl implements MensaRepository {
  @override
  Future<Either<String, MensaMenuResponse>> getMensaMenu(
    GetMenuReqParams params,
  ) async {
    final result = await sl<MensaApiService>().fetchMensaMeals(params);

    return result.fold(
      (errorMessage) {
        //print('MensaApiService error: $errorMessage'); 
        return Left(errorMessage);
      },
      (response) {
        //print('MensaApiService response: ${response.data}');
        try {
          final data = response.data is String
              ? jsonDecode(response.data)
              : response.data;
          final menu = MensaMenuResponse.fromJson(data);
          return Right(menu);
        } catch (e) {
          //print('Error parsing mensa menu data: $e');
          return Left('Failed to parse mensa menu data');
        }
      },
    );
  }

  @override
  Future<Either<String, int>> addFavouriteMeal(
    AddFavouriteMealReqParams params,
  ) async {
    final result = await sl<MensaApiService>().addFavouriteMeal(params);

    return result.fold(
      (errorMessage) {
        //print('MensaApiService error: $errorMessage');
        return Left(errorMessage);
      },
      (response) {
        //print('MensaApiService response: ${response.data}');
        try {
          final data = response.data is String
              ? jsonDecode(response.data)
              : response.data;
          final mealId = data['id'] as int;
          return Right(mealId);
        } catch (e) {
          //print('Error parsing add favourite meal response: $e');
          return Left('Failed to parse add favourite meal response');
        }
      },
    );
  }

  @override
  Future<Either<String, void>> deleteFavouriteMeal(int mealId) async {
    final result = await sl<MensaApiService>().deleteFavouriteMeal(mealId);

    return result.fold(
      (errorMessage) {
        //print('MensaApiService error: $errorMessage');
        return Left(errorMessage);
      },
      (response) {
        //print('MensaApiService response: ${response.data}');
        return Right(null); // Assuming successful deletion returns void
      },
    );
  }
}
