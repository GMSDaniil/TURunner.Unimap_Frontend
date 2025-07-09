import 'dart:async';
import 'dart:convert';

import 'package:auth_app/data/models/interactive_annotation.dart';
import 'package:auth_app/data/models/route_segment.dart';
import 'package:auth_app/data/theme_manager.dart';
import 'package:auth_app/presentation/widgets/rain_widget.dart';
import 'package:auth_app/presentation/widgets/route_options_sheet.dart';
import 'package:flutter/material.dart';
//import 'package:flutter_map/flutter_map.dart' hide MapOptions;
import 'package:geolocator/geolocator.dart'as gl;
import 'package:latlong2/latlong.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide LocationSettings;
import 'package:flutter/foundation.dart';

final List<String> markers = [
  'mensa',
  'library',
  'cafe',
  'default',
  'destination', 
];


class MapboxMapWidget extends StatefulWidget {
  final List<LatLng> busStopMarkers;
  /// Annotations to show on the map
  final List<InteractiveAnnotation> markerAnnotations;
  final Map<String, Uint8List> markerImageCache;
  final MapTheme? mapTheme;
  bool isRaining = false; // New: flag to control rain overlay
  final LatLng? destinationLatLng;
  /// Optional controller callback: parent can capture the unhighlight function to call when needed (e.g., when panel closes).
  final void Function(void Function())? onClearHighlightController;
  final double navBarHeight;
  final List<RouteSegment> segments;
  final Function(LatLng) onMapTap;
  final void Function(MapboxMap)? onMapCreated;
  final BuildContext parentContext;
  /// New: optional camera change callback
  final void Function(CameraChangedEventData)? onCameraChanged;

  MapboxMapWidget({
    super.key,
    required this.markerAnnotations,
    required this.navBarHeight,
    this.destinationLatLng,
    this.mapTheme,
    required this.markerImageCache,
    required this.busStopMarkers,
    required this.segments,
    this.isRaining = false,
    required this.onMapTap,
    required this.onMapCreated,
    this.onClearHighlightController,
    required this.parentContext,
    this.onCameraChanged,
    List<RouteSegment> routePoints = const [],
  });

  @override
  State<MapboxMapWidget> createState() => _MapBoxWidgetState();
}


class _MapBoxWidgetState extends State<MapboxMapWidget> {

  /// Helper to get color for a transport type
  int _lineColor(String? transportType) {
    switch (transportType) {
      case 'bus':
        return const Color(0xFF9C27B0).value;
      case 'subway':
        return const Color(0xFF1565C0).value;
      case 'tram':
        return const Color(0xFFD32F2F).value; // Red for tram
      case 'suburban':
        return const Color(0xFF388E3C).value; // Green for S-Bahn
      default:
        return Colors.black.value;
    }
  }

  /// Removes all changeover circles and labels from the map
  Future<void> removeChangeoverMarkers() async {
    final layers = await mapboxMap.style.getStyleLayers();
    final sources = await mapboxMap.style.getStyleSources();
    for (final layer in [...layers]) {
      if (layer != null && (layer.id.startsWith('changeover-layer-') || layer.id.startsWith('changeover-label-layer-'))) {
        await mapboxMap.style.removeStyleLayer(layer.id);
      }
    }
    for (final src in [...sources]) {
      if (src != null && (src.id.startsWith('changeover-source-') || src.id.startsWith('changeover-label-source-'))) {
        await mapboxMap.style.removeStyleSource(src.id);
      }
    }
  }
  var _currentTheme = MapTheme.day;
  /// Draws small white points for all bus stops along the bus segments
  Future<void> drawBusStopMarkers(List<LatLng> busMarkers) async {
    // Remove old bus stop layers/sources
    final layers = await mapboxMap.style.getStyleLayers();
    final sources = await mapboxMap.style.getStyleSources();
    for (final layer in [...layers]) {
      if (layer!.id.startsWith('busstop-layer-')) {
        await mapboxMap.style.removeStyleLayer(layer.id);
      }
    }
    for (final src in [...sources]) {
      if (src!.id.startsWith('busstop-source-')) {
        await mapboxMap.style.removeStyleSource(src.id);
      }
    }

    for (int i = 0; i < busMarkers.length; i++) {
      final marker = busMarkers[i];
      final srcId = 'busstop-source-$i';
      final lyrId = 'busstop-layer-$i';

      await mapboxMap.style.addSource(GeoJsonSource(
        id: srcId,
        data: jsonEncode({
          "type": "FeatureCollection",
          "features": [
            {
              "type": "Feature",
              "geometry": {
                "type": "Point",
                "coordinates": [marker.longitude, marker.latitude]
              },
              "properties": {}
            }
          ]
        }),
      ));

      await mapboxMap.style.addLayer(CircleLayer(
        id: lyrId,
        sourceId: srcId,
        circleEmissiveStrength: 1.0,
        circleRadius: 3.5, // slightly larger for better visibility
        circleColor: Colors.white.value,
        circleStrokeColor: Colors.grey.value,
        circleStrokeWidth: 1.0,
      ));
    }
  }
  /*────────────  zoom-direction “memory”  ────────────*/
  /// pins hidden during the **current zoom-out** gesture
  final Set<String> _hiddenThisZoomOut = {};
  /// pins that have appeared during the **current zoom-in** gesture
  /// (must never disappear until we zoom-out again)
  final Set<String> _visibleThisZoomIn = {};
  double? _lastMarkerVisibilityZoom;
  DateTime _lastUpdate = DateTime.fromMillisecondsSinceEpoch(0);
  //Timer? _cameraPollTimer;
  double? _lastZoom;
  // ── dynamic-marker visibility ───────────────────────────────────
  //static const double _markerZoomThreshold = 14.0;   // tune as you like
  /*──────────── Highlight Logic ────────────*/

