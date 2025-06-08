import 'dart:convert';
import 'package:auth_app/data/models/find_scooter_route_response.dart';
import 'package:auth_app/data/models/get_menu_req_params.dart';
import 'package:auth_app/data/models/route_data.dart';
import 'package:auth_app/data/models/route_segment.dart';
import 'package:auth_app/domain/usecases/find_bus_route.dart';
import 'package:auth_app/domain/usecases/find_scooter_route.dart';
import 'package:auth_app/domain/usecases/get_mensa_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:auth_app/domain/usecases/find_walking_route.dart';
import 'package:auth_app/data/models/findroute_req_params.dart';
import 'package:auth_app/service_locator.dart';
import 'package:auth_app/data/models/pointer.dart';
import 'package:auth_app/data/favourites_manager.dart';
import 'package:auth_app/presentation/widgets/building_popup.dart'; // Make sure this is imported
import 'package:auth_app/presentation/widgets/building_popup_manager.dart';
import 'package:auth_app/presentation/widgets/building_slide_window.dart';
import 'package:auth_app/presentation/widgets/category_navigation.dart'
    show CategoryNavigationBar;
import 'package:auth_app/presentation/widgets/search_bar.dart';
import 'package:auth_app/presentation/widgets/map_marker_manager.dart';
import 'package:auth_app/core/configs/theme/app_theme.dart';
import 'package:auth_app/domain/usecases/find_building_at_point.dart'; // Ensure this is imported
import 'package:geolocator/geolocator.dart'; // Add this import at the top
import 'package:flutter/animation.dart'; // ensure this is available
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart' as FMTC;
import 'package:auth_app/presentation/widgets/route_options_sheet.dart';
import 'package:flutter_map/flutter_map.dart' show StrokePattern, PatternFit;

//import 'package:flutter_map/plugin_api.dart';
const double matheLat = 52.5135, matheLon = 13.3245;

class MapPage extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKeyForBottomSheet;

  const MapPage({super.key, required this.scaffoldKeyForBottomSheet});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with TickerProviderStateMixin {
  bool _isFlyToActive = false;
  final MapController _mapController = MapController();
  AnimationController? _mapAnimController; // <-- new field
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<Map<TravelMode, RouteData>> _routesNotifier = ValueNotifier({});
  TravelMode _currentMode = TravelMode.walk;

   // <-- new field

  List<Marker> _markers = [];
  List<Pointer> _allPointers = [];
  List<Pointer> _suggestions = [];
  LatLng? _currentLocation; // Add this line
  late final TileProvider _cachedTileProvider;

  PersistentBottomSheetController? _routeSheetController;

  @override
  void initState() {
    super.initState();
    _loadBuildingMarkers();
    _searchController.addListener(_onSearchChanged);
    _goToCurrentLocation(); // <-- Add this line

    // Browse‐cache strategy: read from mapStore, fetch missing from network & create
    _cachedTileProvider = FMTC.FMTCTileProvider(
      stores: {'mapStore': FMTC.BrowseStoreStrategy.readUpdateCreate},
    );
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _suggestions = [];
      } else {
        _suggestions =
            _allPointers
                .where((pointer) => pointer.name.toLowerCase().contains(query))
                .toList();
      }
    });
  }

  @override
  void dispose() {
    _mapAnimController?.dispose(); // <-- dispose animation controller
    _searchController.dispose();
    super.dispose();
  }

