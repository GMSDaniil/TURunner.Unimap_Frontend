import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:auth_app/data/models/pointer.dart';

class MapMarkerManager {
  /// Filters markers by category and returns a list of filtered markers.
  static List<Marker> filterMarkersByCategory({
    required List<Pointer> allPointers,
    required String category, 
    required Color markerColor,
    required Function(String, LatLng) onMarkerTap,
  }) {
    final filtered = allPointers
        .where((p) => p.category.toLowerCase() == category.toLowerCase())
        .toList();

    return filtered.map((pointer) {
      return Marker(
        point: LatLng(pointer.lat, pointer.lng),
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () => onMarkerTap(pointer.name, LatLng(pointer.lat, pointer.lng)),
          child: Icon(Icons.location_on, color: markerColor),
        ),
      );
    }).toList();
  }

  /// Centers the map on the first item of a filtered list, if available.
  static void centerMapOnFilteredResults({
    required MapController mapController,
    required List<Pointer> filtered,
    double zoom = 17.0,
  }) {
    if (filtered.isNotEmpty) {
      mapController.move(
        LatLng(filtered.first.lat, filtered.first.lng),
        zoom,
      );
    }
  }

  /// Search logic: filter markers by name
  static List<Marker> searchMarkersByName({
    required List<Pointer> allPointers,
    required String query,
    required Function(String, LatLng) onMarkerTap,
  }) {
    final filtered = allPointers
        .where((pointer) => 
            pointer.name.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return filtered.map((pointer) {
      return Marker(
        point: LatLng(pointer.lat, pointer.lng),
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () => onMarkerTap(pointer.name, LatLng(pointer.lat, pointer.lng)),
          child: const Icon(Icons.location_on, color: Colors.deepPurple),
        ),
      );
    }).toList();
  }
}