  /// Centralized method for selecting and highlighting a building, with zoom logic
  Future<void> selectBuilding(dynamic feature, dynamic event) async {
    final cameraState = await mapboxMap.getCameraState();
    const minZoom = 15.2;

    // If zoom is too low, animate to minZoom and center on the building
    if (cameraState.zoom < minZoom) {
      
    }

    // Always de-highlight previous building
    await unhighlightCurrentBuilding();

    // Highlight new building
    await mapboxMap.setFeatureStateForFeaturesetFeature(
      feature,
      StandardBuildingsState(highlight: true),
    );
    _highlightedBuilding = feature;

    // Forward tap to parent
    widget.onMapTap(LatLng(
      event.point.coordinates.lat.toDouble(),
      event.point.coordinates.lng.toDouble(),
    ));
  }

  /// Helper method to unhighlight the currently highlighted building
  Future<void> unhighlightCurrentBuilding() async {
    if (_highlightedBuilding != null) {
      await mapboxMap.setFeatureStateForFeaturesetFeature(
        _highlightedBuilding,
        StandardBuildingsState(highlight: false),
      );
      _highlightedBuilding = null;
    }
  }

  @override
  void initState() {
    super.initState();
    _setupPositionTracking();
    _currentTheme = widget.mapTheme ?? ThemeManager.getCurrentTheme();
    
    // Expose the canonical clear highlight function to the parent if requested
    if (widget.onClearHighlightController != null) {
      widget.onClearHighlightController!(unhighlightCurrentBuilding);
    }
    // No polling timer: marker visibility will update on camera events
  }
  final Map<String, VoidCallback> _markerTapCallbacks = {};
  late MapboxMap mapboxMap;
  Map<String, Object> mapConfig = {
      "showPointOfInterestLabels": false,
      "lightPreset": "day",
      "colorBuildingHighlight": "#B39DDB",
    };
  late PointAnnotationManager pointAnnotationManager;
  late PolylineAnnotationManager polylineAnnotationManager;

  StreamSubscription? userPositionStream;
  dynamic _highlightedBuilding;

  bool _isMapInitialized = false;

  final Map<String, PointAnnotation> _liveAnnotations = {};

  /* single canonical “clear” helper – both tap-handler and
   * parent UI will use this via the exposed callback above               */
  // Future<void> unhighlightCurrentBuilding() async {
  //   if (_highlightedBuilding != null) {
  //     await mapboxMap.setFeatureStateForFeaturesetFeature(
  //       _highlightedBuilding, StandardBuildingsState(highlight: false),
  //     );
  //     _highlightedBuilding = null;
  //   }
  // }

  // @override
  // void initState() {
  //   super.initState();
  //   _setupPositionTracking();
  // }

  @override
  void didUpdateWidget(covariant MapboxMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if(!mounted) return;
    if (!_isMapInitialized) {
      // MapboxMap is not initialized yet, skip updates
      return;
    }
    // If the annotations list changed, update the map
    if (widget.markerAnnotations != oldWidget.markerAnnotations) {
      _updateAllMarkers();
      print("Updated markers");
    }

    if(widget.segments != oldWidget.segments) {
      // Remove old changeover markers before drawing new ones
      removeChangeoverMarkers();
      drawStyledRouteSegments(widget.segments);
      if (widget.busStopMarkers != null) {
        drawBusStopMarkers(widget.busStopMarkers!);
      }
      print("Updated polylines");
    }

    if (widget.destinationLatLng != oldWidget.destinationLatLng) {
      if (widget.destinationLatLng != null) {
        addDestinationMarker(widget.destinationLatLng!);
      } else {
        deleteDestinationMarker();
      }
    }

    if (widget.mapTheme != oldWidget.mapTheme && widget.mapTheme != null) {
      _currentTheme = widget.mapTheme!;
      _updateMapTheme();
    }
  }