// Loads the markers using the new JSON file which already contains centroid data.
  Future<void> _loadBuildingMarkers() async {
    try {
      final jsonStr = await rootBundle.loadString(
        'assets/campus_buildings.json',
      );
      final List data = jsonDecode(jsonStr);
      print('Loaded ${data.length} buildings');

      // Store all pointers for search
      _allPointers =
          data.map((entry) {
            final double lat = (entry['Latitude'] as num).toDouble();
            final double lng = (entry['Longitude'] as num).toDouble();
            final String name = entry['Name'] as String;
            final String category = entry['Category'] as String? ?? 'Building';
            return Pointer(name: name, lat: lat, lng: lng, category: category);
          }).toList();

      // Create markers from all pointers
      final markers =
          _allPointers.map((pointer) {
            return Marker(
              point: LatLng(pointer.lat, pointer.lng),
              width: 40,
              height: 40,
              child: GestureDetector(
                onTap: () => _onMarkerTap(pointer), // <-- Use pointer directly
                child: const Icon(Icons.location_on, color: Colors.deepPurple),
              ),
            );
          }).toList();

      setState(() {
        _markers = markers;
      });

      print('Markers updated: ${markers.length} markers added.');
    } catch (e) {
      print('Error loading building markers: $e');
    }
  }

  // Search logic: filter markers by name - this can be simplified using our new utility
  void _searchMarkers(String query) {
    final filtered =
        _allPointers
            .where(
              (pointer) =>
                  pointer.name.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();

    setState(() {
      _markers = MapMarkerManager.searchMarkersByName(
        allPointers: _allPointers,
        query: query,
        onMarkerTap: (Pointer pointer) => _onMarkerTap(pointer),
      );
    });

    // Center map on first result
    MapMarkerManager.centerMapOnFilteredResults(
      mapController: _mapController,
      filtered: filtered,
    );
  }

  Future<void> onCreateRoute(LatLng latlng) async {
    
    final params = FindRouteReqParams(
      fromLat: _currentLocation?.latitude ?? matheLat, // Default to Hauptgebäude
      fromLon: _currentLocation?.longitude ?? matheLon,
      toLat: latlng.latitude,
      toLon: latlng.longitude,
    );
    final result = await sl<FindWalkingRouteUseCase>().call(param: params);
    result.fold(
      (error) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $error')));
      },
      (route) {
        setState(() {
          _routesNotifier.value[TravelMode.walk] = RouteData(
            segments: [
              RouteSegment(
                mode: TravelMode.walk,
                path: route.foot,
                distanceMeters: route.distanceMeters,
                durrationSeconds: route.durationSeconds,
          ),
          ],
          );
          _currentMode = TravelMode.walk;
        });
        // pop the building sheet
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        // fit map to show entire route
        final walkRoute = _routesNotifier.value[TravelMode.walk];
        final walkPath = walkRoute?.segments.first.path ?? [];
        if (walkPath.isNotEmpty) {
          final bounds = LatLngBounds.fromPoints(walkPath);
          _animatedMapMove(bounds.center, 16.5);
        }
        // show persistent, interactive route‐options sheet
        showRouteOptionsSheet(
          routesNotifier: _routesNotifier,
          currentMode: _currentMode,
          onModeChanged: (mode) async{
            print('Mode changed to: $mode');
            await _onModeChanged(mode, latlng);
             
          },
          onClose: () {
            // Close the bottom sheet
            setState(() {
              _routesNotifier.value.clear();
            });
            if (mounted && Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        );
      },
    );
  }

Future<void> _onModeChanged(TravelMode mode, LatLng destination) async {
  if (_routesNotifier.value.containsKey(mode)) {
    setState(() {
      _currentMode = mode;
    });
    return;
  }

  if (mode == TravelMode.bus) {
    final params = FindRouteReqParams(
      fromLat: _currentLocation?.latitude ?? matheLat,
      fromLon: _currentLocation?.longitude ?? matheLon,
      toLat: destination.latitude,
      toLon: destination.longitude,
    );
    final result = await sl<FindBusRouteUseCase>().call(param: params);

    result.fold(
      (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      },
      (route) {
        // Build segments from the bus response (using Segments array)
        final segments = <RouteSegment>[];
        for (final seg in route.segments) {
          segments.add(
            RouteSegment(
              mode: seg.type == 'walk' ? TravelMode.walk : TravelMode.bus,
              path: seg.polyline,
              distanceMeters: seg.distanceMeters,
              durrationSeconds: seg.durationSeconds,
              precisePolyline: seg.precisePolyline,
              transportType: seg.transportType,
              transportLine: seg.transportLine,
              fromStop: seg.fromStop,
              toStop: seg.toStop,
              
            ),
          );
          
        }

        setState(() {
          final newMap = Map<TravelMode, RouteData>.from(_routesNotifier.value);
          newMap[TravelMode.bus] = RouteData(segments: segments);
          _routesNotifier.value = newMap;
          _currentMode = TravelMode.bus;
        });
      },
    );
  }

  else if (mode == TravelMode.scooter) {
    final params = FindRouteReqParams(
      fromLat: _currentLocation?.latitude ?? matheLat,
      fromLon: _currentLocation?.longitude ?? matheLon,
      toLat: destination.latitude,
      toLon: destination.longitude,
    );
    final result = await sl<FindScooterRouteUseCase>().call(param: params);

    result.fold(
      (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      },
      (response) {
        // If your backend returns a list of segments:
        // final segments = FindScooterRouteResponse.fromSegmentsList(response);
        // If your backend returns a wrapped object:

        final segments = response.segments.map((seg) => RouteSegment(
          mode: seg.type.toLowerCase() == 'walking'
              ? TravelMode.walk
              : TravelMode.scooter,
          path: seg.polyline,
          distanceMeters: seg.distanceMeters,
          durrationSeconds: seg.durationSeconds,
        )).toList();

        setState(() {
          final newMap = Map<TravelMode, RouteData>.from(_routesNotifier.value);
          newMap[TravelMode.scooter] = RouteData(segments: segments);
          _routesNotifier.value = newMap;
          _currentMode = TravelMode.scooter;
        });
      },
    );
  }
}

  // /// Filters markers by category and updates the map - using our new utility class
  void _filterMarkersByCategory(String? category, Color? markerColor) {
    setState(() {
      _markers = MapMarkerManager.allMarkersWithHighlight(
        allPointers: _allPointers,
        highlightedCategory: category,
        highlightColor: markerColor,
        onMarkerTap: (Pointer pointer) => _onMarkerTap(pointer),
      );
    });

    if (category != null) {
      final filtered = _allPointers
          .where((p) => p.category.toLowerCase() == category.toLowerCase())
          .toList();
      if (filtered.isNotEmpty) {
        final bounds = LatLngBounds.fromPoints(
          filtered.map((p) => LatLng(p.lat, p.lng)).toList(),
        );
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.all(40),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildFlutterMap(),
          MapSearchBar(
            searchController: _searchController,
            suggestions: _suggestions,
            onSearch: (value) {
              _searchMarkers(value);
              setState(() => _suggestions = []);
            },
            onClear: () {
              _searchController.clear();
              setState(() => _suggestions = []);
            },
            onCategorySelected: _filterMarkersByCategory,
            onSuggestionSelected: (pointer) {
              final target = LatLng(pointer.lat, pointer.lng);
              // animate map move & zoom smoothly
              _animatedMapMove(target, 18.0);
              // then open detail sheet
              _onMapTap(target);
            },
          ),
          _buildCurrentLocationButton(),
        ],
      ),
    );
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

  // main map widget with markers and polylines
  Widget _buildFlutterMap() {
    final route = _routesNotifier.value[_currentMode];
    final segments = route?.segments ?? [];
    final allPoints = <LatLng>[
      for (final seg in segments) ...seg.path,
    ];

    // Helper to find the closest point on the polyline to a stop
    LatLng _closestPointOnPolyline(LatLng stop, List<LatLng> polyline) {
      double minDist = double.infinity;
      LatLng closest = polyline.first;
      for (final p in polyline) {
        final d = Distance().as(LengthUnit.Meter, stop, p);
        if (d < minDist) {
          minDist = d;
          closest = p;
        }
      }
      return closest;
    }

    final busStopMarkers = <Marker>[];
    for (final seg in segments) {
      if (seg.mode == TravelMode.bus && seg.precisePolyline != null) {
        for (final stop in seg.path) {
          // Find the closest point on the precise polyline to the stop
          final markerPoint = _closestPointOnPolyline(stop, seg.precisePolyline!);
          busStopMarkers.add(
            Marker(
              point: markerPoint,
              width: 18,
              height: 18,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.blue.shade700,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      }
    }

    final scooterMarkers = <Marker>[];
    for (final seg in segments) {
      if (seg.mode == TravelMode.scooter && seg.path.isNotEmpty) {
        scooterMarkers.add(
          Marker(
            point: seg.path.first,
            width: 38,
            height: 38,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.orange.shade700,
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.directions_bike,
                  color: Colors.orange.shade700,
                  size: 20,
                ),
              ),
            ),
          ),
        );
      }
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: LatLng(52.5125, 13.3269),
        initialZoom: 17.0,
        minZoom: 15.0, // prevent zooming out below campus level
        maxZoom: 18.0, // prevent zooming in beyond detail level
        cameraConstraint: CameraConstraint.contain(
          bounds: LatLngBounds(LatLng(52.507, 13.317), LatLng(52.519, 13.335)),
        ),
        // disable all rotation gestures
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
        backgroundColor: Colors.grey.shade200,
        onTap: (tapPos, latlng) => _onMapTap(latlng),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.app',
          tileProvider: _cachedTileProvider,
        ),
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
                        ? Colors.orange // Use orange for scooter
                        : Theme.of(context).primaryColor,
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

        MarkerLayer(
          markers: [
            ..._markers,
            ...busStopMarkers,
            ...scooterMarkers,
            if (_currentLocation != null)
              Marker(
                point: _currentLocation!,
                width: 40,
                height: 40,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer circle (more opaque)
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                    ),
                    // Inner circle
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


  Widget _buildCurrentLocationButton() {
    return Positioned(
      bottom: 20,
      right: 20,
      child: FloatingActionButton(
        // before: onPressed: _goToCurrentLocation,
        onPressed:
            () => _goToCurrentLocation(moveMap: true), // <-- pass moveMap:true
        backgroundColor: Colors.white,
        child: const Icon(Icons.my_location, color: Colors.blue),
      ),
    );
  }

  void _onMapTap(LatLng latlng) async {
    if (_routeSheetController != null) {
      
      return;
    }
    // Remove this to prevent closing your signed-in page:
    // if (Navigator.of(context).canPop()) {
    //   Navigator.of(context).pop();
    // }

    final findBuildingAtPoint = sl<FindBuildingAtPoint>();
    final building = await findBuildingAtPoint.call(latlng);

    if (building != null) {
      final pointer = _allPointers.firstWhere(
        (p) => p.name == building.name,
        orElse: () => Pointer(
          name: building.name,
          lat: latlng.latitude,
          lng: latlng.longitude,
          category: 'Building',
        ),
      );

      BuildingPopupManager.showBuildingSlideWindow(
        context: context,
        scaffoldKey: widget.scaffoldKeyForBottomSheet,
        title: building.name,
        category: pointer.category,
        location: latlng,
        onClose: () {},                // ← was Navigator.of(context).pop()
        onCreateRoute: () async {
          await onCreateRoute(latlng);
        },
      );
    } else {
      BuildingPopupManager.showBuildingOrCoordinatesPopup(
        context: context,
        scaffoldKey: widget.scaffoldKeyForBottomSheet, // ← NEW
        latlng: latlng,
        buildingName: null,
        category: null,
        onCreateRoute: () async {
          await onCreateRoute(latlng);
        },
        //onClose: () => Navigator.of(context).pop(),
      );
    }
  }

  void _onMarkerTap(Pointer pointer) async {
    // Close any open popup/bottom sheet first
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      // Wait a frame to ensure the old popup is closed before opening a new one
      await Future.delayed(const Duration(milliseconds: 50));
    }

    // Zoom in on this marker
    _animatedMapMove(LatLng(pointer.lat, pointer.lng), 18.0);

    // Show the popup for this pointer
    BuildingPopupManager.showBuildingSlideWindow(
      context: context,
      scaffoldKey: widget.scaffoldKeyForBottomSheet,
      title: pointer.name,
      category: pointer.category,
      location: LatLng(pointer.lat, pointer.lng),
      onCreateRoute: () async {
        await onCreateRoute(LatLng(pointer.lat, pointer.lng));
      },
      onClose: () {},
    );
  }

  Future<void> _goToCurrentLocation({bool moveMap = false}) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    // Try to get last known position first (fast)
    final lastKnown = await Geolocator.getLastKnownPosition();
    if (lastKnown != null) {
      if (!mounted) return;
      setState(() {
        _currentLocation = LatLng(lastKnown.latitude, lastKnown.longitude);
      });
      if (moveMap) {
        final currentZoom = _mapController.camera.zoom;
        final zoom = currentZoom < 17.0 ? 17.0 : currentZoom;
        _animatedMapMove(_currentLocation!, zoom);
      }
    }

    // Then get the current position (may take longer)
    final position = await Geolocator.getCurrentPosition();
    if (!mounted) return;
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
    });
    if (moveMap) {
      final currentZoom = _mapController.camera.zoom;
      final zoom = currentZoom < 17.0 ? 17.0 : currentZoom;
      _animatedMapMove(_currentLocation!, zoom);
    }
  }

  // <-- new helper to animate center & zoom
  void _animatedMapMove(LatLng dest, double destZoom) {
    // dispose any old one
    _mapAnimController?.dispose();

    // new controller
    _mapAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _isFlyToActive = true; // start flying

    final latTween = Tween(
      begin: _mapController.camera.center.latitude,
      end: dest.latitude,
    );
    final lngTween = Tween(
      begin: _mapController.camera.center.longitude,
      end: dest.longitude,
    );
    final zoomTween = Tween(begin: _mapController.camera.zoom, end: destZoom);

    final anim = CurvedAnimation(
      parent: _mapAnimController!,
      curve: Curves.easeInOut,
    );

    anim.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(anim), lngTween.evaluate(anim)),
        zoomTween.evaluate(anim),
      );
    });

    // when the fly-to finishes naturally, clear the flag
    _mapAnimController!.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        _isFlyToActive = false;
      }
    });

    _mapAnimController!.forward();
  }

  /// Shows a persistent (non-modal) bottom sheet so the map remains interactive.
void showRouteOptionsSheet({
  required ValueNotifier<Map<TravelMode, RouteData>> routesNotifier,
  required TravelMode currentMode,
  required ValueChanged<TravelMode> onModeChanged,
  required VoidCallback onClose,
}) {
  // If already open, do nothing or close the previous one first
  if (_routeSheetController != null) return;

  _routeSheetController = widget.scaffoldKeyForBottomSheet.currentState?.showBottomSheet(
    (ctx) => RouteOptionsSheet(
      routesNotifier: routesNotifier,
      currentMode: currentMode,
      onClose: onClose,
      onModeChanged: onModeChanged,
    ),
    backgroundColor: Colors.transparent,
    elevation: 0,
  );

  _routeSheetController?.closed.then((_) {
    _routeSheetController = null; // Reset when closed
    onClose();
  });
}

}
