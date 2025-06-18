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
import 'package:auth_app/presentation/widgets/building_slide_window.dart';
import 'package:auth_app/presentation/home/pages/mensa.dart';

// Removed invalid import as the file does not exist

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/animation.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/flutter_map.dart' show StrokePattern, PatternFit;
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart' as FMTC;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:auth_app/service_locator.dart';
import 'package:auth_app/presentation/widgets/search_bar.dart';
import 'package:auth_app/presentation/widgets/route_plan_bar.dart';
//import 'package:flutter_map/plugin_api.dart' show FitBoundsOptions;

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

  /// Emits `true` when the search bar gains focus and `false` when it
  /// loses focus.  Parent widgets can use this to hide/show UI elements.
  final ValueChanged<bool>? onSearchFocusChanged;

  const MapPage({
    super.key,
    required this.scaffoldKeyForBottomSheet,
    this.onSearchFocusChanged,
  });

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with TickerProviderStateMixin {
  static const _animDuration = Duration(milliseconds: 250);
  static const double _navBarHeight = 88; // ← height from bottom-nav

  // ── live flags & sheet controllers ───────────────────────────────
  bool _creatingRoute = false;
  PersistentBottomSheetController? _plannerSheetCtr;
  OverlayEntry? _plannerOverlay; // top RoutePlanBar overlay
  bool _searchActive = false;
  Pointer? _buildingPanelPointer;

  final FocusNode _searchFocusNode = FocusNode();

  // Sliding-up-panel controller
  final PanelController _panelController = PanelController();
  ValueNotifier<Map<TravelMode, RouteData>>? _panelRoutes;
  TravelMode? _panelMode;

  // Controller for programmatic snapping after drag-release
  final DraggableScrollableController _sheetCtrl =
      DraggableScrollableController();

  // helper so we type less ↓
  void _notifyNavBar(bool hide) => widget.onSearchFocusChanged?.call(hide);

  // ── controllers & data ───────────────────────────────────────────
  final MapController _mapController = MapController();
  AnimationController? _mapAnimController;
  final TextEditingController _searchCtl = TextEditingController();
  LatLng? _routeDestination; // Field to store the route destination
  List<Marker> _markers = [];
  List<Pointer> _allPointers = [];
  List<Pointer> _suggestions = [];
  LatLng? _currentLocation;

  final ValueNotifier<Map<TravelMode, RouteData>> _routesNotifier =
      ValueNotifier({});
  TravelMode _currentMode = TravelMode.walk;

  late final TileProvider _cachedTiles;

  // Consistent animation timing for every disappearing element
  //static const _animDuration = Duration(milliseconds: 250);

  // ────────────────────────────────────────────────────────────────
  // Cache WeatherWidget so it isn’t rebuilt (and re-fetching) on
  // every focus toggle.  A ValueKey guarantees Flutter re-uses the
  // same State object, keeping the previously-fetched data alive.
  // ────────────────────────────────────────────────────────────────
  late final Widget _persistentWeather = WeatherWidget(
    key: const ValueKey('persistentWeather'),
    location: const LatLng(matheLat, matheLon),
  );

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
    _searchFocusNode.addListener(() {
      final active = _searchFocusNode.hasFocus;
      if (mounted && _searchActive != active) {
        setState(() => _searchActive = active);
        _notifyNavBar(active);
      }
    });
  }

  @override
  void dispose() {
    _mapAnimController?.dispose();
    _panelController.close();
    _searchCtl.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// Snap the sheet to the nearest predefined stop once the user lifts their finger.
  void _snapToNearest() {
    const stops = [0.10, 0.15, 0.20, 0.25, 0.30];
    final current = _sheetCtrl.size;
    final closest = stops.reduce(
      (a, b) => (a - current).abs() < (b - current).abs() ? a : b,
    );
    _sheetCtrl.animateTo(
      closest,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  /* ───────────────────────── Panel helpers ───────────────────── */
  void _clearPanelData() {
    _panelRoutes = null;
    _panelMode = null;
  }

  // Returns true if any panel (building or route) is open
  bool get _panelActive =>
      _buildingPanelPointer != null || _panelRoutes != null;
  bool get _isMensaPanel =>
      _buildingPanelPointer != null &&
      _buildingPanelPointer!.category.toLowerCase() == 'canteen';

  // ── build ────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // We need to choose how tall the panel should be, based on which content it’s showing.
    double maxHeight;

    // If we’re currently showing a “building info” panel…
    if (_buildingPanelPointer != null) {
      final p =
          _buildingPanelPointer!; // our Pointer model with name, category, coords

      // ────────────────────────────────────────────────────────────────
      // 1) Compute available width for text layout (total screen width minus horizontal padding)
      // ────────────────────────────────────────────────────────────────
      const horizontalPadding =
          20.0 * 2; // left + right padding inside the sheet
      final panelWidth = MediaQuery.of(context).size.width - horizontalPadding;
      print('Panel width: $panelWidth');
      // ────────────────────────────────────────────────────────────────
      // 2) Measure the height of the title (which may wrap to multiple lines)
      // ────────────────────────────────────────────────────────────────
      final TextStyle titleStyle =
          Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)
          // fallback if theme doesn’t provide titleLarge
          ??
          const TextStyle(fontSize: 20, fontWeight: FontWeight.bold);
      //print('Title style: $titleStyle');
      
      // Calculate the available width dynamically by subtracting the close button width
      final closeButtonWidth = 40.0; // Example width of the close button
      final availableWidth = panelWidth - closeButtonWidth; // Adjust the width for the text

      // Create a TextPainter to measure the rendered size of p.name
      final TextPainter titlePainter = TextPainter(
        text: TextSpan(text: p.name, style: titleStyle),
        textDirection: TextDirection.ltr,
        maxLines: 10, // Set a large number for maxLines
      )..layout(maxWidth: availableWidth); // Use the adjusted width

      // Calculate the total height using line metrics
      final lineMetrics = titlePainter.computeLineMetrics();
      final totalHeight = lineMetrics.fold(0.0, (sum, line) => sum + line.height);

      print('Title size: ${titlePainter.size}, Total height: $totalHeight');


      // Get per-line metrics (so we know line height and count)
      final lineMetrics2 = titlePainter.computeLineMetrics();
      // Either take the computed height of the first line, or fallback to the fontSize
      final lineHeight = lineMetrics2.isNotEmpty
          ? lineMetrics2.first.height
          : (titleStyle.fontSize ?? 20);
      // Total title height = number of lines × line height
      final titleHeight = lineMetrics2.length * lineHeight;
      print('Title height: $titleHeight');
      

      // ────────────────────────────────────────────────────────────────
      // 3) Measure the height of the category text (single line)
      // ────────────────────────────────────────────────────────────────
      final TextStyle categoryStyle =
          Theme.of(context).textTheme.bodyMedium ??
          const TextStyle(fontSize: 14);
      //print('Category style: $categoryStyle');

      final TextPainter categoryTP = TextPainter(
        text: TextSpan(text: p.category, style: categoryStyle),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: panelWidth);
      print('Category size: ${categoryTP.size}');

      // Category label height
      final categoryHeight = categoryTP.size.height;
      print('Category height: $categoryHeight');
      // ────────────────────────────────────────────────────────────────
      // 4) Account for all the fixed spacings in the sheet’s header
      // ────────────────────────────────────────────────────────────────
      const topPadding = 12.0; // Padding top in BuildingSlideWindow
      const handleHeight = 4.0; // drag handle height
      const betweenHandleAndHeader = 12.0; // SizedBox(height:12)
      const betweenTitleAndCategory = 4.0; // SizedBox(height:4)
      const afterHeader = 20.0; // SizedBox(height:20)
      const closeButtonHeight = 28.0; // height of the circular close button
      // Compute the height of the title+category block
      final headerContentHeight = titleHeight + betweenTitleAndCategory + categoryHeight;
      // Ensure header accounts for the larger of text block or close button
      final headerBlockHeight = headerContentHeight < closeButtonHeight ? closeButtonHeight : headerContentHeight;
      final headerTotal = topPadding + handleHeight + betweenHandleAndHeader
          + headerBlockHeight + afterHeader;
      print('Header total height: $headerTotal');

      // ────────────────────────────────────────────────────────────────
      // 5) Account for the buttons section (one or two rows of gradient buttons)
      // ────────────────────────────────────────────────────────────────
      const buttonHeight = 48.0; // each button’s height
      const buttonRowSpacing = 16.0; // vertical gap between rows

      // If this is a canteen, we show two rows (route + fav. + menu), otherwise one.
      final rows = (p.category.toLowerCase() == 'canteen') ? 2 : 1;

      // Total buttons block = (height × rows) + (spacing between rows)
      final buttonsTotal =
          (buttonHeight * rows) + (buttonRowSpacing * (rows - 1));
      print('Buttons total height: $buttonsTotal');

      // ────────────────────────────────────────────────────────────────
      // 6) Bottom padding + safe area inset
      // ────────────────────────────────────────────────────────────────
      const bottomPadding = 28.0; // Padding at bottom of sheet
      final safeAreaBottom = MediaQuery.of(context).padding.bottom;
      

      // Final: sum header + buttons + bottom padding + any OS-level safe area
      maxHeight = headerTotal + buttonsTotal + bottomPadding + safeAreaBottom;
      print('Max height for building panel: $maxHeight');
      // Clamp so it’s never too small or taller than 85% of screen height
      maxHeight = maxHeight.clamp(
        180.0,
        MediaQuery.of(context).size.height * 0.85,
      );

      // ────────────────────────────────────────────────────────────────
      // If we’re showing the route-options panel instead…
      // ────────────────────────────────────────────────────────────────
    } else if (_panelRoutes != null) {
      // route sheet always up to 31% of screen height
      maxHeight = MediaQuery.of(context).size.height * 0.31;

      // ────────────────────────────────────────────────────────────────
      // Otherwise neither sheet is active, we’ll show a small handle only
      // ────────────────────────────────────────────────────────────────
    } else {
      maxHeight = 180.0; // default “peek” height if nothing else is open
    }

    // ─────────────────────────────────────────────────────────────────
    // Now build the Scaffold with our SlidingUpPanel, using the computed height
    // ─────────────────────────────────────────────────────────────────
    return Scaffold(
      body: SlidingUpPanel(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        controller: _panelController, // the PanelController instance
        minHeight: 20, // always leave a 20 px “handle” visible
        maxHeight: maxHeight, // our dynamic max height
        snapPoint: 0.2, // when you drag up, snaps at 20% if release early
        isDraggable: true, // allow dragging
        // … panelBuilder, onPanelClosed, body, etc. follow here …
        panelBuilder: (sc) {
          if (_buildingPanelPointer != null) {
            final p = _buildingPanelPointer!;
            return BuildingSlideWindow(
              title: p.name,
              category: p.category,
              onCreateRoute: () {
                setState(() => _buildingPanelPointer = null);
                _panelController.close();
                _startRouteFlow(LatLng(p.lat, p.lng));
              },
              onAddToFavourites: () {
                FavouritesManager().add(p);
                setState(() => _buildingPanelPointer = null);
                _panelController.close();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${p.name} added to favourites!')),
                );
              },
              onClose: () {
                setState(() => _buildingPanelPointer = null);
                _panelController.close();
                _notifyNavBar(false);
              },
              onShowMenu: p.category.toLowerCase() == 'canteen'
                  ? () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MensaPage(mensaName: p.name),
                      ),
                    )
                  : null,
              // No custom handle or controller needed
            );
          }
          if (_panelRoutes != null) {
            return RouteOptionsSheet(
              routesNotifier: _panelRoutes!,
              currentMode: _panelMode ?? TravelMode.walk,
              scrollController: sc,
              onModeChanged: _changeTravelMode,
              onClose: () {
                _panelController.close();
                _notifyNavBar(false); // Hide nav bar when closing
              },
            );
          }
          return const SizedBox.shrink();
        },
        onPanelClosed: () {
          // Only clear the panel if it is actually closed (not just at minHeight)
          if (_panelController.panelPosition == 0.0) {
            setState(() => _buildingPanelPointer = null);
            _plannerOverlay?.remove();
            _plannerOverlay = null;
            _routesNotifier.value = {};
            _currentMode = TravelMode.walk;
            _clearPanelData();
            setState(() => _creatingRoute = false);
            _notifyNavBar(false);
          }
        },
        body: Stack(
          children: [
            _buildFlutterMap(),

            // ── animated white sheet over the map ──────────────────────
            AnimatedSlide(
              offset: _searchActive ? Offset.zero : const Offset(0, -0.06),
              duration: _animDuration,
              curve: Curves.easeInOut,
              child: AnimatedOpacity(
                opacity: _searchActive ? 1.0 : 0.0,
                duration: _animDuration,
                child: IgnorePointer(
                  ignoring: !_searchActive,
                  child: GestureDetector(
                    onTap: () {},
                    child: Container(
                      color: Colors.white,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                ),
              ),
            ),
            if (!_creatingRoute && !_panelActive)
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
                onCategorySelected: (category, color) {
                  _filterMarkersByCategory(category, color);
                  if (category != null) {
                    _showCategoryListPopup(category, color ?? Colors.blue);
                  }
                },
                onSuggestionSelected: (p) {
                  final dest = LatLng(p.lat, p.lng);
                  _animatedMapMove(dest, 18);
                  _onMapTap(dest);
                },
                focusNode: _searchFocusNode,
              ),
            // hide FAB & weather while search bar or any panel is active
            if (!_panelActive) _buildCurrentLocationButton(),
            if (!_panelActive)
              Positioned(
                left: 16,
                bottom: _bottomOffset,
                child: AnimatedSlide(
                  offset: (_searchActive || _creatingRoute)
                      ? const Offset(0, 1)
                      : Offset.zero,
                  duration: _animDuration,
                  curve: Curves.easeInOut,
                  child: AnimatedOpacity(
                    opacity: (_searchActive || _creatingRoute) ? 0 : 1,
                    duration: _animDuration,
                    child: _persistentWeather,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Opens building info panel
  void _showBuildingPanel(Pointer p) {
    setState(() => _buildingPanelPointer = p);
    _panelController.open();
    _notifyNavBar(true); // Hide nav bar when opening
  }

  // ───────────────────────────────────────────────────────────
  // Start full routing flow: top bar + bottom-sheet directions
  // ───────────────────────────────────────────────────────────
  void _startRouteFlow(LatLng destination) {
    _routeDestination = destination; // remember for later
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

              _notifyNavBar(false); // ⬅️ show it again
              // also close the Sliding-up panel if it is open
              if (_panelController.isPanelOpen) {
                _panelController.close();
              }
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

  // ────────────────────────────────────────────────────────────────
  // Helpers to build overlay widgets
  // ────────────────────────────────────────────────────────────────
  // Always place widgets 20 px above the nav bar; they will animate
  // out of view instead of shifting upward.
  double get _bottomOffset => 20 + _navBarHeight;

  Widget _buildCurrentLocationButton() => Positioned(
    bottom: _bottomOffset,
    right: 20,
    child: AnimatedSlide(
      offset: _searchActive ? const Offset(0, 1) : Offset.zero,
      duration: _animDuration,
      curve: Curves.easeInOut,
      child: AnimatedOpacity(
        opacity: _searchActive ? 0 : 1,
        duration: _animDuration,
        child: FloatingActionButton(
          backgroundColor: Colors.white,
          onPressed: () => _goToCurrentLocation(moveMap: true),
          child: const Icon(Icons.my_location, color: Colors.blue),
        ),
      ),
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
    if (_panelController.isPanelOpen || _plannerOverlay != null) return;

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
      _showBuildingPanel(p);
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
    _showBuildingPanel(p);
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
    required Function(TravelMode) onModeChanged,
    required VoidCallback onClose,
  }) {
    _panelRoutes = routesNotifier;
    _panelMode = currentMode;
    setState(() {}); // rebuild SlidingUpPanel
    _notifyNavBar(true);
    _panelController.open();
  }

  // ── animation helper ───────────────────in──────────────────────────
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

  Future<void> _changeTravelMode(TravelMode mode) async {
    if (mode == _currentMode || _routeDestination == null) return;

    // Update UI immediately so the pills highlight correctly
    setState(() {
      _currentMode = mode;
      _panelMode = mode;
    });

    await RouteLogic.onModeChanged(
      context: context,
      mode: mode,
      destination: _routeDestination!, // ← we stored it earlier
      currentLocation: _currentLocation,
      routesNotifier: _routesNotifier,
      setState: setState,
      updateCurrentMode: (m) => setState(() => _currentMode = m),
    );
  }
}

/// Prevents any inner scrolling or overscroll glow
class _NoScrollBehavior extends ScrollBehavior {
  @override
  Widget buildViewportChrome(BuildContext _, Widget child, AxisDirection __) =>
      child;
  @override
  ScrollPhysics getScrollPhysics(BuildContext _) =>
      const NeverScrollableScrollPhysics();
}