  void _updateMapTheme() {
    if (mapboxMap == null) return;
    
    mapConfig["lightPreset"] = _currentTheme.toString();
    mapboxMap.style.setStyleImportConfigProperties("basemap", mapConfig);
  }

  @override
    void dispose(){
      // No polling timer to cancel
      try{
        mapboxMap.dispose();
      }catch(e){
        if(kDebugMode){
          print("Error disposing mapboxMap: $e");
        }
      }
      userPositionStream?.cancel();
      _liveAnnotations.clear();
      _markerTapCallbacks.clear();
      _hiddenThisZoomOut.clear();
      _visibleThisZoomIn.clear();
      super.dispose();
    }

  Future<void> _addInteractiveMarkers(
    Iterable<InteractiveAnnotation> annotations) async {
  if (annotations.isEmpty) return;
  final opts = annotations.map((a) => a.options).toList();
  final created = await pointAnnotationManager.createMulti(opts);
  int i = 0;
  for (final pa in created) {
    if (pa == null) continue;
    final key = _markerKeyFromPoint(pa.geometry.coordinates);
    _liveAnnotations[key] = pa;
    _markerTapCallbacks[pa.id] = annotations.elementAt(i).onTap;
    i++;
  }
}

  Future<void> drawStyledRouteSegments(List<RouteSegment> segments) async {
  // ── 1) Clean up old route, changeover, and bus label layers/sources ─────────────
  final layers = await mapboxMap.style.getStyleLayers();
  final sources = await mapboxMap.style.getStyleSources();
  for (final layer in [...?layers]) {
    if (layer!.id.startsWith('route-layer-') ||
        layer.id.startsWith('change-layer-') ||
        layer.id.startsWith('bus-label-layer-')) {
      await mapboxMap.style.removeStyleLayer(layer.id);
    }
  }
  for (final src in [...?sources]) {
    if (src!.id.startsWith('route-source-') ||
        src.id.startsWith('change-source-') ||
        src.id.startsWith('bus-label-source-')) {
      await mapboxMap.style.removeStyleSource(src.id);
    }
  }

  

  // ── 2) Draw each route segment as you already do ────────────────
  for (int i = 0; i < segments.length; i++) {
    final seg = segments[i];
    final points = (seg.mode == TravelMode.bus && seg.precisePolyline != null)
        ? smoothPolyline(seg.precisePolyline!)
        : smoothPolyline(seg.path);

    if (points.length < 2) continue;

    final coordinates = points.map((p) => [p.longitude, p.latitude]).toList();

    final geojson = {
      "type": "FeatureCollection",
      "features": [
        {
          "type": "Feature",
          "geometry": {
            "type": "LineString",
            "coordinates": coordinates,
          },
          "properties": {}
        }
      ]
    };

    // Choose color and dash style based on mode
    int color;
    List<double>? dashArray;
    // Use transportType for color selection
    if (seg.transportType == 'bus') {
      color = const Color(0xFF9C27B0).toARGB32(); // purple for bus
      dashArray = null;
    } else if (seg.transportType == 'subway') {
      color = const Color(0xFF1565C0).toARGB32(); // blue for subway (U-Bahn)
      dashArray = null;
    } else if (seg.transportType == 'tram') {
      color = const Color(0xFFD32F2F).toARGB32(); // red for tram
      dashArray = null;
    } else if (seg.transportType == 'suburban') {
      color = const Color(0xFF388E3C).toARGB32(); // green for S-Bahn
      dashArray = null;
    } else if (seg.mode == TravelMode.scooter) {
      color = const Color(0xFFFFA500).toARGB32();
      dashArray = null;
    } else {
      color = const Color(0xFF1A73E8).toARGB32();
      dashArray = [0.1, 2.0]; // Better dots for walking
    }

    // Use unique IDs for each segment (mode + index)
    final sourceId = 'route-source-${seg.mode.name}-$i';
    final layerId = 'route-layer-${seg.mode.name}-$i';

    try {
      await mapboxMap.style.addSource(GeoJsonSource(
        id: sourceId,
        data: jsonEncode(geojson),
      ));

      await mapboxMap.style.addLayer(LineLayer(
        id: layerId,
        sourceId: sourceId,
        lineColor: color,
        lineEmissiveStrength: 1.0,
        lineWidth: seg.mode == TravelMode.walk ? 5.0 : 6.0,
        lineDasharray: dashArray,
        lineCap: LineCap.ROUND,
        lineJoin: LineJoin.ROUND,
      ));

      // ── Add line label as a horizontal rectangle ──
      final isBus = seg.transportType == 'bus';
      final isSubway = seg.transportType == 'subway';
      final isTram = seg.transportType == 'tram';
      final isSuburban = seg.transportType == 'suburban';
      if ((isBus || isSubway || isTram || isSuburban) && seg.transportLine != null && seg.transportLine.toString().isNotEmpty) {
        // Find a good label point (midpoint of the polyline)
        final labelPoint = points[points.length ~/ 2];
        final labelSourceId = 'bus-label-source-$i';
        final labelLayerId = 'bus-label-layer-$i';
        await mapboxMap.style.addSource(GeoJsonSource(
          id: labelSourceId,
          data: jsonEncode({
            "type": "FeatureCollection",
            "features": [
              {
                "type": "Feature",
                "geometry": {
                  "type": "Point",
                  "coordinates": [labelPoint.longitude, labelPoint.latitude]
                },
                "properties": {
                  "lineName": seg.transportLine
                }
              }
            ]
          }),
        ));
        int haloColor = isBus
            ? const Color(0xFF9C27B0).value
            : isSubway
                ? const Color(0xFF1565C0).value
                : isTram
                    ? const Color(0xFFD32F2F).value
                    : isSuburban
                        ? const Color(0xFF388E3C).value
                        : Colors.black.value;
        await mapboxMap.style.addLayerAt(SymbolLayer(
          id: labelLayerId,
          sourceId: labelSourceId,
          textField: '{lineName}',
          textSize: 15.0,
          iconEmissiveStrength: 1.0,
          textEmissiveStrength: 1.0,
          textColor: Colors.white.value,
          textHaloColor: haloColor,
          textHaloWidth: 6.0,
          textHaloBlur: 1.0,
          textRotationAlignment: TextRotationAlignment.VIEWPORT,
          textPitchAlignment: TextPitchAlignment.VIEWPORT,
          textKeepUpright: true,
          textAnchor: TextAnchor.CENTER,
          textJustify: TextJustify.CENTER,
          textFont: ["Open Sans Bold", "Arial Unicode MS Bold"],
        ),
        LayerPosition(above: 'busstop-layer-$i'),
        );
      }
    } catch (e) {
      print('Error adding route segment $i (${seg.mode.name}): $e');
    }
  }

  // ── 3) Add a label at each changeover ─────────────────
  for (int i = 1; i < segments.length; i++) {
    if (segments[i].mode != segments[i - 1].mode) {
      final prevSeg = segments[i - 1];
      final nextSeg = segments[i];
      final LatLng switchPoint = nextSeg.path.first;
      final srcId = 'changeover-source-$i';
      final lyrId = 'changeover-layer-$i';

      // Always add a big circle at every changeover
      int strokeColor = _lineColor(nextSeg.transportType);
      if (strokeColor == Colors.black.value) strokeColor = Colors.grey.value;

      await mapboxMap.style.addSource(GeoJsonSource(
        id: srcId,
        data: jsonEncode({
          "type": "FeatureCollection",
          "features": [
            {
              "type": "Feature",
              "geometry": {
                "type": "Point",
                "coordinates": [switchPoint.longitude, switchPoint.latitude]
              },
              "properties": {}
            }
          ]
        }),
      ));

      await mapboxMap.style.addLayer(CircleLayer(
        id: lyrId,
        sourceId: srcId,
        circleEmissiveStrength: 1.0,
        circleRadius: 5,
        circleColor: Colors.white.value,
        circleStrokeColor: strokeColor,
        circleStrokeWidth: 3.0,
      ));

      // Show label if both previous and next are public transport
      final prevIsTransport = prevSeg.transportType == 'bus' || prevSeg.transportType == 'subway' || prevSeg.transportType == 'tram' || prevSeg.transportType == 'suburban';
      final nextIsTransport = nextSeg.transportType == 'bus' || nextSeg.transportType == 'subway' || nextSeg.transportType == 'tram' || nextSeg.transportType == 'suburban';
      if (prevIsTransport && nextIsTransport) {
        final prevLine = prevSeg.transportLine?.toString() ?? '';
        final nextLine = nextSeg.transportLine?.toString() ?? '';
        // Always show label, even if one is empty
        String label;
        if (prevLine.isNotEmpty && nextLine.isNotEmpty) {
          label = '$prevLine > $nextLine';
        } else if (prevLine.isNotEmpty) {
          label = prevLine;
        } else if (nextLine.isNotEmpty) {
          label = nextLine;
        } else {
          label = '';
        }
        if (label.isNotEmpty) {
          final labelSrcId = 'changeover-label-source-$i';
          final labelLyrId = 'changeover-label-layer-$i';

          await mapboxMap.style.addSource(GeoJsonSource(
            id: labelSrcId,
            data: jsonEncode({
              "type": "FeatureCollection",
              "features": [
                {
                  "type": "Feature",
                  "geometry": {
                    "type": "Point",
                    "coordinates": [switchPoint.longitude, switchPoint.latitude]
                  },
                  "properties": {
                    "changeLabel": label
                  }
                }
              ]
            }),
          ));

          int haloColor = _lineColor(nextSeg.transportType);
          await mapboxMap.style.addLayerAt(SymbolLayer(
            id: labelLyrId,
            sourceId: labelSrcId,
            textField: '{changeLabel}',
            textSize: 15.0,
            iconEmissiveStrength: 1.0,
            textEmissiveStrength: 1.0,
            textColor: Colors.white.value,
            textHaloColor: haloColor,
            textHaloWidth: 6.0,
            textHaloBlur: 1.0,
            textRotationAlignment: TextRotationAlignment.VIEWPORT,
            textPitchAlignment: TextPitchAlignment.VIEWPORT,
            textKeepUpright: true,
            textAnchor: TextAnchor.CENTER,
            textJustify: TextJustify.CENTER,
            textFont: ["Open Sans Bold", "Arial Unicode MS Bold"],
          ), LayerPosition(above: lyrId));
        }
      }
    }
  }

  

  // ── 4) Re‐draw the destination marker ───────────────────────────
  await deleteDestinationMarker();
  if (segments.isNotEmpty && segments.last.path.isNotEmpty) {
    await addDestinationMarker(segments.last.path.last);
  }
}

