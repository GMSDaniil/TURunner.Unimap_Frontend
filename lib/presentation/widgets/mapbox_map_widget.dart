import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MapboxMapWidget extends StatefulWidget {
  final List<LatLng> routePoints;
  final List<LatLng> busStops;
  final LatLng? currentLocation;

  const MapboxMapWidget({
    Key? key,
    required this.routePoints,
    required this.busStops,
    required this.currentLocation,
  }) : super(key: key);

  @override
  State<MapboxMapWidget> createState() => _MapBoxWidgetState();
}

class _MapBoxWidgetState extends State<MapboxMapWidget> {
  

  @override
  Widget build(BuildContext context) {
    late MapboxMap mabBoxMap;
    MapboxOptions.setAccessToken(dotenv.env['MAPBOX_ACCESS_TOKEN']!);
  

    void _onMapCreated(MapboxMap map) {
      mabBoxMap = map;
    }

    return MapWidget(
      key: ValueKey("mapWidget"),
      cameraOptions: CameraOptions(
        center: Point(
          coordinates: Position(
            widget.routePoints.isNotEmpty
                ? widget.routePoints.first.longitude
                : 13.3269,
            widget.routePoints.isNotEmpty
                ? widget.routePoints.first.latitude
                : 52.5125,
          ),
        ),
        zoom: 15.0,
      ),
      onMapCreated: _onMapCreated,
      // onMapCreated: _onMapCreated,
    );

    
  }

  

  // void _onMapCreated(MapboxMapController controller) async {
  //   _controller = controller;

  //   // Add route polyline
  //   if (widget.routePoints.length > 1) {
  //     await _controller.addPolyline(
  //       PolylineAnnotationOptions(
  //         geometry: widget.routePoints
  //             .map((p) => Position(p.longitude, p.latitude))
  //             .toList(),
  //         lineColor: "#007AFF",
  //         lineWidth: 5.0,
  //       ),
  //     );
  //   }

  //   // Add bus stop markers
  //   for (final stop in widget.busStops) {
  //     await _controller.addCircle(
  //       CircleAnnotationOptions(
  //         geometry: Position(stop.longitude, stop.latitude),
  //         circleRadius: 9.0,
  //         circleColor: "#ffffff",
  //         circleStrokeColor: "#1976d2",
  //         circleStrokeWidth: 3.0,
  //       ),
  //     );
  //   }

  //   // Add current location marker
  //   if (widget.currentLocation != null) {
  //     await _controller.addCircle(
  //       CircleAnnotationOptions(
  //         geometry: Position(
  //           widget.currentLocation!.longitude,
  //           widget.currentLocation!.latitude,
  //         ),
  //         circleRadius: 16.0,
  //         circleColor: "#007AFF",
  //         circleStrokeColor: "#ffffff",
  //         circleStrokeWidth: 2.0,
  //       ),
  //     );
  //   }
  // }
}