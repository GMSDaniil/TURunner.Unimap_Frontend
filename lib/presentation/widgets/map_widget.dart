/// Utility to compute the best position for a line rectangle between two stops.
// Place all imports at the top
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:auth_app/data/models/route_segment.dart';
import 'package:flutter_map/flutter_map.dart' show StrokePattern, PatternFit;
import 'package:auth_app/presentation/widgets/route_options_sheet.dart'; // if needed

LatLng getLineRectanglePosition(LatLng stopA, LatLng stopB, {double minDistance = 20.0}) {
  final Distance distance = const Distance();
  final double totalDist = distance(stopA, stopB);
  // If the stops are too close, just return the midpoint
  if (totalDist < minDistance * 2) {
    return LatLng(
      (stopA.latitude + stopB.latitude) / 2,
      (stopA.longitude + stopB.longitude) / 2,
    );
  }
  // Find the midpoint
  final double midLat = (stopA.latitude + stopB.latitude) / 2;
  final double midLng = (stopA.longitude + stopB.longitude) / 2;
  LatLng midPoint = LatLng(midLat, midLng);
  // Check distance from midpoint to each stop
  final double distToA = distance(midPoint, stopA);
  final double distToB = distance(midPoint, stopB);
  // If too close to either stop, nudge along the segment
  if (distToA < minDistance || distToB < minDistance) {
    // Move the rectangle towards the farther stop
    final double nudgeRatio = minDistance / totalDist;
    final double nudgeLat = (stopB.latitude - stopA.latitude) * nudgeRatio;
    final double nudgeLng = (stopB.longitude - stopA.longitude) * nudgeRatio;
    if (distToA < distToB) {
      // Nudge towards B
      midPoint = LatLng(stopA.latitude + nudgeLat, stopA.longitude + nudgeLng);
    } else {
      // Nudge towards A
      midPoint = LatLng(stopB.latitude - nudgeLat, stopB.longitude - nudgeLng);
    }
  }
  return midPoint;
}

/// A widget that builds the FlutterMap with given configuration.
class MapWidget extends StatelessWidget {
  final MapController mapController;
  final List<Marker> markers;
  final List<Marker> busStopMarkers;
  final List<Marker> scooterMarkers;
  final List<RouteSegment> segments;
  final LatLng? currentLocation;
  final TileProvider cachedTileProvider;
  final Function(LatLng) onMapTap;
  final BuildContext parentContext;

  const MapWidget({
    Key? key,
    required this.mapController,
    required this.markers,
    required this.busStopMarkers,
    required this.scooterMarkers,
    required this.segments,
    required this.currentLocation,
    required this.cachedTileProvider,
    required this.onMapTap,
    required this.parentContext,
  }) : super(key: key);

