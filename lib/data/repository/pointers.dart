import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:auth_app/data/models/pointer.dart';
import '../../domain/repository/pointers.dart';

class PointersRepositoryImpl implements PointersRepository {
  @override
  Future<List<Pointer>> getPointers() async {
    
    /*
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
    */

    try {
      // Load from local asset file
      final jsonStr = await rootBundle.loadString('assets/campus_buildings.json');
      final List data = jsonDecode(jsonStr);
      final pointers = data.map((json) => Pointer.fromJson(json)).toList();
      return List<Pointer>.from(pointers);
    } catch (e) {
      print('Error loading pointers from local asset: $e');
      return [];
    }
  }
}
