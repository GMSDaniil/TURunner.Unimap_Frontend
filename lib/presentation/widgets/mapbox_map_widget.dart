import 'dart:async';
import 'dart:convert';

import 'package:auth_app/data/models/interactive_annotation.dart';
import 'package:auth_app/data/models/route_segment.dart';
import 'package:auth_app/presentation/widgets/route_options_sheet.dart';
import 'package:flutter/material.dart';
//import 'package:flutter_map/flutter_map.dart' hide MapOptions;
import 'package:geolocator/geolocator.dart'as gl;
import 'package:latlong2/latlong.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide LocationSettings;
import 'package:flutter/foundation.dart';

class MapboxMapWidget extends StatefulWidget {
  /// Annotations to show on the map
  final List<InteractiveAnnotation> markerAnnotations;
  /// Optional controller callback: parent can capture the unhighlight function to call when needed (e.g., when panel closes).
  final void Function(void Function())? onClearHighlightController;
  final double navBarHeight;
  //final List<Marker> busStopMarkers;
 // final List<Marker> scooterMarkers;
  final List<RouteSegment> segments;
  //final TileProvider cachedTileProvider;
  final Function(LatLng) onMapTap;
  final void Function(MapboxMap)? onMapCreated;
  final BuildContext parentContext;

  const MapboxMapWidget({
    Key? key,
    required this.markerAnnotations,
    required this.navBarHeight,
   // required this.busStopMarkers,
   // required this.scooterMarkers,
    required this.segments,
    //required this.cachedTileProvider,
    required this.onMapTap,
    required this.onMapCreated,
    this.onClearHighlightController,
    required this.parentContext,
    List<RouteSegment> routePoints = const [],
  }) : super(key: key);

  @override
  State<MapboxMapWidget> createState() => _MapBoxWidgetState();
}

class _MapBoxWidgetState extends State<MapboxMapWidget> {
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
      await mapboxMap.easeTo(
        CameraOptions(
          center: event.point,
          zoom: minZoom,
        ),
        MapAnimationOptions(duration: 500, startDelay: 0),
      );
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
    // Expose the canonical clear highlight function to the parent if requested
    if (widget.onClearHighlightController != null) {
      widget.onClearHighlightController!(unhighlightCurrentBuilding);
    }
    // No polling timer: marker visibility will update on camera events
  }
  final Map<String, VoidCallback> _markerTapCallbacks = {};
  late MapboxMap mapboxMap;
  late PointAnnotationManager pointAnnotationManager;
  late PolylineAnnotationManager polylineAnnotationManager;

  StreamSubscription? userPositionStream;
  dynamic _highlightedBuilding;

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
    // If the annotations list changed, update the map
    if (widget.markerAnnotations != oldWidget.markerAnnotations) {
      _updateAllMarkers();
      print("Updated markers");
    }

    if(widget.segments != oldWidget.segments) {
      drawStyledRouteSegments(widget.segments);
      print("Updated polylines");
    }
  }

  @override
    void dispose(){
      // No polling timer to cancel
      mapboxMap.dispose();
      userPositionStream?.cancel();
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
    // Remove old layers/sources if they exist
    for (var mode in TravelMode.values) {
      try {
        await mapboxMap.style.removeStyleLayer('route-layer-${mode.name}');
        await mapboxMap.style.removeStyleSource('route-source-${mode.name}');
      } catch (_) {}
    }

    for (final seg in segments) {
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
      if (seg.mode == TravelMode.bus) {
        color = const Color(0xFF0000FF).value;
        dashArray = null;
      } else if (seg.mode == TravelMode.scooter) {
        color = const Color(0xFFFFA500).value;
        dashArray = null;
      } else {
        // Walk: dotted line, pretty color
        color = Colors.greenAccent.shade700.value;
        dashArray = [1.5, 2.5];
      }

      final sourceId = 'route-source-${seg.mode.name}';
      final layerId = 'route-layer-${seg.mode.name}';

      await mapboxMap.style.addSource(GeoJsonSource(
        id: sourceId,
        data: jsonEncode(geojson),
      ));

      await mapboxMap.style.addLayer(LineLayer(
        id: layerId,
        sourceId: sourceId,
        lineColor: color,
        lineEmissiveStrength: 1.0,
        lineWidth: 5.0,
        lineDasharray: dashArray,
        lineCap: LineCap.ROUND,
        lineJoin: LineJoin.ROUND,
      ));
    }
  }
    
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

    await mapboxMap.setBounds(CameraBoundsOptions(
      minPitch: 0,
      maxPitch: 70,
      maxZoom: 18.0,
    ));

    mapboxMap.style.setStyleImportConfigProperties("basemap", {
      "showPointOfInterestLabels": false,
      "lightPreset": "day",
      "colorBuildingHighlight": "#B39DDB",
    });

    pointAnnotationManager = await mapboxMap.annotations.createPointAnnotationManager();
    polylineAnnotationManager = await mapboxMap.annotations.createPolylineAnnotationManager();

    _addBuildingTapInteraction(); // Add building tap interaction

    final initZoom = (await mapboxMap.getCameraState()).zoom;
    await _updateMarkerVisibility(initZoom);

    widget.onMapCreated?.call(mapboxMap);
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
    
    return MapWidget(
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
      onCameraChangeListener: (CameraChangedEventData data) async {
        final zoom = data.cameraState.zoom;
        if (_lastZoom != zoom) {
          _lastZoom = zoom;
          await _updateMarkerVisibility(zoom);
        }
      },
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