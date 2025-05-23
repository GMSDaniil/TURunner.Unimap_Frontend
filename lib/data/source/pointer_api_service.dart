import 'package:auth_app/data/models/get_pointers_req_params.dart';
import 'package:auth_app/data/models/pointer.dart';

class PointerApiService {
  Future<List<Pointer>> getPointers(GetPointersRequest req) async {
    // Simulate network delay
    await Future.delayed(Duration(milliseconds: 500));
    // Return mock data
    return [
      // Pointer(name: 'Library', lat: 52.5125, lng: 13.3269, category: 'Library'),
      // Pointer(name: 'Cafeteria', lat: 52.5130, lng: 13.3275, category: 'Cafeteria'),
      // Pointer(name: 'Lab', lat: 52.5115, lng: 13.3255, category: 'Lab'),
      // Pointer(name: 'TU Mensa', lat: 52.5121, lng: 13.3260, category: 'Mensa'), // Added TU Mensa
    ];
  }
}