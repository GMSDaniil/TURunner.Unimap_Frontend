import 'package:latlong2/latlong.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class InteractiveAnnotation {
  final PointAnnotationOptions options;
  final void Function() onTap;
  final String category; // Marker type/category (e.g., 'building', 'cafe', etc.)

  InteractiveAnnotation({
    required this.options,
    required this.onTap,
    required this.category,
  });
}