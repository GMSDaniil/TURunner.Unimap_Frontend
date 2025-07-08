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
    required Function(Pointer) onMarkerTap,
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
          onTap: () => onMarkerTap(pointer),
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
      mapController.move(LatLng(filtered.first.lat, filtered.first.lng), zoom);
    }
  }

  /// Search logic: filter markers by name
  static List<Marker> searchMarkersByName({
  required List<Pointer> allPointers,
  required String query,
  required Function(Pointer) onMarkerTap,
}) {
  final q = query.toLowerCase();
  
  final filtered = allPointers.where((p) {
    // Check if pointer name matches
    final nameMatches = p.name.toLowerCase().contains(q);
    
    // Check if any room in this pointer matches
    final roomMatches = p.rooms.any((room) => 
        room.toLowerCase().contains(q));
    
    // Include pointer if either name or any room matches
    return nameMatches || roomMatches;
  }).toList();

  return filtered.map((pointer) => Marker(
    point: LatLng(pointer.lat, pointer.lng),
    width: 40,
    height: 40,
    child: GestureDetector(
      onTap: () => onMarkerTap(pointer),
      child: const Icon(Icons.location_on, color: Colors.deepPurple, size: 32),
    ),
  )).toList();
}

  /// Returns all markers, optionally highlighting a specific category.
  static List<Marker> allMarkersWithHighlight({
    required List<Pointer> allPointers,
    String? highlightedCategory,
    Color? highlightColor,
    required Function(Pointer) onMarkerTap,
  }) {
    return allPointers.map((pointer) {
      final isHighlighted =
          highlightedCategory != null &&
          pointer.category.toLowerCase() == highlightedCategory.toLowerCase();
      return Marker(
        point: LatLng(pointer.lat, pointer.lng),
        width: isHighlighted ? 56 : 36,
        height: isHighlighted ? 56 : 36,
        child: GestureDetector(
          onTap: () => onMarkerTap(pointer),
          child: Icon(
            Icons.location_on,
            color: isHighlighted
                ? (highlightColor ?? Colors.deepPurple)
                : Colors.deepPurple.withOpacity(0.5),
            size: isHighlighted ? 48 : 32,
          ),
        ),
      );
    }).toList();
  }
}
