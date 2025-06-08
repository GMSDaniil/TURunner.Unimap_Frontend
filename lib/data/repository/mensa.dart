import 'dart:convert';
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
        print('MensaApiService error: $errorMessage');
        return Left(errorMessage);
      },
      (response) {
        print('MensaApiService response: ${response.data}');
        try {
          final data = response.data is String
              ? jsonDecode(response.data)
              : response.data;
          final menu = MensaMenuResponse.fromJson(data);
          return Right(menu);
        } catch (e) {
          print('Error parsing mensa menu data: $e');
          return Left('Failed to parse mensa menu data');
        }
      },
    );
  }
}
