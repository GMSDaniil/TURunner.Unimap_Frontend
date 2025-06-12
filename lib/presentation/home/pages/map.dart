import 'dart:convert';
import 'package:auth_app/data/models/find_scooter_route_response.dart';
import 'package:auth_app/data/models/get_menu_req_params.dart';
import 'package:auth_app/data/models/route_data.dart';
import 'package:auth_app/data/models/route_segment.dart';
import 'package:auth_app/domain/usecases/find_bus_route.dart';
import 'package:auth_app/domain/usecases/find_scooter_route.dart';
import 'package:auth_app/domain/usecases/get_mensa_menu.dart';
import 'package:auth_app/domain/usecases/get_pointers_usecase.dart';
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
import 'package:auth_app/presentation/widgets/route_logic.dart';
import 'package:auth_app/presentation/widgets/map_widget.dart';

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
  final ValueNotifier<Map<TravelMode, RouteData>> _routesNotifier =
      ValueNotifier({});
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
        _suggestions = _allPointers
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
      // Use your usecase to get all pointers/buildings
      final pointers = await sl<GetPointersUseCase>().call();
      print('Loaded ${pointers.length} buildings');

      _allPointers = pointers;

      final markers = _allPointers.map((pointer) {
        return Marker(
          point: LatLng(pointer.lat, pointer.lng),
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => _onMarkerTap(pointer),
            child: Image.asset(
              getPinAssetForCategory(pointer.category),
              width: 40,
              height: 40,
            ),
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
    final filtered = _allPointers
        .where(
          (pointer) => pointer.name.toLowerCase().contains(query.toLowerCase()),
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

  Future<void> _handleCreateRoute(LatLng latlng) async {
    await RouteLogic.onCreateRoute(
      context: context,
      latlng: latlng,
      currentLocation: _currentLocation,
      routesNotifier: _routesNotifier,
      setState: setState,
      animatedMapMove: _animatedMapMove,
      mounted: mounted,
      currentMode: _currentMode,
      showRouteOptionsSheet: showRouteOptionsSheet,
      onModeChanged: (mode) async {
        print('Mode changed to: $mode');
        await _onModeChanged(mode, latlng);
      },
    );
  }

  Future<void> _onModeChanged(TravelMode mode, LatLng destination) async {
  return RouteLogic.onModeChanged(
    context: context,
    mode: mode,
    destination: destination,
    currentLocation: _currentLocation,
    routesNotifier: _routesNotifier,
    setState: setState,
    updateCurrentMode: (newMode) {
      setState(() {
        _currentMode = newMode;
      });
    },
  );
}

  // /// Filters markers by category and updates the map - using our new utility class
  void _filterMarkersByCategory(String? category, Color? markerColor) {
    setState(() {
      if (category == null) {
        // Show all markers if no category is selected
        _markers = _allPointers.map((pointer) {
          return Marker(
            point: LatLng(pointer.lat, pointer.lng),
            width: 35,
            height: 35,
            child: GestureDetector(
              onTap: () => _onMarkerTap(pointer),
              child: Image.asset(
                getPinAssetForCategory(pointer.category),
                width: 35,
                height: 35,
              ),
            ),
          );
        }).toList();
      } else {
        // Show only markers for the selected category
        _markers = _allPointers
            .where(
              (p) =>
                  p.category.trim().toLowerCase() ==
                  category.trim().toLowerCase(),
            )
            .map((pointer) {
              return Marker(
                point: LatLng(pointer.lat, pointer.lng),
                width: 40,
                height: 40,
                child: GestureDetector(
                  onTap: () => _onMarkerTap(pointer),
                  child: Image.asset(
                    getPinAssetForCategory(pointer.category),
                    width: 40,
                    height: 40,
                  ),
                ),
              );
            })
            .toList();
      }
    });

    // Optionally: Center map on filtered markers
    if (category != null) {
      final filtered = _allPointers
          .where(
            (p) =>
                p.category.trim().toLowerCase() ==
                category.trim().toLowerCase(),
          )
          .toList();
      if (filtered.isNotEmpty) {
        final bounds = LatLngBounds.fromPoints(
          filtered.map((p) => LatLng(p.lat, p.lng)).toList(),
        );
        _mapController.fitCamera(
          CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(40)),
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
        newPoints
          ..add(p0)
          ..add(q)
          ..add(r);
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
  // Get all your markers (e.g. _markers), busStopMarkers & scooterMarkers using your existing builder functions.
  final busStopMarkers = buildBusStopMarkers(
    segments: segments,
    closestPointCalculator: _closestPointOnPolyline,
  );
  final scooterMarkers = buildScooterMarkers(segments);

  return MapWidget(
    mapController: _mapController,
    markers: _markers,
    busStopMarkers: busStopMarkers,
    scooterMarkers: scooterMarkers,
    segments: segments,
    currentLocation: _currentLocation,
    cachedTileProvider: _cachedTileProvider,
    onMapTap: _onMapTap,
    parentContext: context,
  );
}

  Widget _buildCurrentLocationButton() {
    return Positioned(
      bottom: 20,
      right: 20,
      child: FloatingActionButton(
        // before: onPressed: _goToCurrentLocation,
        onPressed: () =>
            _goToCurrentLocation(moveMap: true), // <-- pass moveMap:true
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
        onClose: () {}, // ← was Navigator.of(context).pop()
        onCreateRoute: () async {
          await _handleCreateRoute(latlng);
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
          await _handleCreateRoute(latlng);
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
        await _handleCreateRoute(LatLng(pointer.lat, pointer.lng));
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

    _routeSheetController = widget.scaffoldKeyForBottomSheet.currentState
        ?.showBottomSheet(
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

  String getPinAssetForCategory(String category) {
    switch (category.trim().toLowerCase()) {
      case 'mensa':
      case 'canteen':
        return 'assets/icons/pin_mensa.png';
      case 'café':
      case 'cafe':
        return 'assets/icons/pin_cafe.png';
      case 'library':
        return 'assets/icons/pin_library.png';
      default:
        return 'assets/icons/pin_default.png'; // fallback
    }
  }
}
