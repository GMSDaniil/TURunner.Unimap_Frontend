import 'dart:convert';
import 'package:auth_app/data/models/find_scooter_route_response.dart';
import 'package:auth_app/data/models/get_menu_req_params.dart';
import 'package:auth_app/data/models/route_data.dart';
import 'package:auth_app/data/models/route_segment.dart';
import 'package:auth_app/domain/usecases/find_bus_route.dart';
import 'package:auth_app/domain/usecases/find_scooter_route.dart';
import 'package:auth_app/domain/usecases/get_mensa_menu.dart';
import 'package:auth_app/domain/usecases/get_pointers_usecase.dart';
import 'package:auth_app/domain/usecases/find_walking_route.dart';
//import 'package:auth_app/domain/usecases/find_route.dart';
import 'package:auth_app/domain/usecases/find_building_at_point.dart';
import 'package:auth_app/data/models/findroute_req_params.dart';
import 'package:auth_app/data/models/pointer.dart';
import 'package:auth_app/data/favourites_manager.dart';
import 'package:auth_app/presentation/widgets/building_popup_manager.dart';
import 'package:auth_app/presentation/widgets/category_navigation.dart'
    show CategoryNavigationBar;
import 'package:auth_app/presentation/widgets/map_marker_manager.dart';
import 'package:auth_app/presentation/widgets/map_widget.dart';
import 'package:auth_app/presentation/widgets/route_logic.dart';
import 'package:auth_app/presentation/widgets/route_options_sheet.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/animation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/flutter_map.dart' show StrokePattern, PatternFit;
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart'
    as FMTC;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:auth_app/service_locator.dart';
import 'package:auth_app/presentation/widgets/search_bar.dart';
import 'package:auth_app/presentation/widgets/route_plan_bar.dart';


// ─────────────────────────────────────────────────────────────────────────
//  MapPage – now featuring Google-Maps-style route planner
// ─────────────────────────────────────────────────────────────────────────

const double matheLat = 52.5135, matheLon = 13.3245;