  // Option 1: Catmull-Rom spline interpolation for smooth polylines
  // List<LatLng> smoothPolyline(List<LatLng> points, {int samplesPerSegment = 8}) {
  //   if (points.length < 2) return points;
  //   List<LatLng> result = [];
  //   for (int i = 0; i < points.length - 1; i++) {
  //     LatLng p0 = i == 0 ? points[i] : points[i - 1];
  //     LatLng p1 = points[i];
  //     LatLng p2 = points[i + 1];
  //     LatLng p3 = (i + 2 < points.length) ? points[i + 2] : points[i + 1];
  //     for (int j = 0; j < samplesPerSegment; j++) {
  //       double t = j / samplesPerSegment;
  //       double t2 = t * t;
  //       double t3 = t2 * t;
  //       double lat = 0.5 * ((2 * p1.latitude) +
  //           (-p0.latitude + p2.latitude) * t +
  //           (2 * p0.latitude - 5 * p1.latitude + 4 * p2.latitude - p3.latitude) * t2 +
  //           (-p0.latitude + 3 * p1.latitude - 3 * p2.latitude + p3.latitude) * t3);
  //       double lng = 0.5 * ((2 * p1.longitude) +
  //           (-p0.longitude + p2.longitude) * t +
  //           (2 * p0.longitude - 5 * p1.longitude + 4 * p2.longitude - p3.longitude) * t2 +
  //           (-p0.longitude + 3 * p1.longitude - 3 * p2.longitude + p3.longitude) * t3);
  //       result.add(LatLng(lat, lng));
  //     }
  //   }
  //   result.add(points.last);
  //   return result;
  // }
  
