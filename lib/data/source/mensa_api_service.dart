import 'package:dio/dio.dart';
import '../models/meal_model.dart';

class MensaApiService {
  final Dio dio;

  MensaApiService(this.dio);

  Future<List<MealModel>> fetchMensaMeals(String mensaName) async {
    final response = await dio.post(
      '/getMensaMenu',
      data: {'mensa': mensaName},
    );
    final List data = response.data;
    return data.map((meal) => MealModel.fromJson(meal)).toList();
  }
}
