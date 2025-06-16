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
import 'package:auth_app/presentation/widgets/weather_widget.dart';
// Removed invalid import as the file does not exist

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/animation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/flutter_map.dart' show StrokePattern, PatternFit;
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart' as FMTC;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:auth_app/service_locator.dart';
import 'package:auth_app/presentation/widgets/search_bar.dart';
import 'package:auth_app/presentation/widgets/route_plan_bar.dart';
import 'package:auth_app/main.dart' show appNavKey; // ← new
import 'dart:async' show Timer;                     // <── add this

// ─────────────────────────────────────────────────────────────────────────
//  MapPage – now featuring Google-Maps-style route planner
// ─────────────────────────────────────────────────────────────────────────

const double matheLat = 52.5135, matheLon = 13.3245;

// ── campus-wide “presets” for the three category buttons ────────────
//
//   • derived once from the full buildings.json
//   • tuned on a medium-phone emulator (≈ 480 px × 1 070 px map window)
//
//   If you ever change marker inventories, just re-calculate the mean
//   lat/lon per category and play with the zoom until it “looks right”.
//   No more run-time maths needed :)
//
//   ─────────  category  ────────  center.lat   center.lon    zoom
const _cafesCenter = LatLng(52.51271, 13.32517); // 10 cafés
const _cafesZoom = 15.5;

const _librariesCenter = LatLng(52.51250, 13.32619); //  4 libraries
const _librariesZoom = 15.5;

