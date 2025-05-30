import 'dart:convert';
import 'package:auth_app/data/models/get_menu_req_params.dart';
import 'package:auth_app/domain/usecases/get_mensa_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:auth_app/domain/usecases/find_route.dart';
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
import 'package:auth_app/domain/usecases/find_building_at_point.dart'; // Ensure this is imported
import 'package:geolocator/geolocator.dart'; // Add this import at the top
import 'package:flutter/animation.dart';  // ensure this is available
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart'
       as FMTC;


class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with TickerProviderStateMixin {
  bool _isFlyToActive = false;
  final MapController _mapController = MapController();
  AnimationController? _mapAnimController;  // <-- new field
  final TextEditingController _searchController = TextEditingController();
  List<Marker> _markers = [];
  List<LatLng> _path = [];
  List<Pointer> _allPointers = [];
  List<Pointer> _suggestions = [];
  LatLng? _currentLocation; // Add this line

  @override
  void initState() {
    super.initState();
    _loadBuildingMarkers();
    _searchController.addListener(_onSearchChanged);
    _goToCurrentLocation(); // <-- Add this line
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
    _mapAnimController?.dispose();         // <-- dispose animation controller
    _searchController.dispose();
    super.dispose();
  }

  // Loads the markers using the new JSON file which already contains centroid data.
  Future<void> _loadBuildingMarkers() async {
    try {
      final jsonStr = await rootBundle.loadString(
        'assets/campus_buildings_centroids.json',
      );
      final List data = jsonDecode(jsonStr);
      print('Loaded ${data.length} building centroids');

      // Store all pointers for search
      _allPointers =
          data.map((entry) {
            final double lat = (entry['latitude'] as num).toDouble();
            final double lng = (entry['longitude'] as num).toDouble();
            final String name = entry['name'] as String;
            final String category = entry['category'] as String? ?? 'Building';
            return Pointer(name: name, lat: lat, lng: lng, category: category);
          }).toList();

      // Create markers from all pointers
      final markers = _allPointers.map((pointer) {
        return Marker(
          point: LatLng(pointer.lat, pointer.lng),
          width: 40,
          height: 40,
          child: GestureDetector(
            // old:
            // onTap: () => _showPointPopup(context, pointer),

            // new:
            onTap: () => _onMapTap(LatLng(pointer.lat, pointer.lng)),
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
    final filtered = _allPointers
        .where((pointer) => 
            pointer.name.toLowerCase().contains(query.toLowerCase()))
        .toList();

    setState(() {
      _markers = MapMarkerManager.searchMarkersByName(
        allPointers: _allPointers,
        query: query,
        onMarkerTap: (String _, LatLng latlng) => _onMapTap(latlng),
      );
    });

    // Center map on first result
    MapMarkerManager.centerMapOnFilteredResults(
      mapController: _mapController,
      filtered: filtered
    );
  }

  /// Pops up a bottom sheet showing the building info and allows adding to favourites.
  void _showPointPopup(BuildContext context, Pointer pointer) {
    BuildingPopupManager.showBuildingPopup(context, pointer);
  }



  // FindRoute use case to fetch a route between Hauptgebäude and Mathegebäude.
  Future<void> _findRoute() async {
    // Coordinates for Hauptgebäude and Mathegebäude
    const double hauptLat = 52.5125;
    const double hauptLon = 13.3269;
    const double matheLat = 52.5135;
    const double matheLon = 13.3245;

    final params = FindRouteReqParams(
      fromLat: hauptLat,
      fromLon: hauptLon,
      toLat: matheLat,
      toLon: matheLon,
    );
    final findRouteUseCase = sl<FindRouteUseCase>();
    final result = await findRouteUseCase.call(param: params);
  }

  // /// Filters markers by category and updates the map - using our new utility class
  void _filterMarkersByCategory(String? category, Color? markerColor) {
    if (category == null) {
      // no filter → show all
      setState(() {
        _markers = _allPointers.map((pointer) {
          return Marker(
            point: LatLng(pointer.lat, pointer.lng),
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: () => _onMapTap(LatLng(pointer.lat, pointer.lng)),
              child: const Icon(Icons.location_on, color: Colors.deepPurple),
            ),
          );
        }).toList();
      });
      return;
    }

    // apply category filter
    final filtered = _allPointers
        .where((p) => p.category.toLowerCase() == category.toLowerCase())
        .toList();

    setState(() {
      _markers = MapMarkerManager.filterMarkersByCategory(
        allPointers: _allPointers,
        category: category,
        markerColor: markerColor!,
        onMarkerTap: (String _, LatLng latlng) => _onMapTap(latlng),
      );
    });
    MapMarkerManager.centerMapOnFilteredResults(
      mapController: _mapController,
      filtered: filtered,
    );
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

  // main map widget with markers and polylines
  Widget _buildFlutterMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: LatLng(52.5125, 13.3269),
        initialZoom: 17.0,
        maxZoom: 18.0,
        cameraConstraint: CameraConstraint.contain(
          bounds: LatLngBounds(LatLng(52.507, 13.317), LatLng(52.519, 13.335)),
        ),
        onTap: (tapPosition, latlng) => _onMapTap(latlng),
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),

        // cancel any ongoing fly‐to when user drags/pinches
        onPositionChanged: (pos, hasGesture) {
          // if the user gestures while flying → cancel once and forever
          if (hasGesture && _isFlyToActive) {
            _mapAnimController?.stop();
            _isFlyToActive = false;
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.app',
        ),
        if (_path.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(points: _path, color: Colors.blue, strokeWidth: 4.0),
            ],
          ),
        MarkerLayer(markers: [
          ..._markers,
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
        ]),
      ],
    );
  }

  // 'Find Route' button
  Widget _buildFindRouteButton() {
    return Positioned(
      bottom: 20,
      left: 20,
      child: ElevatedButton(
        onPressed: _findRoute,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'Find Route',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildCurrentLocationButton() {
    return Positioned(
      bottom: 20,
      right: 20,
      child: FloatingActionButton(
        // before: onPressed: _goToCurrentLocation,
        onPressed: () => _goToCurrentLocation(moveMap: true),  // <-- pass moveMap:true
        backgroundColor: Colors.white,
        child: const Icon(Icons.my_location, color: Colors.blue),
      ),
    );
  }

  void _onMapTap(LatLng latlng) async {
    // 1) Close any open bottom-sheet
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

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
        title: building.name,
        category: pointer.category,
        location: latlng,
        onClose: () => Navigator.of(context).pop(),
        onCreateRoute: () async {
          const double matheLat = 52.5135, matheLon = 13.3245;
          final params = FindRouteReqParams(
            fromLat: matheLat,
            fromLon: matheLon,
            toLat: latlng.latitude,
            toLon: latlng.longitude,
          );
          final result = await sl<FindRouteUseCase>().call(param: params);
          result.fold(
            (error) {
              ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('Error: $error')));
            },
            (route) {
              setState(() {
                _path = route.foot;
              });
              // 2) Safely pop only if the sheet is still there
              if (mounted && Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
          );
        },
      );
    } else {
      BuildingPopupManager.showBuildingOrCoordinatesPopup(
        context: context,
        latlng: latlng,
        buildingName: null,
        category: null,
        onCreateRoute: () async {
          const double matheLat = 52.5135, matheLon = 13.3245;
          final params = FindRouteReqParams(
            fromLat: matheLat,
            fromLon: matheLon,
            toLat: latlng.latitude,
            toLon: latlng.longitude,
          );
          final result = await sl<FindRouteUseCase>().call(param: params);
          result.fold(
            (error) {
              ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('Error: $error')));
            },
            (route) {
              setState(() => _path = route.foot);
              if (mounted && Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
          );
        },
        //onClose: () => Navigator.of(context).pop(),
      );
    }
  }

  void _onMarkerTap(String buildingName, LatLng latlng) {
    final pointer = _allPointers.firstWhere(
      (p) => p.name == buildingName,
      orElse: () => Pointer(
        name: buildingName,
        lat: latlng.latitude,
        lng: latlng.longitude,
        category: 'Building',
      ),
    );

    BuildingPopupManager.showBuildingSlideWindow(
      context: context,
      title: buildingName,
      category: pointer.category,
      location: latlng,
      onClose: () => Navigator.of(context).pop(),
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
        _currentLocation =
          LatLng(lastKnown.latitude, lastKnown.longitude);
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
      _currentLocation =
        LatLng(position.latitude, position.longitude);
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
    _isFlyToActive = true;       // start flying

    final latTween = Tween(
      begin: _mapController.camera.center.latitude,
      end: dest.latitude,
    );
    final lngTween = Tween(
      begin: _mapController.camera.center.longitude,
      end: dest.longitude,
    );
    final zoomTween = Tween(
      begin: _mapController.camera.zoom,
      end: destZoom,
    );

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

  // @override
  // void dispose() {
  //   _debounceTimer?.cancel();
  //   _searchController.dispose(); // Dispose controller
  //   super.dispose();
  // }
}
