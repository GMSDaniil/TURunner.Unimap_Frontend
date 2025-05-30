import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart'
    as FMTC;
import 'package:latlong2/latlong.dart';
import 'package:auth_app/domain/usecases/find_route.dart';
import 'package:auth_app/data/models/findroute_req_params.dart';
import 'package:auth_app/service_locator.dart';
import 'package:auth_app/data/models/pointer.dart';
import 'package:auth_app/presentation/widgets/building_popup_manager.dart';
import 'package:auth_app/presentation/widgets/search_bar.dart';
import 'package:auth_app/presentation/widgets/map_marker_manager.dart';
import 'package:auth_app/domain/usecases/find_building_at_point.dart';
import 'package:geolocator/geolocator.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with TickerProviderStateMixin {
  bool _isFlyToActive = false;
  final MapController _mapController = MapController();
  AnimationController? _mapAnimController;
  final TextEditingController _searchController = TextEditingController();
  List<Marker> _markers = [];
  List<LatLng> _path = [];
  List<Pointer> _allPointers = [];
  List<Pointer> _suggestions = [];
  LatLng? _currentLocation;
  late final TileProvider _cachedTileProvider;

  // Animation system for bouncing markers
  AnimationController? _bounceAnimationController;
  late Animation<double> _bounceAnimation;
  LatLng? _selectedMarkerPosition;
  bool _isAnimationActive = false;

  @override
  void initState() {
    super.initState();
    _loadBuildingMarkers();
    _searchController.addListener(_onSearchChanged);
    _goToCurrentLocation();

    // Initialize bouncing animation
    _bounceAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _bounceAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _bounceAnimationController!,
      curve: Curves.elasticOut,
    ));

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
    _mapAnimController?.dispose();
    _bounceAnimationController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Unified handler for marker selection that handles animation and bottom sheet
  void _handleMarkerSelection(LatLng position) {
    setState(() {
      _selectedMarkerPosition = position;
      _isAnimationActive = true;
    });
    
    // Start bounce animation
    _bounceAnimationController?.reset();
    _bounceAnimationController?.forward();
    
    // Call existing map tap logic
    _onMapTap(position);
  }

  /// Builds marker icon with animation and color based on selection state
  Widget _buildMarkerIcon(LatLng position) {
    final isSelected = _selectedMarkerPosition == position;
    final color = isSelected ? Colors.red : Colors.deepPurple;
    
    if (isSelected && _isAnimationActive) {
      return AnimatedBuilder(
        animation: _bounceAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _bounceAnimation.value,
            child: Icon(
              Icons.location_on,
              color: color,
              size: 30,
            ),
          );
        },
      );
    }
    
    return Icon(
      Icons.location_on,
      color: color,
      size: 30,
    );
  }

  /// Resets marker animation and selection state
  void _resetMarkerSelection() {
    setState(() {
      _selectedMarkerPosition = null;
      _isAnimationActive = false;
    });
    _bounceAnimationController?.reset();
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

      // Create markers from all pointers using the unified handler
      final markers = _allPointers.map((pointer) {
        final position = LatLng(pointer.lat, pointer.lng);
        return Marker(
          point: position,
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => _handleMarkerSelection(position),
            child: _buildMarkerIcon(position),
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

    // Create filtered markers with unified handler
    final filteredMarkers = filtered.map((pointer) {
      final position = LatLng(pointer.lat, pointer.lng);
      return Marker(
        point: position,
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () => _handleMarkerSelection(position),
          child: _buildMarkerIcon(position),
        ),
      );
    }).toList();

    setState(() {
      _markers = filteredMarkers;
    });

    // Center map on first result
    MapMarkerManager.centerMapOnFilteredResults(
      mapController: _mapController,
      filtered: filtered
    );
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
      // no filter → show all markers with unified handler
      setState(() {
        _markers = _allPointers.map((pointer) {
          final position = LatLng(pointer.lat, pointer.lng);
          return Marker(
            point: position,
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: () => _handleMarkerSelection(position),
              child: _buildMarkerIcon(position),
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

    // Create filtered markers with unified handler
    final filteredMarkers = filtered.map((pointer) {
      final position = LatLng(pointer.lat, pointer.lng);
      return Marker(
        point: position,
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () => _handleMarkerSelection(position),
          child: _buildMarkerIcon(position),
        ),
      );
    }).toList();

    setState(() {
      _markers = filteredMarkers;
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
              // then open detail sheet with animation
              _handleMarkerSelection(target);
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
        minZoom: 15.0, // prevent zooming out below campus level
        maxZoom: 18.0, // prevent zooming in beyond detail level
        // disable all rotation gestures
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
        cameraConstraint: CameraConstraint.contain(
          bounds: LatLngBounds(
            LatLng(52.507, 13.317), // southWest
            LatLng(52.519, 13.335), // northEast
          ),
        ),
        backgroundColor: Colors.grey.shade200,
        onTap: (tapPos, latlng) => _handleMarkerSelection(latlng),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.app',
          tileProvider: _cachedTileProvider,
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
        onPressed: () => _goToCurrentLocation(moveMap: true),
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
        onClose: () {
          Navigator.of(context).pop();
          _resetMarkerSelection(); // Reset animation when sheet closes
        },
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
              _resetMarkerSelection(); // Reset animation when route is created
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
              _resetMarkerSelection(); // Reset animation when route is created
            },
          );
        },
      );
    }
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
}
