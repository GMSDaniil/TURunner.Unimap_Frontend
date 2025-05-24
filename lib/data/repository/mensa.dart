import 'package:auth_app/data/models/get_menu_req_params.dart';
import 'package:auth_app/data/models/meal_model.dart';
import 'package:dio/dio.dart';

import '../../domain/repository/mensa.dart';
import '../source/mensa_api_service.dart';
import '../../service_locator.dart';

class MensaRepositoryImpl implements MensaRepository {

  @override
  Future<List<MealModel>> getMensaMenu(
    GetMenuReqParams  params,
  ) async {
    final data = await sl<MensaApiService>().fetchMensaMeals(params);

    try{
    final response = data as Response;
    final meals = (response.data['meals'] as List)
        .map((json) => MealModel.fromJson(json))
        .toList();
  
    return meals;
    
    } catch (e) {
      return [];
    }
  }
  
}
