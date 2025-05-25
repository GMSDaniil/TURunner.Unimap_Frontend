
import 'package:auth_app/data/source/pointer_api_service.dart';
import 'package:auth_app/domain/repository/pointers.dart';
import 'package:dio/dio.dart';

import 'package:auth_app/data/models/pointer.dart';
import '../../service_locator.dart';

class PointersRepositoryImpl implements PointersRepository {

  @override
  Future<List<Pointer>> getPointers() async {
    final data = await sl<PointerApiService>().getPointers();

    try{
    final response = data as Response;
    final pointers = (response.data['pointers'] as List)
        .map((json) => Pointer.fromJson(json))
        .toList();
  
    return pointers;
    
    } catch (e) {
      return [];
    }
  }
  
}
