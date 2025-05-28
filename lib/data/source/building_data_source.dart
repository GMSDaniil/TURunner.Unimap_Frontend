import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:auth_app/data/models/building.dart';

class BuildingDataSource {
  Future<List<BuildingModel>> loadBuildings() async {
    final jsonStr = await rootBundle.loadString('assets/campus_buildings.json');
    final List data = jsonDecode(jsonStr);
    return data.map<BuildingModel>((e) => BuildingModel.fromJson(e)).toList();
  }
}