  // Option 2: Chaikin spline smoothing
  List<LatLng> smoothPolyline(List<LatLng> points, {int iterations = 3}) {
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

  Future<void> deleteDestinationMarker() async {
    try {
      await mapboxMap.style.removeStyleLayer('destination-layer');
      await mapboxMap.style.removeStyleSource('destination-source');
    } catch (_) {}
  }
  Future<void> addDestinationMarker(LatLng destination) async {

    final destinationGeoJson = {
      "type": "FeatureCollection",
      "features": [
        {
          "type": "Feature",
          "geometry": {
            "type": "Point",
            "coordinates": [destination.longitude, destination.latitude],
          },
          "properties": {}
        }
      ]
    };

    await mapboxMap.style.addSource(GeoJsonSource(
      id: 'destination-source',
      data: jsonEncode(destinationGeoJson),
    ));

    // Option 1: Circle marker
    // await mapboxMap.style.addLayer(CircleLayer(
    //   id: 'destination-layer',
    //   sourceId: 'destination-source',
    //   circleRadius: 15.0,
    //   circleColor: Colors.red.value,
    //   circleStrokeColor: Colors.white.value,
    //   circleStrokeWidth: 4.0,
    // ));

    // Option 2: Symbol marker (if you have an icon)
    await mapboxMap.style.addLayer(SymbolLayer(
      id: 'destination-layer',
      sourceId: 'destination-source',
      iconImage: 'destination-marker', // You'd need to load this icon first
      iconSize: 0.75,
      iconAnchor: IconAnchor.BOTTOM,
    ));
  }

  Future<void> _updateAllMarkers() async {
    // recreate full initial set (will be trimmed by first camera-event)
    await pointAnnotationManager.deleteAll();
    _liveAnnotations.clear();
    await _addInteractiveMarkers(widget.markerAnnotations);
    pointAnnotationManager.addOnPointAnnotationClickListener(MarkerClickListener(_markerTapCallbacks));
  }

  /*────────────────────────  ZOOM-AWARE VISIBILITY  ────────────────────────*/
  /// Show only a subset of markers so that no two are too close (simple declutter)
  // Future<void> _updateMarkerVisibility(double zoom) async {
  //   // Debounce: only update every 200ms
  //   final now = DateTime.now();
  //   if (now.difference(_lastUpdate).inMilliseconds < 500) return;
  //   _lastUpdate = now;

  //   const minScreenDist = 10.0;

  //   final List<InteractiveAnnotation> all = List.from(widget.markerAnnotations);
  //   final List<InteractiveAnnotation> visible = [];
  //   final List<Offset> visibleScreenPoints = [];

  //   // Helper to get unique key for a marker
  //   String markerKey(InteractiveAnnotation a) {
  //     final c = a.options.geometry.coordinates;
  //     return '${c.lat},${c.lng}';
  //   }

  //   // Helper to get priority: lower value = lower priority (hidden first)
  //   int markerPriority(InteractiveAnnotation a) {
  //     final category = a.category.toLowerCase();
  //     if (category.contains('canteen') || category.contains('mensa')) return 0;
  //     if (category.contains('library')) return 1;
  //     if (category.contains('cafe')) return 2;
  //     return 3; // buildings or default
  //   }

  //   // Sort all markers by priority descending (higher priority last, so they are kept if crowded)
  //   all.sort((a, b) => markerPriority(a).compareTo(markerPriority(b)));

  //   // Detect zoom direction
  //   bool zoomingIn = _lastMarkerVisibilityZoom == null || zoom > _lastMarkerVisibilityZoom!;
  //   _lastMarkerVisibilityZoom = zoom;

  //   // Reset hidden buildings set when zooming in
  //   if (zoomingIn) {
  //     _hiddenBuildingsOnZoomOut.clear();
  //   }

  //   for (final ann in all) {
  //     final isBuilding = markerPriority(ann) == 3;
  //     final key = markerKey(ann);
  //     // If zoom <= 14 and this is a building, skip it and mark as hidden
  //     if (zoom <= 14 && isBuilding) {
  //       _hiddenBuildingsOnZoomOut.add(key);
  //       continue;
  //     }
  //     // If zooming out and this building was hidden, keep it hidden
  //     if (!zoomingIn && isBuilding && _hiddenBuildingsOnZoomOut.contains(key)) {
  //       continue;
  //     }
  //     final screenPos = await mapboxMap.pixelForCoordinate(
  //       Point(coordinates: Position(
  //         ann.options.geometry.coordinates.lng,
  //         ann.options.geometry.coordinates.lat,
  //       )),
  //     );
  //     final pt = Offset(screenPos.x, screenPos.y);
  //     bool tooClose = false;
  //     for (final other in visibleScreenPoints) {
  //       if ((pt - other).distance < minScreenDist) {
  //         tooClose = true;
  //         break;
  //       }
  //     }
  //     if (!tooClose) {
  //       visible.add(ann);
  //       visibleScreenPoints.add(pt);
  //     }
  //   }

  //   // Only update if visible set actually changed
  //   final newIds = visible.map(markerKey).toSet();
  //   bool setsEqual(Set<String> a, Set<String> b) => a.length == b.length && a.containsAll(b);
  //   if (newIds.isEmpty || setsEqual(newIds, _currentVisibleMarkerKeys)) return;
  //   await pointAnnotationManager.deleteAll();
  //   _addInteractiveMarkers(visible);
  //   var listener = MarkerClickListener(_markerTapCallbacks);
  //   pointAnnotationManager.addOnPointAnnotationClickListener(listener);
  //   _annotationsVisible = true;
  //   _currentVisibleMarkerKeys = newIds;
  // }

  // ── smart, diff-aware declutter ────────────────────────────────
  /*──────────────── helper – buffer grows smoothly with zoom ─────────────*/
double _minScreenDist(double zoom) {
  const zMax = 19.0, zMin = 11.0;
  const dMax = 350.0, dMin = 30.0;
  final t = ((zMax - zoom) / (zMax - zMin)).clamp(0.0, 1.0);
  return dMin + (dMax - dMin) * t;
}

/*──────────────── smart, one-way declutter ─────────────────────────────*/
Future<void> _updateMarkerVisibility(double zoom) async {
  final now = DateTime.now();
  if (now.difference(_lastUpdate).inMilliseconds < 250) return;
  _lastUpdate = now;

  final bool zoomingIn =
      _lastMarkerVisibilityZoom == null || zoom > _lastMarkerVisibilityZoom!;
  _lastMarkerVisibilityZoom = zoom;

  if (zoomingIn) {
    _hiddenThisZoomOut.clear();
  } else {
    _visibleThisZoomIn.clear();
  }

  final buffer = _minScreenDist(zoom);

  String keyOf(Position p) => '${p.lat},${p.lng}';
  int priorityOf(String cat) {
    final c = cat.toLowerCase();
    if (c.contains('canteen') || c.contains('mensa')) return 0;
    if (c.contains('library')) return 1;
    if (c.contains('cafe')) return 2;
    return 3;
  }

  if (zoomingIn) {
    final candidates = widget.markerAnnotations
        .where((a) =>
            !_liveAnnotations.containsKey(keyOf(a.options.geometry.coordinates)) &&
            !_hiddenThisZoomOut.contains(keyOf(a.options.geometry.coordinates)))
        .toList()
      ..sort((a, b) =>
          priorityOf(a.category).compareTo(priorityOf(b.category)));

    final List<InteractiveAnnotation> toAdd = [];
    final List<Offset> onScreen = [];

    for (final pa in _liveAnnotations.values) {
      final pt = await mapboxMap.pixelForCoordinate(pa.geometry);
      onScreen.add(Offset(pt.x, pt.y));
    }

    for (final ann in candidates) {
      final pt = await mapboxMap.pixelForCoordinate(
        Point(coordinates: Position(
          ann.options.geometry.coordinates.lng,
          ann.options.geometry.coordinates.lat,
        )),
      );
      final screenPt = Offset(pt.x, pt.y);

      bool crowded = false;
      for (final other in onScreen) {
        if ((screenPt - other).distance < buffer) {
          crowded = true;
          break;
        }
      }
      if (!crowded) {
        toAdd.add(ann);
        onScreen.add(screenPt);
      }
    }

    await _addInteractiveMarkers(toAdd);
    _visibleThisZoomIn.addAll(
        toAdd.map((a) => keyOf(a.options.geometry.coordinates)));
  } else {
    final work = _liveAnnotations.entries.toList()
      ..sort((a, b) {
        final catA = widget.markerAnnotations
            .firstWhere((x) => keyOf(x.options.geometry.coordinates) == a.key)
            .category;
        final catB = widget.markerAnnotations
            .firstWhere((x) => keyOf(x.options.geometry.coordinates) == b.key)
            .category;
        return priorityOf(catA).compareTo(priorityOf(catB));
      });

    final keep = <String>{};
    final keepScreen = <Offset>[];

    for (final entry in work) {
      final k = entry.key;
      if (_hiddenThisZoomOut.contains(k)) continue;
      final pt = await mapboxMap.pixelForCoordinate(entry.value.geometry);
      final screenPt = Offset(pt.x, pt.y);

      bool crowded = false;
      for (final other in keepScreen) {
        if ((screenPt - other).distance < buffer) {
          crowded = true;
          break;
        }
      }

      if (crowded) {
        await pointAnnotationManager.delete(entry.value);
        _liveAnnotations.remove(k);
        _hiddenThisZoomOut.add(k);
      } else {
        keep.add(k);
        keepScreen.add(screenPt);
      }
    }
  }

  pointAnnotationManager.addOnPointAnnotationClickListener(
    MarkerClickListener(_markerTapCallbacks),
  );
}

/* utility: coordinates → key */
String _markerKeyFromPoint(Position pos) => '${pos.lat},${pos.lng}';

  void _bindInteractions() {
    mapboxMap.setOnMapTapListener(
      (context) {
        widget.onMapTap(LatLng(context.point.coordinates.lat.toDouble(), context.point.coordinates.lng.toDouble()));
      },
    );
  }

  Future<void> _setupPositionTracking() async{
    bool serviceEnabled;
    gl.LocationPermission permission;
    
    serviceEnabled = await gl.Geolocator.isLocationServiceEnabled();

    if(!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await gl.Geolocator.checkPermission();
    if(permission == gl.LocationPermission.denied) {
      permission = await gl.Geolocator.requestPermission();
      if(permission == gl.LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == gl.LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied, we cannot request permissions.');
    }

    gl.LocationSettings locationsSettings = gl.LocationSettings(
      accuracy: gl.LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
      timeLimit: Duration(seconds: 5), // Update every 5 secondsv
    );

    userPositionStream?.cancel();
    userPositionStream = gl.Geolocator.getPositionStream(locationSettings: locationsSettings).listen((gl.Position? position){
      if(position != null){
        print(position);
      }
    });

    
  }

  void _onMapCreated(MapboxMap map) async {
    mapboxMap = map;
    _updateMapTheme();

    
    
    pointAnnotationManager = await mapboxMap.annotations.createPointAnnotationManager();
    polylineAnnotationManager = await mapboxMap.annotations.createPolylineAnnotationManager();

    await mapboxMap.setBounds(CameraBoundsOptions(
    minPitch: 0,    // Minimum tilt angle (degrees)
    maxPitch: 70,   // Maximum tilt angle (degrees), adjust as needed
    bounds: CoordinateBounds(
      southwest: 
        Point(
          coordinates: 
            Position(
              12.964, 
              52.313
            )
          ), 
          northeast: 
            Point(
              coordinates: 
                Position(13.826, 52.727)
            ), 
          infiniteBounds: false),
     maxZoom: 18.0,
  ));

  mapboxMap.compass.updateSettings(
      CompassSettings(
        enabled: true,
        clickable: true,
        position: OrnamentPosition.BOTTOM_RIGHT,
        marginLeft: 16.0,
        marginTop: 32.0,
        marginRight: 26.0,
        marginBottom: widget.navBarHeight + 90,
      )
    );

    mapboxMap.scaleBar.updateSettings(ScaleBarSettings(enabled: false));


    mapboxMap.location.updateSettings(LocationComponentSettings(
      enabled: true,
      pulsingEnabled: true,
      showAccuracyRing: true,
    ));    

  mapboxMap.style.addStyleImage(
    'destination-marker', 
    1.0, 
    MbxImage(width: 64, height: 64, data: widget.markerImageCache['destination']!),
    false, [], [], null);


    mapboxMap.style.setStyleImportConfigProperties("basemap", mapConfig);
    
    // var x = await mapboxMap.style.getStyleImportConfigProperties("basemap");
    // print("Style import config: ${x["lightPreset"]!.value as String}");
    // x["lightPreset"].toString();

    

    _addBuildingTapInteraction(); // Add building tap interaction

    // final initZoom = (await mapboxMap.getCameraState()).zoom;
    // await _updateMarkerVisibility(initZoom);

    widget.onMapCreated?.call(mapboxMap);
    setState(() {
      _isMapInitialized = true;
    });
    _bindInteractions();
  }

  void _addBuildingTapInteraction() {
    // Centralized highlight and zoom logic on building tap
    var buildingTap = TapInteraction(
      StandardBuildings(),
      (feature, event) async {
        await selectBuilding(feature, event);
      },
    );
    mapboxMap.addInteraction(buildingTap);
  }

  @override
  Widget build(BuildContext context) {
    
    return Stack(
      children:[ MapWidget(
        key: ValueKey("mapWidget"),
        cameraOptions: CameraOptions(
          center: Point(
            coordinates: Position(
              13.3269,
              52.5125,
            ),
          ),
          // pitch: 45.0,
          zoom: 15.0,
        ),
        onMapCreated: (map) {
          _onMapCreated(map);
        },
        onCameraChangeListener: widget.onCameraChanged,
      ),
      RainOverlay(isRaining: widget.isRaining),]
    );

    
  }
}


class MarkerClickListener implements OnPointAnnotationClickListener{
  final Map<String, VoidCallback> markerTapCallbacks;

  MarkerClickListener(this.markerTapCallbacks);

  @override
  Future<void> onPointAnnotationClick(PointAnnotation annotation) async {
    final callback = markerTapCallbacks[annotation.id];
    if (callback != null) {
      callback();
    }
  }
}

Future<List<InteractiveAnnotation>> _declutterMarkers(
    MapboxMap mapboxMap, List<InteractiveAnnotation> markers, double buffer) async {
  final List<InteractiveAnnotation> result = [];
  final List<Offset> screenPoints = [];

  for (final marker in markers) {
    final screenCoordinate = await mapboxMap.pixelForCoordinate(
      Point(coordinates: Position(
        marker.options.geometry.coordinates.lng,
        marker.options.geometry.coordinates.lat,
      )),
    );

    final screenPt = Offset(screenCoordinate.x, screenCoordinate.y);

    bool tooClose = false;
    for (final other in screenPoints) {
      if ((screenPt - other).distance < buffer) {
        tooClose = true;
        break;
      }
    }

    if (!tooClose) {
      result.add(marker);
      screenPoints.add(screenPt);
    }
  }

  return result;
}