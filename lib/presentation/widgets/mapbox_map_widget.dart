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

final List<String> markers = [
  'mensa',
  'library',
  'cafe',
  'default',
  'destination', 
];

class MapboxMapWidget extends StatefulWidget {
  /// Annotations to show on the map
  final List<InteractiveAnnotation> markerAnnotations;
  final Map<String, Uint8List> markerImageCache;
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
    required this.markerImageCache,
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
  // Centralized method for selecting and highlighting a building, with zoom logic
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
    // Always de-highlight previous
    await unhighlightCurrentBuilding();
    // Highlight new building
    await mapboxMap.setFeatureStateForFeaturesetFeature(
      feature, StandardBuildingsState(highlight: true),
    );
    _highlightedBuilding = feature;
    // Forward tap to parent
    widget.onMapTap(LatLng(
      event.point.coordinates.lat.toDouble(),
      event.point.coordinates.lng.toDouble(),
    ));
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
  Future<void> unhighlightCurrentBuilding() async {
    if (_highlightedBuilding != null) {
      await mapboxMap.setFeatureStateForFeaturesetFeature(
        _highlightedBuilding, StandardBuildingsState(highlight: false),
      );
      _highlightedBuilding = null;
    }
  }

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
  // Remove old layers/sources if they exist - remove ALL route layers/sources
  try {
    final allLayerIds = await mapboxMap.style.getStyleLayers();
    final allSourceIds = await mapboxMap.style.getStyleSources();
    
    for (final layerId in allLayerIds) {
      if (layerId!.id.startsWith('route-layer-')) {
        try {
          await mapboxMap.style.removeStyleLayer(layerId.id);
        } catch (_) {}
      }
    }
    
    for (final sourceId in allSourceIds) {
      if (sourceId!.id.startsWith('route-source-')) {
        try {
          await mapboxMap.style.removeStyleSource(sourceId.id);
        } catch (_) {}
      }
    }
  } catch (e) {
    print('Error cleaning up old routes: $e');
  }