class MapPage extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKeyForBottomSheet;

  const MapPage({super.key, required this.scaffoldKeyForBottomSheet});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with TickerProviderStateMixin {
  // ── live flags & sheet controllers ───────────────────────────────
  bool _creatingRoute = false;
  PersistentBottomSheetController? _plannerSheetCtr;
  PersistentBottomSheetController? _routeSheetCtr;
  OverlayEntry? _plannerOverlay;   // ← NEW

  // ── controllers & data ───────────────────────────────────────────
  final MapController _mapController = MapController();
  AnimationController? _mapAnimController;
  final TextEditingController _searchCtl = TextEditingController();

  List<Marker> _markers = [];
  List<Pointer> _allPointers = [];
  List<Pointer> _suggestions = [];
  LatLng? _currentLocation;

  final ValueNotifier<Map<TravelMode, RouteData>> _routesNotifier =
      ValueNotifier({});
  TravelMode _currentMode = TravelMode.walk;

  late final TileProvider _cachedTiles;

  // ── lifecycle ────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadBuildingMarkers();
    _searchCtl.addListener(_onSearchChanged);
    _goToCurrentLocation();
    _cachedTiles = FMTC.FMTCTileProvider(
      stores: {'mapStore': FMTC.BrowseStoreStrategy.readUpdateCreate},
    );
  }

  @override
  void dispose() {
    _mapAnimController?.dispose();
    _searchCtl.dispose();
    super.dispose();
  }

  // ── build ────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildFlutterMap(),
          if (!_creatingRoute)
            MapSearchBar(
              searchController: _searchCtl,
              suggestions: _suggestions,
              onSearch: (q) {
                _searchMarkers(q);
                setState(() => _suggestions = []);
              },
              onClear: () {
                _searchCtl.clear();
                setState(() => _suggestions = []);
              },
              onCategorySelected: _filterMarkersByCategory,
              onSuggestionSelected: (p) {
                final dest = LatLng(p.lat, p.lng);
                _animatedMapMove(dest, 18);
                _onMapTap(dest);
              },
            ),
          _buildCurrentLocationButton(),
        ],
      ),
      // floatingActionButton removed to hide route-creation button
    );
  }

  // ───────────────────────────────────────────────────────────
  // Start full routing flow: top bar + bottom-sheet directions
  // ───────────────────────────────────────────────────────────
  void _startRouteFlow(LatLng destination) {
    if (_plannerOverlay != null) return;
    setState(() {
      _creatingRoute = true;
      _currentMode   = TravelMode.walk;   // reset to walking
      _routesNotifier.value = {};         // drop any old routes
    });

    /* slide-in from top */
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    final slide = Tween(begin: const Offset(0, -1), end: Offset.zero)
        .animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));

    _plannerOverlay = OverlayEntry(
      builder: (_) => SlideTransition(
        position: slide,
        child: Align(
          alignment: Alignment.topCenter,
          child: RoutePlanBar(
              currentLocation: _currentLocation,
              initialDestination: destination,
              allPointers:        _allPointers,
              onCancelled:        () async {
                controller.reverse();
                await controller.forward();
                _plannerOverlay?.remove();
                _plannerOverlay = null;
                setState(() => _creatingRoute = false);
                // also close directions sheet if open
                _routeSheetCtr?.close();
              },
              onChanged: (newStart, newDest) async {
                // 1️⃣ recalc the route in place
                await _handleCreateRoute(
                  newDest,
                  startOverride: newStart,
                  rebuildOnly: true,
                );

                // 2️⃣ once that's done, grab all the points & fit the map
                final data = _routesNotifier.value[_currentMode];
                final pts = data?.segments.expand((s) => s.path).toList() ?? [];
                if (pts.isNotEmpty) {
                  final bounds = LatLngBounds.fromPoints(pts);
                  // you can tweak the padding/zoomThreshold here
                  _animatedMapMove(bounds.center, 16.0);
                }
              },
            ),
        ),
      ),
    );

    Overlay.of(context, rootOverlay: true)!.insert(_plannerOverlay!);
    controller.forward();        // animate it in

    // first time in → rebuildOnly=false (default)
    _handleCreateRoute(destination, startOverride: _currentLocation);
  }

  // ── search listener ──────────────────────────────────────────────
  void _onSearchChanged() {
    final q = _searchCtl.text.trim().toLowerCase();
    setState(() {
      _suggestions = q.isEmpty
          ? []
          : _allPointers.where((p) => p.name.toLowerCase().contains(q)).toList();
    });
  }

  // ── map widget + helpers ─────────────────────────────────────────
  Widget _buildFlutterMap() {
    final route = _routesNotifier.value[_currentMode];
    final segments = route?.segments ?? [];

    LatLng _closest(LatLng s, List<LatLng> line) {
      double best = double.infinity;
      LatLng bestP = line.first;
      for (final p in line) {
        final d = Distance().as(LengthUnit.Meter, s, p);
        if (d < best) {
          best = d;
          bestP = p;
        }
      }
      return bestP;
    }

    final busMarkers = buildBusStopMarkers(
      segments: segments,
      closestPointCalculator: _closest,
    );
    final scooterMarkers = buildScooterMarkers(segments);

    return MapWidget(
      mapController: _mapController,
      markers: _markers,
      busStopMarkers: busMarkers,
      scooterMarkers: scooterMarkers,
      segments: segments,
      currentLocation: _currentLocation,
      cachedTileProvider: _cachedTiles,
      onMapTap: _onMapTap,
      parentContext: context,
    );
  }

  Widget _buildCurrentLocationButton() => Positioned(
        bottom: 20,
        right: 20,
        child: FloatingActionButton(
          backgroundColor: Colors.white,
          onPressed: () => _goToCurrentLocation(moveMap: true),
          child: const Icon(Icons.my_location, color: Colors.blue),
        ),
      );

  // ── markers, filter & search ─────────────────────────────────────
  Future<void> _loadBuildingMarkers() async {
    try {
      _allPointers = await sl<GetPointersUseCase>().call();
      final m = _allPointers.map((p) {
        return Marker(
          point: LatLng(p.lat, p.lng),
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => _onMarkerTap(p),
            child: Image.asset(
              getPinAssetForCategory(p.category),
              width: 40,
              height: 40,
            ),
          ),
        );
      }).toList();
      setState(() => _markers = m);
    } catch (e) {
      debugPrint('Error loading markers: $e');
    }
  }

  void _searchMarkers(String q) {
    final filtered =
        _allPointers.where((p) => p.name.toLowerCase().contains(q)).toList();

    setState(() {
      _markers = MapMarkerManager.searchMarkersByName(
        allPointers: _allPointers,
        query: q,
        onMarkerTap: _onMarkerTap,
      );
    });

    MapMarkerManager.centerMapOnFilteredResults(
      mapController: _mapController,
      filtered: filtered,
    );
  }

  void _filterMarkersByCategory(String? cat, Color? color) {
    setState(() {
      _markers = MapMarkerManager.allMarkersWithHighlight(
        allPointers: _allPointers,
        highlightedCategory: cat,
        highlightColor: color,
        onMarkerTap: _onMarkerTap,
      );
    });

    if (cat != null) {
      final f = _allPointers
          .where((p) =>
              p.category.trim().toLowerCase() == cat.trim().toLowerCase())
          .toList();
      if (f.isNotEmpty) {
        final b = LatLngBounds.fromPoints(
          f.map((p) => LatLng(p.lat, p.lng)).toList()
        );
        _mapController.fitCamera(
          CameraFit.bounds(bounds: b, padding: const EdgeInsets.all(40)),
        );
      }
    }
  }

  // ── taps ─────────────────────────────────────────────────────────
  void _onMapTap(LatLng latlng) async {
    if (_routeSheetCtr != null || _plannerSheetCtr != null) return;

    final building = await sl<FindBuildingAtPoint>().call(latlng);

    if (building != null) {
      final p = _allPointers.firstWhere(
        (x) => x.name == building.name,
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
        category: p.category,
        location: latlng,
        onCreateRoute: () => _startRouteFlow(latlng),
        onClose: () {},
      );
    } else {
      BuildingPopupManager.showBuildingOrCoordinatesPopup(
        context: context,
        scaffoldKey: widget.scaffoldKeyForBottomSheet,
        latlng: latlng,
        buildingName: null,
        category: null,
        onCreateRoute: () => _startRouteFlow(latlng),
      );
    }
  }

  void _onMarkerTap(Pointer p) {
    _animatedMapMove(LatLng(p.lat, p.lng), 18);
    BuildingPopupManager.showBuildingSlideWindow(
      context: context,
      scaffoldKey: widget.scaffoldKeyForBottomSheet,
      title: p.name,
      category: p.category,
      location: LatLng(p.lat, p.lng),
      onCreateRoute: () => _startRouteFlow(LatLng(p.lat, p.lng)),
      onClose: () {},
    );
  }

  // ── current location ─────────────────────────────────────────────
  Future<void> _goToCurrentLocation({bool moveMap = false}) async {
    if (!await Geolocator.isLocationServiceEnabled()) return;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) return;
    }

    final last = await Geolocator.getLastKnownPosition();
    if (last != null) {
      _currentLocation = LatLng(last.latitude, last.longitude);
      if (moveMap) _animatedMapMove(_currentLocation!, 17);
    }

    final pos = await Geolocator.getCurrentPosition();
    _currentLocation = LatLng(pos.latitude, pos.longitude);
    if (moveMap) _animatedMapMove(_currentLocation!, 17);
    setState(() {});
  }

  // ── route creation & sheet ───────────────────────────────────────
  Future<void> _handleCreateRoute(
    LatLng dest, {
    LatLng? startOverride,
    bool   rebuildOnly = false,
  }) async {
    await RouteLogic.onCreateRoute(
      context: context,
      latlng: dest,
      currentLocation: startOverride ?? _currentLocation,
      routesNotifier: _routesNotifier,
      setState: setState,
      animatedMapMove: _animatedMapMove,
      mounted: mounted,
      currentMode: _currentMode,
      showRouteOptionsSheet: _showRouteOptionsSheet,
      onModeChanged: (m) async {
        await RouteLogic.onModeChanged(
          context: context,
          mode: m,
          destination: dest,
          currentLocation: _currentLocation,
          routesNotifier: _routesNotifier,
          setState: setState,
          updateCurrentMode: (nm) => setState(() => _currentMode = nm),
        );
      },
      rebuildOnly: rebuildOnly,      // ← NEW
    );
  }

  void _showRouteOptionsSheet({
    required ValueNotifier<Map<TravelMode, RouteData>> routesNotifier,
    required TravelMode currentMode,
    required ValueChanged<TravelMode> onModeChanged,
    required VoidCallback onClose,
  }) {
    if (_routeSheetCtr != null) return;

    _routeSheetCtr =
        widget.scaffoldKeyForBottomSheet.currentState?.showBottomSheet(
      (_) => RouteOptionsSheet(
        routesNotifier: routesNotifier,
        currentMode: currentMode,
        onClose: onClose,
        onModeChanged: onModeChanged,
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
    );

    _routeSheetCtr?.closed.then((_) {
      // clear bottom‐sheet state
      _routeSheetCtr = null;
      onClose();
      // also remove the top RoutePlanBar overlay
      _plannerOverlay?.remove();
      _plannerOverlay = null;
      setState(() => _creatingRoute = false);
    });
  }

  // ── animation helper ─────────────────────────────────────────────
void _animatedMapMove(LatLng dest, double zoom) {
  _mapAnimController?.dispose();
  _mapAnimController =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

  final latTween  = Tween(begin: _mapController.camera.center.latitude,  end: dest.latitude);
  final lngTween  = Tween(begin: _mapController.camera.center.longitude, end: dest.longitude);
  final zoomTween = Tween(begin: _mapController.camera.zoom,             end: zoom);

  // ❶ Create the curved animation first …
  final anim = CurvedAnimation(
    parent: _mapAnimController!,
    curve: Curves.easeInOut,
  );

  // ❷ … then attach the listener.
  anim.addListener(() {
    _mapController.move(
      LatLng(latTween.evaluate(anim), lngTween.evaluate(anim)),
      zoomTween.evaluate(anim),
    );
  });

  _mapAnimController!.forward();
}

void _showPlannerBar() {
  final dest = _currentLocation ?? LatLng(matheLat, matheLon);
  _startRouteFlow(dest);
}

  // ── utils ───────────────────────────────────────────────────────
  String getPinAssetForCategory(String cat) {
    switch (cat.trim().toLowerCase()) {
      case 'mensa':
      case 'canteen':
        return 'assets/icons/pin_mensa.png';
      case 'café':
      case 'cafe':
        return 'assets/icons/pin_cafe.png';
      case 'library':
        return 'assets/icons/pin_library.png';
      default:
        return 'assets/icons/pin_default.png';
    }
  }
}
