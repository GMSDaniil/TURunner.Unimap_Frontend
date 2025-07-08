import 'package:auth_app/data/models/pointer.dart';

class SearchableItem {
  final String name;
  final String category;
  final double lat;
  final double lng;
  final SearchItemType type;
  final Pointer? parentPointer; // null for buildings, set for rooms
  final String? roomName; // null for buildings, set for rooms

  SearchableItem({
    required this.name,
    required this.category,
    required this.lat,
    required this.lng,
    required this.type,
    this.parentPointer,
    this.roomName,
  });
}

enum SearchItemType { point, room }