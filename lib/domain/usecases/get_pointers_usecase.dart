import 'package:auth_app/data/models/get_pointers_req_params.dart';
import 'package:auth_app/data/models/pointer.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GetPointersUseCase {
  Future<List<Pointer>> call(GetPointersRequest req) async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:8000/api/get-pointers'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(req.toJson()),
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Pointer.fromJson(e)).toList();
    } else {
      throw Exception('Failed to fetch pointers');
    }
  }
}