  /// Returns a smooth polyline for better course rendering.
  List<LatLng> smoothPolyline(List<LatLng> points, {int iterations = 2}) {
    List<LatLng> result = List.from(points);
    for (int it = 0; it < iterations; it++) {
      List<LatLng> newPoints = [];
      for (int i = 0; i < result.length - 1; i++) {
        final p0 = result[i];
        final p1 = result[i + 1];
        final q = LatLng(
          0.75 * p0.latitude + 0.25 * p1.latitude,
          0.75 * p0.longitude + 0.25 * p1.longitude,
        );
        final r = LatLng(
          0.25 * p0.latitude + 0.75 * p1.latitude,
          0.25 * p0.longitude + 0.75 * p1.longitude,
        );
        newPoints..add(p0)..add(q)..add(r);
      }
      newPoints.add(result.last);
      result = newPoints;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    // Combine all route points; used later for a pinch marker
    final allPoints = <LatLng>[];
    for (final seg in segments) {
      allPoints.addAll(seg.path);
    }

    // --- Track zoom level for hiding stops ---
    double currentZoom = mapController.camera.zoom;
    // --- Compute rectangle positions for each segment (between stops) ---
    final List<Marker> lineRectMarkers = [];
    for (final seg in segments) {
      if (seg.path.length >= 2 && seg.transportLine != null && seg.transportLine!.isNotEmpty) {
        // 1. Take the midpoint of the segment path
        final LatLng mid = LatLng(
          (seg.path.first.latitude + seg.path.last.latitude) / 2,
          (seg.path.first.longitude + seg.path.last.longitude) / 2,
        );

        // 2. Find the two closest stops to the midpoint
        List<LatLng> stops = [seg.path.first, seg.path.last];
        if (seg.path.length > 2) {
          stops = [for (final p in seg.path) p];
        }
        stops.sort((a, b) => const Distance()(mid, a).compareTo(const Distance()(mid, b)));
        final LatLng stopA = stops[0];
        final LatLng stopB = stops[1];

        // 3. Place the label at the midpoint between those two stops
        final LatLng rectPos = LatLng(
          (stopA.latitude + stopB.latitude) / 2,
          (stopA.longitude + stopB.longitude) / 2,
        );

        lineRectMarkers.add(
          Marker(
            point: rectPos,
            width: 48,
            height: 28,
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.black26, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                seg.transportLine!,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        );
      }
    }

    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: LatLng(52.5125, 13.3269),
        initialZoom: 17.0,
        minZoom: 12.0,
        maxZoom: 18.0,
        cameraConstraint: CameraConstraint.contain(
          bounds: LatLngBounds(LatLng(52.505, 13.316), LatLng(52.523, 13.337))
        ),
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
        backgroundColor: Colors.grey.shade200,
        onTap: (tapPos, latlng) => onMapTap(latlng),
      ),
      children: [
        // Tile provider layer
        // TileLayer(
        //   urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        //   userAgentPackageName: 'com.example.app',
        //   tileProvider: cachedTileProvider,
        // ),
        TileLayer(
          urlTemplate: 'https://api.mapbox.com/styles/v1/{username}/{style_id}/tiles/256/{z}/{x}/{y}@2x?access_token={accessToken}',
          // urlTemplate: 'https://api.mapbox.com/v4/mapbox.standard/{z}/{x}/{y}.png?access_token={accessToken}',
          additionalOptions: {
            'accessToken': dotenv.env['MAPBOX_ACCESS_TOKEN']!,
            'username': 'mapbox',
            'style_id': 'streets-v12',
          },
        ),
        // Polyline layer for routes
        PolylineLayer(
          polylines: [
            for (final seg in segments)
              Polyline(
                points: seg.mode == TravelMode.bus && seg.precisePolyline != null
                    ? smoothPolyline(seg.precisePolyline!)
                    : seg.path.length > 2
                        ? smoothPolyline(seg.path)
                        : seg.path,
                strokeWidth: 5,
                color: seg.mode == TravelMode.bus
                    ? Colors.blue
                    : seg.mode == TravelMode.scooter
                        ? Colors.orange
                        : Theme.of(parentContext).primaryColor,
                borderStrokeWidth: 2,
                borderColor: Colors.white,
                pattern: seg.mode == TravelMode.bus || seg.mode == TravelMode.scooter
                    ? const StrokePattern.solid()
                    : const StrokePattern.dotted(
                        spacingFactor: 2.0,
                        patternFit: PatternFit.appendDot,
                      ),
              ),
          ],
        ),
        // Marker layer for various markers
        // --- Markers: stops, scooters, user, and line rectangles ---
        MarkerLayer(
          markers: [
            ...markers,
            if (currentZoom >= 15) ...busStopMarkers,
            ...scooterMarkers,
            ...lineRectMarkers,
            if (currentLocation != null)
              Marker(
                point: currentLocation!,
                width: 40,
                height: 40,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ],
                ),
              ),
            if (allPoints.length > 1)
              Marker(
                point: allPoints.last,
                width: 44,
                height: 44,
                child: Icon(
                  Icons.location_pin,
                  color: Colors.red.shade700,
                  size: 44,
                ),
              ),
          ],
        ),
      ],
    );
  }
}