const _canteensCenter = LatLng(52.51351, 13.32496); //  4 main mensas¹
const _canteensZoom = 16.0;
// ¹ the Marchstraße (northern) mensa was left out on purpose; including it
//   made the view less useful for day-to-day campus food spotting.

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
  OverlayEntry? _plannerOverlay; // ← NEW
  bool _searchActive = false;
  final FocusNode _searchFocusNode = FocusNode();
  OverlayEntry? _searchBackdropEntry; // dim-background
  OverlayEntry? _searchUIEntry; // bar + suggestions

  final FocusNode _overlayFocus = FocusNode();

  OverlayEntry? _dimEntry; // white translucent sheet
  OverlayEntry? _uiEntry; // search bar + suggestions

  // ── controllers & data ───────────────────────────────────────────
  final MapController _mapController = MapController();
  AnimationController? _mapAnimController;
  final TextEditingController _searchCtl = TextEditingController();

  List<Marker> _markers = [];
  List<Pointer> _allPointers = [];
  List<Pointer> _suggestions = [];
  LatLng? _currentLocation;

  /// periodic retry until the search bar has focus
  Timer? _focusRetryTimer;                           // <── and add this

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

    // ── when the text-field gains / loses focus ────────────────
    _searchFocusNode.addListener(() {
      final hasFocus = _searchFocusNode.hasFocus;

      if (hasFocus && _dimEntry == null) {
        // build both entries
        _dimEntry = _buildBackdropOverlay();
        _uiEntry = _buildSearchUIOverlay();

        // insert them into the root overlay
        final overlay = appNavKey.currentState!.overlay!;
        overlay.insert(_dimEntry!);
        overlay.insert(_uiEntry!);

        // redraw suggestions instantly
        setState(() => _searchActive = true);
      } else if (!hasFocus && _dimEntry != null) {
        _dimEntry!.remove();
        _uiEntry!.remove();
        _dimEntry = null;
        _uiEntry = null;
        setState(() => _searchActive = false);
      }
    });
  }

  @override
  void dispose() {
    _searchBackdropEntry?.remove();
    _searchUIEntry?.remove();
    _plannerOverlay?.remove();
    _focusRetryTimer?.cancel(); // clean up retry timer
    super.dispose();
  }

  // ── helper: tap-anywhere to dismiss search ────────────────────────
  void _closeSearch() => _searchFocusNode.unfocus();

  /// Dim background overlay
  OverlayEntry _buildBackdropOverlay() {
    return OverlayEntry(
      builder: (_) => Positioned.fill(               // <-- makes it cover
        child: GestureDetector(
          onTap: _closeSearch,
          behavior: HitTestBehavior.opaque,
          child: ColoredBox(                          // cheaper than Material
            color: Colors.white.withOpacity(0.92),
          ),
        ),
      ),
    );
  }

  /// Search bar + live suggestions (sits above the backdrop)
  OverlayEntry _buildSearchUIOverlay() {
    return OverlayEntry(
      builder: (context) {
        // ⬇️ Re-attempt focus right after this frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_searchFocusNode.hasFocus) _searchFocusNode.requestFocus();
        });
        return SafeArea(
          child: Material(
            type: MaterialType.transparency,
            child: MapSearchBar(
              focusNode: _searchFocusNode,
              searchController: _searchCtl,
              suggestions: _suggestions,
              onSearch: (q) {
                _searchMarkers(q);
                setState(() => _suggestions = []);
                _uiEntry?.markNeedsBuild();
              },
              onClear: () {
                _searchCtl.clear();
                setState(() => _suggestions = []);
                _uiEntry?.markNeedsBuild();
              },
              onCategorySelected: (_, __) {},
              onSuggestionSelected: (p) {
                final dest = LatLng(p.lat, p.lng);
                _animatedMapMove(dest, 18);
                _onMapTap(dest);
                _searchFocusNode.unfocus();
              },
            ),
          ),
        );
      },
    );
  }

  // ── build ────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildFlutterMap(),
          if (_searchActive)
            AnimatedOpacity(
              opacity: _searchActive ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 180),
              child: GestureDetector(
                onTap: () {
                  _searchFocusNode.unfocus();
                },
                child: Container(
                  color: Colors.white.withOpacity(0.92),
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
          // Show in the widget tree only when NOT in fullscreen-search
          if (!_creatingRoute && !_searchActive)
            GestureDetector(
              // ① Invisible, but catches the very first tap
              behavior: HitTestBehavior.translucent,
              onTapDown: (_) {
                // ② Force keyboard focus immediately
                if (!_searchFocusNode.hasFocus) {
                  _searchFocusNode.requestFocus();
                }
              },
              child: MapSearchBar(
                searchController: _searchCtl,
                suggestions: _suggestions,
                onSearch: (q) {
                  setState(() {
                    _suggestions = q.isEmpty
                        ? []
                        : _allPointers
                            .where((p) => p.name.toLowerCase().contains(q))
                            .toList();
                    _searchUIEntry?.markNeedsBuild(); // live-refresh overlay
                  });
                },
                onClear: () {
                  _searchCtl.clear();
                  setState(() => _suggestions = []);
                  _searchUIEntry?.markNeedsBuild();
                },
                onCategorySelected: (_, __) {},
                onSuggestionSelected: (p) {
                  final dest = LatLng(p.lat, p.lng);
                  _animatedMapMove(dest, 18);
                  _onMapTap(dest);
                  _searchFocusNode.unfocus();
                },
                focusNode: _searchFocusNode,
              ),
            ),
          _buildCurrentLocationButton(),
          //weather widget
          Positioned(
            left: 16,
            bottom: 20,
            child: WeatherWidget(
              location: LatLng(
                matheLat,
                matheLon,
              ), // default mathe gebäude location
            ),
          ),
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
      _currentMode = TravelMode.walk; // reset to walking
      _routesNotifier.value = {}; // drop any old routes
    });

    /* slide-in from top */
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    final slide = Tween(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));

    _plannerOverlay = OverlayEntry(
      builder: (_) => SlideTransition(
        position: slide,
        child: Align(
          alignment: Alignment.topCenter,
          child: RoutePlanBar(
            currentLocation: _currentLocation,
            initialDestination: destination,
            allPointers: _allPointers,
            onCancelled: () async {
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

    Overlay.of(
      context,
      rootOverlay: true,
    )!.insert(_plannerOverlay!); // Ensure non-null overlay
    controller.forward(); // animate it in

    // first time in → rebuildOnly=false (default)
    _handleCreateRoute(destination, startOverride: _currentLocation);
  }

  // ── search listener ──────────────────────────────────────────────
  void _onSearchChanged() {
    final q = _searchCtl.text.trim().toLowerCase();
    setState(() {
      _suggestions = q.isEmpty
          ? []
          : _allPointers
                .where((p) => p.name.toLowerCase().contains(q))
                .toList();
      // 🔄 redraw the overlay immediately
      _searchUIEntry?.markNeedsBuild();
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
    var response = await sl<GetPointersUseCase>().call();
    response.fold(
      (error) {
        debugPrint('Error loading pointers: $error');
        return;
      },
      (pointers) {
        _allPointers = pointers;
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
      },
    );
  }

  void _searchMarkers(String q) {
    final filtered = _allPointers
        .where((p) => p.name.toLowerCase().contains(q))
        .toList();

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

  void _filterMarkersByCategory(String? category, Color? markerColor) {
    setState(() {
      if (category == null) {
        _markers = _allPointers.map((pointer) {
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
      } else {
        _markers = _allPointers
            .where((p) {
              final cat = category.trim().toLowerCase();
              final pCat = p.category.trim().toLowerCase();
              if (cat.contains('café')) return pCat == 'cafe' || pCat == 'café';
              if (cat.contains('librar')) return pCat.contains('librar');
              if (cat.contains('canteen') || cat.contains('mensa'))
                return pCat == 'canteen' || pCat == 'mensa';
              if (cat.contains('study room')) return pCat == 'study room';
              return false;
            })
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

    // If a category is selected, zoom to the pre-defined campus view
    if (category != null) {
      final cat = category.toLowerCase();
      if (cat.contains('café') || cat.contains('cafe')) {
        _animatedMapMove(_cafesCenter, _cafesZoom);
      } else if (cat.contains('librar')) {
        _animatedMapMove(_librariesCenter, _librariesZoom);
      } else if (cat.contains('mensa') || cat.contains('canteen')) {
        _animatedMapMove(_canteensCenter, _canteensZoom);
      }
    }
  }

  // ── taps ─────────────────────────────────────────────────────────
  void _onMapTap(LatLng latlng) async {
    if (_routeSheetCtr != null || _plannerSheetCtr != null) return;

    final building = await sl<FindBuildingAtPoint>().call(point: latlng);

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
      _animatedMapMove(LatLng(p.lat, p.lng), 18);
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
    if (_plannerOverlay != null) return;
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
          perm == LocationPermission.deniedForever)
        return;
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
    bool rebuildOnly = false,
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
      rebuildOnly: rebuildOnly, // ← NEW
    );
  }

  void _showRouteOptionsSheet({
    required ValueNotifier<Map<TravelMode, RouteData>> routesNotifier,
    required TravelMode currentMode,
    required ValueChanged<TravelMode> onModeChanged,
    required VoidCallback onClose,
  }) {
    if (_routeSheetCtr != null) return;

    _routeSheetCtr = widget.scaffoldKeyForBottomSheet.currentState
        ?.showBottomSheet(
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
    _mapAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    final latTween = Tween(
      begin: _mapController.camera.center.latitude,
      end: dest.latitude,
    );
    final lngTween = Tween(
      begin: _mapController.camera.center.longitude,
      end: dest.longitude,
    );
    final zoomTween = Tween(begin: _mapController.camera.zoom, end: zoom);

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
      case 'libraries':
      case 'library':
        return 'assets/icons/pin_library.png';
      default:
        return 'assets/icons/pin_default.png';
    }
  }

  void _showCategoryListPopup(String category, Color color) {
    final cat = category.trim().toLowerCase();
    final filtered = _allPointers.where((p) {
      final pCat = p.category.trim().toLowerCase();
      if (cat.contains('café')) return pCat == 'cafe' || pCat == 'café';
      if (cat.contains('librar')) return pCat.contains('librar');
      if (cat.contains('canteen') || cat.contains('mensa'))
        return pCat == 'canteen' || pCat == 'mensa';
      if (cat.contains('study room')) return pCat == 'study room';
      return false;
    }).toList();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'All ${category[0].toUpperCase()}${category.substring(1)}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final p = filtered[i];
                    return ListTile(
                      leading: Image.asset(
                        getPinAssetForCategory(p.category),
                        width: 32,
                        height: 32,
                      ),
                      title: Text(p.name),
                      trailing: IconButton(
                        icon: const Icon(Icons.directions),
                        onPressed: () {
                          Navigator.pop(context);
                          _startRouteFlow(LatLng(p.lat, p.lng));
                        },
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _animatedMapMove(LatLng(p.lat, p.lng), 18);
                        _onMarkerTap(p);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