  // Add each segment with unique ID
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
    if (seg.mode == TravelMode.bus) {
      color = const Color(0xFF0000FF).value;
      dashArray = null;
    } else if (seg.mode == TravelMode.scooter) {
      color = const Color(0xFFFFA500).value;
      dashArray = null;
    } else {
      color = const Color.fromARGB(255, 2, 121, 201).value;
      dashArray = [0.5, 2.0]; // Better dots for walking
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
        lineWidth: seg.mode == TravelMode.walk ? 4.0 : 5.0,
        lineDasharray: dashArray,
        lineCap: LineCap.ROUND,
        lineJoin: LineJoin.ROUND,
      ));
    } catch (e) {
      print('Error adding route segment $i (${seg.mode.name}): $e');
    }
  }

  await deleteDestinationMarker();
  if (segments.isNotEmpty && segments.last.path.isNotEmpty) {
    await addDestinationMarker(segments.last.path.last);
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
      iconSize: 1.5,
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
  Future<void> _updateMarkerVisibility(double zoom) async {
    // Debounce: only every ~300 ms
    final now = DateTime.now();
    if (now.difference(_lastUpdate).inMilliseconds < 300) return;
    _lastUpdate = now;

    const minScreenDist = 200.0;

    final List<InteractiveAnnotation> all = List.from(widget.markerAnnotations);
    final List<InteractiveAnnotation> visible   = [];
    final List<Offset>                screens   = [];

    /* helpers */
    String markerKey(InteractiveAnnotation a) =>
        _markerKeyFromPoint(a.options.geometry.coordinates);

    // Helper to get priority: lower value = lower priority (hidden first)
    int markerPriority(InteractiveAnnotation a) {
      final category = a.category.toLowerCase();
      if (category.contains('canteen') || category.contains('mensa')) return 0;
      if (category.contains('library')) return 1;
      if (category.contains('cafe')) return 2;
      return 3; // buildings or default
    }

    // Sort markers by priority (lower number = higher priority)
    all.sort((a, b) => markerPriority(a).compareTo(markerPriority(b)));

    /*──────── detect direction … ────────*/
    final bool zoomingIn =
        _lastMarkerVisibilityZoom == null || zoom > _lastMarkerVisibilityZoom!;
    _lastMarkerVisibilityZoom = zoom;

    /*──────── reset caches when direction flips ──────*/
    if (zoomingIn) {
      _hiddenThisZoomOut.clear();          // we’re done zooming-out
    } else {
      _visibleThisZoomIn.clear();          // we’re done zooming-in
    }

    /*────────────────────────
     *  ZOOM-IN  →  only ADD
     *───────────────────────*/
    if (zoomingIn) {
      // build a list of candidates that are NOT yet visible
      for (final ann in all) {
        final key = markerKey(ann);
        if (_liveAnnotations.containsKey(key)) continue; // already there
        if (_hiddenThisZoomOut.contains(key)) continue;  // still banned

        // keep simple spacing rule against *currently* visible pins
        final screenPos = await mapboxMap.pixelForCoordinate(
          Point(coordinates: Position(
            ann.options.geometry.coordinates.lng,
            ann.options.geometry.coordinates.lat,
          )),
        );
        final pt = Offset(screenPos.x, screenPos.y);
        bool tooClose = false;
        for (final other in screens) {
          if ((pt - other).distance < minScreenDist) {
            tooClose = true;
            break;
          }
        }
        if (tooClose) continue;

        visible.add(ann);
        screens.add(pt);
      }

      // **add** the new ones
      await _addInteractiveMarkers(visible);
      _visibleThisZoomIn.addAll(
          visible.map((a) => markerKey(a)));         // remember for session
    }

    /*────────────────────────
     *  ZOOM-OUT → only REMOVE
     *───────────────────────*/
    else {
      // decide which **currently visible** pins must go
      final toRemove = <String>[];
      for (final entry in _liveAnnotations.entries) {
        final key = entry.key;
        // once hidden in *this* zoom-out → skip
        if (_hiddenThisZoomOut.contains(key)) continue;

        // simple example rule: buildings below z14
        final parts = key.split(',');
        final isBuilding = parts.length == 2
            ? true
            : false; // your own logic if needed

        if (zoom <= 14 && isBuilding) {
          toRemove.add(key);
          _hiddenThisZoomOut.add(key); // remember ban until next zoom-in
        }
      }
      for (final k in toRemove) {
        final ann = _liveAnnotations[k];
        if (ann != null) await pointAnnotationManager.delete(ann);
        _liveAnnotations.remove(k);
      }
    }

    // 3) keep Tap-listener once (safe to re-add)
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

    // Camera event listener moved to MapWidget's build method (onCameraChanged)

    await mapboxMap.setBounds(CameraBoundsOptions(
    minPitch: 0,    // Minimum tilt angle (degrees)
    maxPitch: 70,   // Maximum tilt angle (degrees), adjust as needed
     maxZoom: 18.0,
  ));

  mapboxMap.style.addStyleImage(
    'destination-marker', 
    1.0, 
    MbxImage(width: 64, height: 64, data: widget.markerImageCache['destination']!),
    false, [], [], null);


    mapboxMap.style.setStyleImportConfigProperties("basemap",{
      "showPointOfInterestLabels" : false,
      "lightPreset": "day",
      "colorBuildingHighlight": "#B39DDB", // light purple
    });

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

    // mapboxMap.setBounds(CameraBoundsOptions(
    //   bounds: CoordinateBounds(
    //     southwest: Point(coordinates: Position(13.316, 52.502)), 
    //     northeast: Point(coordinates: Position(13.34, 52.523)), 
    //     infiniteBounds: false,
    //   ),
    // ));

    mapboxMap.scaleBar.updateSettings(ScaleBarSettings(enabled: false));

    // Highlight selected building
    // var tapInteractionBuildings =
    //     TapInteraction(StandardBuildings(), (feature, pos) {
    //   mapboxMap.setFeatureStateForFeaturesetFeature(
    //       feature, StandardBuildingsState(highlight: true));
    //   widget.onMapTap(LatLng(pos.point.coordinates.lat.toDouble(), pos.point.coordinates.lng.toDouble()));
      
    // });
    // mapboxMap.addInteraction(tapInteractionBuildings);

    _addBuildingTapInteraction();

    mapboxMap.location.updateSettings(LocationComponentSettings(
      enabled: true,
      pulsingEnabled: true,
      showAccuracyRing: true,
    ));

    /*─────────── initial-visibility + live listener ────────────*/
    final initZoom = (await mapboxMap.getCameraState()).zoom;
    _updateMarkerVisibility(initZoom);
    // Camera idle listener now handled via MapWidget's onCameraIdle property in build()

    // mapboxMap.style.setStyleImportProperty("basemap", "showPointOfInterestLabels", false);
    pointAnnotationManager = await mapboxMap.annotations.createPointAnnotationManager();
    polylineAnnotationManager = await mapboxMap.annotations.createPolylineAnnotationManager();

    widget.onMapCreated?.call(mapboxMap);

    _bindInteractions();
    _updateAllMarkers();
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