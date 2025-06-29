import 'dart:async';
import 'dart:convert';

import 'package:auth_app/data/models/interactive_annotation.dart';
import 'package:auth_app/data/models/route_segment.dart';
import 'package:auth_app/presentation/widgets/route_options_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' hide MapOptions;
import 'package:geolocator/geolocator.dart'as gl;
import 'package:latlong2/latlong.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide LocationSettings;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MapboxMapWidget extends StatefulWidget {
  final List<InteractiveAnnotation> markerAnnotations;
  final List<Marker> busStopMarkers;
  final List<Marker> scooterMarkers;
  final List<RouteSegment> segments;
  final TileProvider cachedTileProvider;
  final Function(LatLng) onMapTap;
  final void Function(MapboxMap)? onMapCreated;
  final BuildContext parentContext;

  const MapboxMapWidget({
    Key? key,
    required this.markerAnnotations,
    required this.busStopMarkers,
    required this.scooterMarkers,
    required this.segments,
    required this.cachedTileProvider,
    required this.onMapTap,
    required this.onMapCreated,
    required this.parentContext,
    List<RouteSegment> routePoints = const [],
  }) : super(key: key);

  @override
  State<MapboxMapWidget> createState() => _MapBoxWidgetState();
}

class _MapBoxWidgetState extends State<MapboxMapWidget> {
  final Map<String, VoidCallback> _markerTapCallbacks = {};
  late MapboxMap mapboxMap;
  late PointAnnotationManager pointAnnotationManager;
  late PolylineAnnotationManager polylineAnnotationManager;

  StreamSubscription? userPositionStream;


  @override
  void initState() {
    super.initState();
    _setupPositionTracking();
  }

  @override
  void didUpdateWidget(covariant MapboxMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the annotations list changed, update the map
    if (widget.markerAnnotations != oldWidget.markerAnnotations && pointAnnotationManager != null) {
      _updateAllMarkers();
      print("Updated markers");
    }

    if(widget.segments != oldWidget.segments && polylineAnnotationManager != null) {
      drawStyledRouteSegments(widget.segments);
      print("Updated polylines");
    }
  }

  @override
    void dispose(){
      mapboxMap.dispose();
      userPositionStream?.cancel();
      super.dispose();
    }


  void _addInteractiveMarkers(List<InteractiveAnnotation> annotations) async {
      final options = annotations.map((a) => a.options).toList();
      final created = await pointAnnotationManager.createMulti(options);

      for (int i = 0; i < created.length; i++) {
        _markerTapCallbacks[created[i]!.id] = annotations[i].onTap;
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

  void _updateAllPolylines() async{
    await polylineAnnotationManager.deleteAll();
    final segmentLines = widget.segments.expand((seg) {
        final points = (seg.mode == TravelMode.bus && seg.precisePolyline != null)
            ? smoothPolyline(seg.precisePolyline!)
            : smoothPolyline(seg.path);

        
        return [
          PolylineAnnotationOptions(
            geometry: LineString(coordinates: points
                .map((p) => Position(p.longitude, p.latitude))
                .toList()
            ),
            
            
            lineColor: seg.mode == TravelMode.bus
                ? const Color.fromARGB(255, 162, 0, 255).value
                : seg.mode == TravelMode.scooter
                    ? const Color(0xFFFFA500).value
                    : Theme.of(context).primaryColor.value,
            lineWidth: 5.0,
            lineJoin: LineJoin.ROUND,
            // linePattern: "circle"
            
          )
        ];
      }).toList();

    await polylineAnnotationManager.createMulti(segmentLines);
    
  }

  void _updateAllMarkers() async {
      await pointAnnotationManager.deleteAll();
      
      // await _lineMgr?.createMulti(segmentLines);

      // All markers: bus stops, scooters, current location...
      // final allMarkerOptions = [
      //   ...widget.markers,
      //   ...widget.busStopMarkers,
      //   ...widget.scooterMarkers,
      //   if (widget.currentLocation != null)
      //     PointAnnotationOptions(
      //       geometry: Point(
      //         coordinates: Position(
      //           widget.currentLocation!.longitude,
      //           widget.currentLocation!.latitude,
      //         ),
      //       ),
      //       // Customize icon etc.
      //     ),
      // ];
      // await pointAnnotationManager.createMulti(allMarkerOptions);

      _addInteractiveMarkers(widget.markerAnnotations);

      var markerClickListener = MarkerClickListener(_markerTapCallbacks);

      pointAnnotationManager.addOnPointAnnotationClickListener(markerClickListener);


    }

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

    mapboxMap.style.setStyleImportConfigProperties("basemap",{
      "showPointOfInterestLabels" : false,
      "lightPreset": "day",
    });

    mapboxMap.compass.updateSettings(
      CompassSettings(
        enabled: true,
        clickable: true,
        position: OrnamentPosition.BOTTOM_RIGHT,
        marginLeft: 16.0,
        marginTop: 32.0,
        marginRight: 28.0,
        marginBottom: 174.0,
      )
    );

    mapboxMap.scaleBar.updateSettings(ScaleBarSettings(enabled: false));

    // Highlight selected building
    // var tapInteractionBuildings =
    //     TapInteraction(StandardBuildings(), (feature, pos) {
    //   mapboxMap.setFeatureStateForFeaturesetFeature(
    //       feature, StandardBuildingsState(highlight: true));
    //   widget.onMapTap(LatLng(pos.point.coordinates.lat.toDouble(), pos.point.coordinates.lng.toDouble()));
      
    // });
    // mapboxMap.addInteraction(tapInteractionBuildings);

    

    mapboxMap.location.updateSettings(LocationComponentSettings(
      enabled: true,
      pulsingEnabled: true,
      showAccuracyRing: true,
    ));

    // mapboxMap.style.setStyleImportConfigProperty("basemap", "showPointOfInterestLabels", false);
    pointAnnotationManager = await mapboxMap.annotations.createPointAnnotationManager();
    polylineAnnotationManager = await mapboxMap.annotations.createPolylineAnnotationManager();

    widget.onMapCreated?.call(mapboxMap);

    _bindInteractions();
    _updateAllMarkers();
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