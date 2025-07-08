import 'dart:convert';
import 'package:wkt_parser/wkt_parser.dart';
import 'dart:async';
import 'package:auth_app/data/models/find_scooter_route_response.dart';
import 'package:auth_app/data/models/get_menu_req_params.dart';
import 'package:auth_app/data/models/interactive_annotation.dart';
import 'package:auth_app/data/models/route_data.dart';
import 'package:auth_app/data/models/route_segment.dart';
import 'package:auth_app/data/theme_manager.dart';
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
import 'package:auth_app/presentation/widgets/gradient_widget.dart';
import 'package:auth_app/presentation/widgets/map_marker_manager.dart';
import 'package:auth_app/presentation/widgets/map_widget.dart';
import 'package:auth_app/presentation/widgets/mapbox_map_widget.dart';
import 'package:auth_app/presentation/widgets/route_logic.dart';
import 'package:auth_app/presentation/widgets/route_options_sheet.dart';
import 'package:auth_app/presentation/widgets/route_details_sheet.dart';
import 'package:auth_app/presentation/widgets/weather_widget.dart';
import 'package:auth_app/presentation/widgets/building_slide_window.dart';
import 'package:auth_app/presentation/widgets/weekly_mensa_plan.dart';

// Removed invalid import as the file does not exist

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/animation.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/flutter_map.dart' show StrokePattern, PatternFit;
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart' as FMTC;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:auth_app/service_locator.dart';
import 'package:auth_app/presentation/widgets/search_bar.dart';
import 'package:auth_app/presentation/widgets/route_plan_bar.dart';
import 'package:auth_app/presentation/widgets/category_top_bar.dart';
//import 'package:flutter_map/plugin_api.dart' show FitBoundsOptions;

import 'package:provider/provider.dart';
import 'package:auth_app/common/providers/user.dart';
import 'package:auth_app/domain/entities/favourite.dart';
import 'package:auth_app/domain/usecases/get_favourites.dart';
import 'package:auth_app/domain/usecases/add_favourite.dart';
import 'package:auth_app/domain/usecases/delete_favourite.dart';
import 'package:auth_app/data/models/add_favourite_req_params.dart';
import 'package:auth_app/data/models/delete_favourite_req_params.dart';

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

class MapPage extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKeyForBottomSheet;
  final double navBarHeight;

  /// Emits `true` when the search bar gains focus and `false` when it
  /// loses focus.  Parent widgets can use this to hide/show UI elements.
  final ValueChanged<bool>? onSearchFocusChanged;

  const MapPage({
    super.key,
    required this.scaffoldKeyForBottomSheet,
    required this.navBarHeight,
    this.onSearchFocusChanged,
  });

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with TickerProviderStateMixin {
  // Flag to indicate we want to show route details after closing options panel
  bool _pendingShowRouteDetails = false;
  // Flag to indicate we want to show route options after closing details panel (option C)
  bool _pendingShowRouteOptions = false;
  // Flag to indicate we want to show route details after closing options panel
  //bool _pendingShowRouteDetails = false;
  // Camera state for building highlight/zoom restoration
  mb.CameraOptions? _previousCameraOptions;
  bool _isBuildingZoomed = false;
  static const _animDuration = Duration(milliseconds: 250);
  late double _navBarHeight; // ← height from bottom-nav

  // ── live flags & sheet controllers ───────────────────────────────
  bool _creatingRoute = false;
  PersistentBottomSheetController? _plannerSheetCtr;
  OverlayEntry? _plannerOverlay; // top Route-Plan bar overlay
  AnimationController? _plannerAnimCtr; // drives its in/out animation
  bool _panelClosingStarted = false;
  double _lastPanelPos = 1.0; // track previous slide position
  bool _searchActive = false;
  Pointer? _buildingPanelPointer;
  LatLng? _coordinatePanelLatLng; // NEW: for coordinate panel

  final FocusNode _searchFocusNode = FocusNode();

  // Sliding-up-panel controller
  final PanelController _panelController = PanelController();
  ValueNotifier<Map<TravelMode, RouteData>>? _panelRoutes;
  TravelMode? _panelMode;

  // true ⇒ bottom–sheet shows the full timeline instead of the options card
  bool _showRouteDetails = false;

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
  List<InteractiveAnnotation> _interactiveAnnotations = [];

  List<Pointer> _allPointers = [];
  List<Pointer> _suggestions = [];
  LatLng? _currentLocation;

  bool _markerTapJustHandled = false;

  bool _is3D = false;

  final Map<String, Uint8List> _categoryImageCache = {};
  bool _imagesLoaded = false;

  mb.MapboxMap? _mapboxMap;
  Map<String, Object>? _mapConfig;

  MapTheme _currentMapTheme = MapTheme.day;
  Timer? _themeTimer;

  VoidCallback? _clearBuildingHighlight;

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
  bool _isRaining = false;
  late final Widget _persistentWeather = WeatherWidget(
    key: const ValueKey('persistentWeather'),
    location: const LatLng(matheLat, matheLon),
    onWeatherChanged: (weather) {
      print('[DEBUG] Weather changed: ${weather.description}');
      if (weather.description.toLowerCase().contains('rain') ||
          weather.description.toLowerCase().contains('drizzle')) {
        setState(() => _isRaining = true);
      } else {
        setState(() => _isRaining = false);
      }
    },
  );

  String? _activeCategory;
  Color? _activeCategoryColor;
  List<Pointer> _activeCategoryPointers = [];

  // ── lifecycle ────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _navBarHeight = widget.navBarHeight;
    _initializeMap(); // Create separate initialization method
    _currentMapTheme = ThemeManager.getCurrentTheme();
    print(_currentMapTheme.toString());
    _searchCtl.addListener(_onSearchChanged);
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
    _startThemeTimer();
  }

  void _startThemeTimer() {
    _updateThemeTimer();
  }

  void _updateThemeTimer() {
    _themeTimer?.cancel();

    _themeTimer = Timer(Duration(minutes: 5), () {
      final newTheme = ThemeManager.getCurrentTheme();
      if (_currentMapTheme != newTheme) {
        setState(() {
          _currentMapTheme = newTheme;
        });
      }
      _updateThemeTimer(); // Schedule next update
    });
  }

  Future<void> _initializeMap() async {
    await _preloadCategoryImages();
    setState(() => _imagesLoaded = true);
    await _loadBuildingMarkers();
    await _goToCurrentLocation();
  }

  Future<void> _preloadCategoryImages() async {
    final categories = [
      'mensa',
      'cafe',
      'library',
      'default',
      'destination',
      'favourite',
    ];
    for (final cat in categories) {
      final assetPath = getPinAssetForCategory(cat);
      final byteData = await rootBundle.load(assetPath);
      _categoryImageCache[cat] = byteData.buffer.asUint8List();
    }
  }

  Future<LatLng?> getCurrentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return null;
      }
    }
    try {
      final pos = await Geolocator.getCurrentPosition();
      _currentLocation = LatLng(pos.latitude, pos.longitude);
      return LatLng(pos.latitude, pos.longitude);
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    _themeTimer?.cancel();
    _buildingZoomTimer?.cancel();

    if (_plannerOverlay != null) {
      try {
        _plannerOverlay?.remove();
        _plannerOverlay = null;
      } catch (e) {
        print('Overlay removal error during dispose: $e');
      }
    }

    if (_panelController.isPanelOpen && mounted) {
      try {
        _panelController.close();
      } catch (e) {
        // Ignore errors during disposal
        print('Panel close error during dispose: $e');
      }
    }

    _mapAnimController?.dispose();
    _plannerAnimCtr?.dispose(); // ← tidy up Route-Plan bar anim

    _searchCtl.dispose();
    _searchFocusNode.dispose();

    super.dispose();
  }

  // /// Snap the sheet to the nearest predefined stop once the user lifts their finger.
  // void _snapToNearest() {
  //   const stops = [0.10, 0.15, 0.20, 0.25, 0.30];
  //   final current = _sheetCtrl.size;
  //   final closest = stops.reduce(
  //     (a, b) => (a - current).abs() < (b - current).abs() ? a : b,
  //   );
  //   _sheetCtrl.animateTo(
  //     closest,
  //     duration: const Duration(milliseconds: 200),
  //     curve: Curves.easeOut,
  //   );
  // }

  /* ───────────────────────── Panel helpers ───────────────────── */
  void _clearPanelData() {
    _panelRoutes = null;
    _panelMode = null;
    _showRouteDetails = false;
  }

  // Returns true if any panel (building or route or coords) is open
  bool get _panelActive =>
      _buildingPanelPointer != null ||
      _panelRoutes != null ||
      _coordinatePanelLatLng != null ||
      (_activeCategory != null && _activeCategoryPointers.isNotEmpty);
  bool get _isMensaPanel =>
      _buildingPanelPointer != null &&
      _buildingPanelPointer!.category.toLowerCase() == 'canteen';

  // ── build ────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // Show loading indicator while images are loading
    if (!_imagesLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
      final availableWidth =
          panelWidth - closeButtonWidth; // Adjust the width for the text

      // Create a TextPainter to measure the rendered size of p.name
      final TextPainter titlePainter = TextPainter(
        text: TextSpan(text: p.name, style: titleStyle),
        textDirection: TextDirection.ltr,
        maxLines: 10, // Set a large number for maxLines
      )..layout(maxWidth: availableWidth); // Use the adjusted width

      // Calculate the total height using line metrics
      final lineMetrics = titlePainter.computeLineMetrics();
      final totalHeight = lineMetrics.fold(
        0.0,
        (sum, line) => sum + line.height,
      );

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
      final headerContentHeight =
          titleHeight + betweenTitleAndCategory + categoryHeight;
      // Ensure header accounts for the larger of text block or close button
      final headerBlockHeight = headerContentHeight < closeButtonHeight
          ? closeButtonHeight
          : headerContentHeight;
      final headerTotal =
          topPadding +
          handleHeight +
          betweenHandleAndHeader +
          headerBlockHeight +
          afterHeader;
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
    } else if (_coordinatePanelLatLng != null) {
      maxHeight =
          MediaQuery.of(context).size.height * 0.25; // 35% of screen height
    } else if (_panelRoutes != null) {
      // Dynamically calculate height for route details panel
      if (_showRouteDetails) {
        final data = _panelRoutes!.value[_panelMode ?? TravelMode.walk];
        // Estimate: header + (segmentHeight * segmentCount) + padding
        const double headerHeight = 120;
        const double segmentHeight = 80;
        const double padding = 40;
        final int segmentCount = data?.segments.length ?? 0;
        double total = headerHeight + (segmentHeight * segmentCount) + padding;
        double maxAllowed = MediaQuery.of(context).size.height * 0.85;
        double minAllowed = 180.0;
        maxHeight = total.clamp(minAllowed, maxAllowed);
      } else {
        maxHeight = MediaQuery.of(context).size.height * 0.31;
      }

      // ────────────────────────────────────────────────────────────────
      // Otherwise neither sheet is active, we’ll show a small handle only
      // ────────────────────────────────────────────────────────────────
    } else if (_activeCategory != null && _activeCategoryPointers.isNotEmpty) {
      maxHeight = MediaQuery.of(context).size.height * 0.7;
    } else {
      maxHeight = 180.0; // default “peek” height if nothing else is open
    }

    // ─────────────────────────────────────────────────────────────────
    // Now build the Scaffold with our SlidingUpPanel, using the computed height
    // ─────────────────────────────────────────────────────────────────
    return PopScope(
      canPop: false, // Always intercept the back button
      onPopInvoked: (bool didPop) async {
        if (didPop) return; // Already handled

        // Handle back button press based on current state - priority order:

        // 1. If search is active, close search first
        if (_searchActive) {
          _searchFocusNode.unfocus();
          setState(() => _searchActive = false);
          _notifyNavBar(false);
          return;
        }

        // 2. If route planning is active, close route planner
        if (_creatingRoute || _plannerOverlay != null) {
          await _dismissPlannerOverlay();
          setState(() => _creatingRoute = false);
          _routesNotifier.value = {};
          _currentMode = TravelMode.walk;
          _clearPanelData();
          _notifyNavBar(false);
          if (_panelController.isPanelOpen) {
            _panelController.close();
          }
          return;
        }

        // 3. If any panel is open, close it
        if (_panelActive) {
          // Clear building highlight if active
          if (_clearBuildingHighlight != null) {
            _clearBuildingHighlight!();
          }

          // Restore camera if zoomed to building
          if (_isBuildingZoomed &&
              _mapboxMap != null &&
              _previousCameraOptions != null) {
            _mapboxMap!.easeTo(
              _previousCameraOptions!,
              mb.MapAnimationOptions(duration: 500, startDelay: 0),
            );
            _isBuildingZoomed = false;
            _previousCameraOptions = null;
          }

          // Clear all panel states
          setState(() {
            _buildingPanelPointer = null;
            _coordinatePanelLatLng = null;
            _activeCategory = null;
            _activeCategoryColor = null;
            _activeCategoryPointers = [];
          });

          // Reset markers to show all
          _filterMarkersByCategory(null);

          // Close the panel
          _panelController.close();
          _notifyNavBar(false);

          return;
        }

        // 4. Nothing is active, exit app
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          SystemNavigator.pop(); // Close app
        }
      },
      child: Scaffold(
        body: SlidingUpPanel(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          controller: _panelController, // the PanelController instance
          minHeight: 0,
          maxHeight: maxHeight, // our dynamic max height
          snapPoint: 0.29, // when you drag up, snaps at 29% if release early
          isDraggable: true, // allow dragging
          onPanelSlide: (pos) {
            // Removed auto‐dismiss on slight downward drag
            // if (!_panelClosingStarted &&
            //     _plannerAnimCtr?.isCompleted == true &&
            //     pos < _lastPanelPos && // downward motion
            //     pos < 0.95) {
            //   _panelClosingStarted = true;
            //   _dismissPlannerOverlay();
            // }
            _lastPanelPos = pos; // update tracker
          },
          panelBuilder: (sc) {
            // Category list has highest priority
            if (_activeCategory != null && _activeCategoryPointers.isNotEmpty) {
              return _buildCategoryListPanel(sc);
            }

            // Building info panel
            if (_buildingPanelPointer != null) {
              final p = _buildingPanelPointer!;
              return BuildingSlideWindow(
                title: p.name,
                category: p.category,
                onCreateRoute: () async {
                  // Slide down the panel, then open route options with slide up
                  setState(() => _buildingPanelPointer = null);
                  _panelController.close();
                  await Future.delayed(_animDuration);
                  setState(() {
                    _creatingRoute = true;
                    _currentMode = TravelMode.walk;
                    _routesNotifier.value = {};
                    _panelRoutes = _routesNotifier;
                    _panelMode = TravelMode.walk;
                    _routeDestination = LatLng(p.lat, p.lng);
                  });
                  _startRouteFlow(LatLng(p.lat, p.lng));
                },
                onAddToFavourites: () async {
                  final user = Provider.of<UserProvider>(
                    context,
                    listen: false,
                  ).user;
                  if (user == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please log in to use favourites!'),
                      ),
                    );
                    return;
                  }
                  final favourites = Provider.of<UserProvider>(
                    context,
                    listen: false,
                  ).favourites;
                  final isFavourite = favourites.any(
                    (f) => f.name == p.name && f.lat == p.lat && f.lng == p.lng,
                  );

                  Future<void> updateFavourites() async {
                    final updated = await sl<GetFavouritesUseCase>().call();
                    if (!mounted) return;
                    updated.fold(
                      (error) =>
                          print('[DEBUG] Failed to reload favourites: $error'),
                      (favs) {
                        if (!mounted) return;
                        Provider.of<UserProvider>(
                          context,
                          listen: false,
                        ).setFavourites(favs);
                      },
                    );
                  }

                  if (isFavourite) {
                    // Remove from favourites
                    final fav = favourites.firstWhere(
                      (f) =>
                          f.name == p.name && f.lat == p.lat && f.lng == p.lng,
                    );
                    final result = await sl<DeleteFavouriteUseCase>().call(
                      param: DeleteFavouriteReqParams(favouriteId: fav.id),
                    );
                    result.fold(
                      (error) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to remove favourite: $error'),
                          ),
                        );
                      },
                      (_) async {
                        await updateFavourites();
                        setState(() {});
                      },
                    );
                  } else {
                    // Add to favourites
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) =>
                          const Center(child: CircularProgressIndicator()),
                    );
                    final result = await sl<AddFavouriteUseCase>().call(
                      param: AddFavouriteReqParams(
                        name: p.name,
                        latitude: p.lat,
                        longitude: p.lng,
                      ),
                    );
                    Navigator.of(context).pop();

                    result.fold(
                      (error) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to add favourite: $error'),
                          ),
                        );
                      },
                      (_) async {
                        await updateFavourites();
                        setState(() {});
                      },
                    );
                  }
                },
                onClose: () {
                  setState(() => _buildingPanelPointer = null);
                  _panelController.close();
                  _notifyNavBar(false);
                },
                onShowMenu: p.category.toLowerCase() == 'canteen'
                    ? () async {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) =>
                              const Center(child: CircularProgressIndicator()),
                        );
                        final result = await sl<GetMensaMenuUseCase>().call(
                          param: GetMenuReqParams(mensaName: p.name),
                        );
                        Navigator.of(context).pop();
                        result.fold(
                          (error) => ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('error: $error')),
                          ),
                          (menu) =>
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,

                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(24),
                                  ),
                                ),
                                builder: (_) => Container(
                                  height:
                                      MediaQuery.of(context).size.height * 0.9,
                                  child: WeeklyMensaPlan(menu: menu),
                                ),
                              ).then((_) {
                                setState(() => _buildingPanelPointer = null);
                                _panelController.close();
                                _notifyNavBar(false);
                              }),
                        );
                      }
                    : null,
              );
            }
            if (_panelRoutes != null) {
              // ▒▒▒  decide which flavour to render  ▒▒▒
              if (_showRouteDetails) {
                final data = _panelRoutes!.value[_panelMode ?? TravelMode.walk];
                // Make the Route Details panel taller than the options panel
                return SizedBox(
                  height:
                      MediaQuery.of(context).size.height *
                      0.75, // 75% of screen height
                  child: RouteDetailsPanel(
                    data: data,
                    deriveStartName: (data) {
                      if (data == null) return 'Start';
                      final raw = data.customStartName;
                      if (raw != null && raw.trim().isNotEmpty) return raw;
                      final segs = data.segments;
                      if (segs != null && segs.isNotEmpty) {
                        return segs.first.fromStop ??
                            segs.first.toStop ??
                            'Start';
                      }
                      return 'Start';
                    },
                    deriveEndName: (data) {
                      if (data == null) return 'Destination';
                      final raw = data.customEndName;
                      if (raw != null && raw.trim().isNotEmpty) return raw;
                      final segs = data.segments;
                      if (segs != null && segs.isNotEmpty) {
                        return segs.last.toStop ??
                            segs.last.fromStop ??
                            'Destination';
                      }
                      return 'Destination';
                    },
                    onClose: () {
                      setState(() {
                        _showRouteDetails = false;
                        _pendingShowRouteOptions = true;
                      });
                      _panelController.close();
                    },
                  ),
                );
              } else {
                // Route Options panel keeps its original height logic
                return RouteOptionsPanel(
                  routesNotifier: _panelRoutes!,
                  currentMode: _panelMode ?? TravelMode.walk,
                  scrollController: sc,
                  onModeChanged: _changeTravelMode,
                  onClose: () {
                    _panelController.close();
                    _notifyNavBar(false);
                  },
                  onShowDetails: () {
                    setState(() {
                      _pendingShowRouteDetails = true;
                    });
                    _panelController.close();
                  },
                );
              }
            }
            // ── helpers to derive start / end labels if server left them blank ─────────
            String _deriveStartName(RouteData? data) {
              if (data == null) return 'Start';
              final raw = data.customStartName;
              if (raw != null && raw.trim().isNotEmpty) return raw;
              final segs = data.segments;
              if (segs != null && segs.isNotEmpty) {
                return segs.first.fromStop ?? segs.first.toStop ?? 'Start';
              }
              return 'Start';
            }

            String _deriveEndName(RouteData? data) {
              if (data == null) return 'Destination';
              final raw = data.customEndName;
              if (raw != null && raw.trim().isNotEmpty) return raw;
              final segs = data.segments;
              if (segs != null && segs.isNotEmpty) {
                return segs.last.toStop ?? segs.last.fromStop ?? 'Destination';
              }
              return 'Destination';
            }

            if (_coordinatePanelLatLng != null) {
              final latlng = _coordinatePanelLatLng!;
              return ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28), // Match route options sheet
                ),
                child: Material(
                  color: Colors.white,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      12,
                      20,
                      MediaQuery.of(context).padding.bottom,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Coordinates',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${latlng.latitude.toStringAsFixed(6)}, '
                                    '${latlng.longitude.toStringAsFixed(6)}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 36,
                              height: 36,
                              margin: const EdgeInsets.only(left: 8, top: 0),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey.shade200,
                                // boxShadow: [
                                //   BoxShadow(
                                //     color: Colors.black.withOpacity(0.06),
                                //     blurRadius: 4,
                                //     offset: const Offset(0, 2),
                                //   ),
                                // ],
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                splashRadius: 18,
                                padding: const EdgeInsets.all(0),
                                onPressed: () {
                                  setState(() => _coordinatePanelLatLng = null);
                                  _panelController.close();
                                  _notifyNavBar(false);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 56,
                                child: GradientActionButton(
                                  onPressed: () {
                                    setState(
                                      () => _coordinatePanelLatLng = null,
                                    );
                                    _panelController.close();
                                    _startRouteFlow(latlng);
                                  },
                                  icon: Icons.directions,
                                  label: 'Create Route',
                                  colors: const [
                                    Color(0xFF7B61FF),
                                    Color(0xFFEA5CFF),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
          onPanelClosed: () async {
            // Option C: If we just closed details and want to go back to options
            if (_pendingShowRouteOptions) {
              setState(() {
                _showRouteDetails = false;
                _pendingShowRouteOptions = false;
              });
              _panelController.open();
              return;
            }
            if (_pendingShowRouteDetails) {
              setState(() {
                _showRouteDetails = true;
                _pendingShowRouteDetails = false;
              });
              _panelController.open();
              return;
            }
            if (_panelController.panelPosition == 0.0) {
              // Always clear building highlight when panel closes
              if (_clearBuildingHighlight != null) {
                _clearBuildingHighlight!();
              }
              setState(() {
                _buildingPanelPointer = null;
                _coordinatePanelLatLng = null;
                _activeCategory = null;
                _activeCategoryPointers = [];
              });

              _filterMarkersByCategory(null);
              // Restore previous camera if we zoomed to a building
              if (_isBuildingZoomed &&
                  _mapboxMap != null &&
                  _previousCameraOptions != null) {
                _mapboxMap!.easeTo(
                  _previousCameraOptions!,
                  mb.MapAnimationOptions(duration: 500, startDelay: 0),
                );
                _isBuildingZoomed = false;
                _previousCameraOptions = null;
              }

              // if the user *tapped* the close handle without dragging,
              // the bar is still up → dismiss it now
              await _dismissPlannerOverlay();
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
              // MapboxMapWidget(routePoints: [], busStops: [], currentLocation: _currentLocation),

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
              // --- Animated Search Bar and Category Navigation ---
              AnimatedSlide(
                offset: (_panelActive || _creatingRoute)
                    ? const Offset(0, -0.06)
                    : Offset.zero,
                duration: _animDuration,
                curve: Curves.easeInOut,
                child: AnimatedOpacity(
                  opacity: (_panelActive || _creatingRoute) ? 0.0 : 1.0,
                  duration: _animDuration,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                          if (category != null) {
                            _showCategoryListPopup(
                              category,
                              color ?? Colors.blue,
                            );
                          }
                        },
                        onSuggestionSelected: (p) {
                          final dest = LatLng(p.lat, p.lng);
                          _animatedMapboxMove(dest, 18);
                          _onMapTap(dest);
                        },
                        focusNode: _searchFocusNode,
                      ),
                      // If you want to show the CategoryNavigationBar here, add it below:
                      // CategoryNavigationBar(...),
                    ],
                  ),
                ),
              ),
              _build3DButton(),

              _buildThemesButton(),
              _buildRainButton(),

              if (!_panelActive) _buildTUButton(),
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
              if (_activeCategory != null)
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    child: CategoryTopBar(
                      title: _activeCategory!,
                      onClose: () {
                        setState(() {
                          _activeCategory = null;
                          _activeCategoryColor = null;
                          _activeCategoryPointers = [];
                        });
                        _filterMarkersByCategory(null);
                        _animatedMapboxMove(LatLng(52.5125, 13.3256), 15.0);
                        _panelController.close();
                        _notifyNavBar(false);
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Opens building info panel
  void _showBuildingPanel(Pointer p) async {
    setState(() => _buildingPanelPointer = p);
    _panelController.open();
    _notifyNavBar(true); // Hide nav bar when opening
  }

  // ───────────────────────────────────────────────────────────
  // Start full routing flow: top bar + bottom-sheet directions
  // ───────────────────────────────────────────────────────────
  Future<void> _startRouteFlow(
    LatLng destination, {
    bool skipPanelOpen = false,
  }) async {
    // Optionally skip opening the panel if already open (for swap animation)
    if (!skipPanelOpen) {
      _panelController.open();
      _notifyNavBar(true); // Hide nav bar when opening
    }

    _routeDestination = destination; // remember for later
    if (_plannerOverlay != null) return;

    _panelClosingStarted = false; // reset every time we open the flow
    setState(() {
      _creatingRoute = true;
      _currentMode = TravelMode.walk; // reset to walking
      _routesNotifier.value = {}; // drop any old routes
      // Ensure the panel is never blank: always set these immediately
      _panelRoutes = _routesNotifier;
      _panelMode = TravelMode.walk;
    });

    /* ────────────────────────────────────────────────────────────
     *  Animated Route-Plan bar
     *  – slides in + fades in (like the search bar),
     *  – slides out + fades out on cancel.
     * ─────────────────────────────────────────────────────────── */
    final currentLocation = await getCurrentLocation();
    if (_plannerOverlay == null) {
      _plannerAnimCtr = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      );
      final curved = CurvedAnimation(
        parent: _plannerAnimCtr!,
        curve: Curves.easeInOut,
      );

      // Same feel as the search-bar: only 6 % of its height moves.
      final slide = Tween<Offset>(
        begin: const Offset(0, -0.06),
        end: Offset.zero,
      ).animate(curved);

      final fade = Tween<double>(begin: 0, end: 1).animate(curved);

      _plannerOverlay = OverlayEntry(
        builder: (_) => SlideTransition(
          position: slide,
          child: FadeTransition(
            opacity: fade,
            child: Align(
              alignment: Alignment.topCenter,
              child: RoutePlanBar(
                currentLocation: currentLocation,
                initialDestination: destination,
                allPointers: _allPointers,
                onCancelled: () async {
                  await _dismissPlannerOverlay(); // animate-out first
                  setState(() => _creatingRoute = false);
                  _notifyNavBar(false); // show it again
                  // also close the Sliding-up panel if it is open
                  if (_panelController.isPanelOpen) {
                    _panelController.close();
                  }
                },
                // update signature to receive start and end labels
                onChanged: (route, startLabel, endLabel) async {
                  // 1. recalc the route in place
                  await _handleCreateRoute(route, rebuildOnly: true);

                  // 2. once that's done, grab all the points & fit the map
                  final data = _routesNotifier.value[_currentMode];
                  final pts =
                      data?.segments.expand((s) => s.path).toList() ?? [];
                  if (pts.isNotEmpty) {
                    final bounds = LatLngBounds.fromPoints(pts);
                    _animatedMapboxMove(bounds.center, 16.0);
                  }
                },
              ),
            ),
          ),
        ),
      );

      if (_plannerOverlay != null) {
        Overlay.of(context, rootOverlay: true)!.insert(_plannerOverlay!);
      }
      _plannerAnimCtr!.forward(); // animate it in
    }

    // first time in → rebuildOnly=false (default)
    _handleCreateRoute([currentLocation!, _routeDestination!]);
  }

  IconData _getThemeIcon(MapTheme theme) {
    switch (theme) {
      case MapTheme.dawn:
        return Icons.wb_twilight;
      case MapTheme.day:
        return Icons.wb_sunny;
      case MapTheme.dusk:
        return Icons.wb_twilight;
      case MapTheme.night:
        return Icons.nightlight;
    }
  }

  // ── search listener ──────────────────────────────────────────────
  void _onSearchChanged() {
    final q = _searchCtl.text.trim().toLowerCase();
    setState(() {
      _suggestions = q.isEmpty
          ? []
          : _allPointers.where((p) {
              // Check if pointer name matches
              final nameMatches = p.name.toLowerCase().contains(q);

              // Check if any room in this pointer matches
              final roomMatches = p.rooms.any(
                (room) => room.toLowerCase().contains(q),
              );

              // Include pointer if either name or any room matches
              return nameMatches || roomMatches;
            }).toList();
    });
  }

  // ── map widget + helpers ─────────────────────────────────────────
  // --- Camera change listener for building zoom state ---
  VoidCallback? _removeCameraListener;
  bool _isAnimatingToBuilding = false;
  Timer? _buildingZoomTimer;
  void _handleCameraChanged(dynamic data) {
    // Only care if we are in building zoomed state and not animating
    if (_isBuildingZoomed && !_isAnimatingToBuilding) {
      _isBuildingZoomed = false;
      _previousCameraOptions = null;
      // Remove this listener after first trigger
      if (_removeCameraListener != null) {
        _removeCameraListener!();
        _removeCameraListener = null;
      }
    }
  }

  Widget _buildFlutterMap() {
    final route = _routesNotifier.value[_currentMode];
    final segments = route?.segments ?? [];

    LatLng _closest(LatLng s, List<LatLng> line) {
      double best = double.infinity;
      if (line.isEmpty) return s; // no points, return start point
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

    // 1. Favourites & Icon aus Provider/Cache holen
    final favourites = Provider.of<UserProvider>(context).favourites;
    final favouriteIcon = _categoryImageCache['favourite'];
    if (favouriteIcon == null) {
      // Show loading indicator while icon is loading
      return const Center(child: CircularProgressIndicator());
    }

    // 2. Marker-Annotations
    final allAnnotations = [
      ..._interactiveAnnotations, // normal POIs
      ...buildFavouriteAnnotations(favourites, favouriteIcon), // Favourites!
    ];

    return MapboxMapWidget(
      markerAnnotations: _interactiveAnnotations,
      navBarHeight: _navBarHeight,
      destinationLatLng: _coordinatePanelLatLng,
      markerImageCache: _categoryImageCache,
      busStopMarkers: busMarkers,
      isRaining: _isRaining,
      segments: segments,
      mapTheme: _currentMapTheme,
      onMapTap: _onMapTap,
      onMapCreated: (map) {
        _mapboxMap = map;
      },
      parentContext: context,
      onClearHighlightController: (clearFn) {
        _clearBuildingHighlight = clearFn;
      },
      onCameraChanged: (data) {
        _handleCameraChanged(data);
      },
      routePoints: const [],
    );
  }

  Future<List<mb.PointAnnotationOptions>> convertMarkersToAnnotations(
    List<Marker> markers,
    Uint8List iconBytes,
  ) async {
    return markers.map((marker) {
      return mb.PointAnnotationOptions(
        geometry: mb.Point(
          coordinates: mb.Position(
            marker.point.longitude,
            marker.point.latitude,
          ),
        ),
        iconSize: 1.0,
        // image: , // shared image asset for all markers
      );
    }).toList();
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
          child: GradientWidget(
            colors: const [Color(0xFF7B61FF), Color(0xFFEA5CFF)],
            child: const Icon(Icons.my_location, color: Colors.white, size: 24),
          ),
        ),
      ),
    ),
  );

  Widget _build3DButton() => Positioned(
    top: 180,
    right: 20,
    child: AnimatedSlide(
      offset: _searchActive
          ? const Offset(0, -1)
          : Offset.zero, // Slide up when search is active
      duration: _animDuration,
      curve: Curves.easeInOut,
      child: AnimatedOpacity(
        opacity: _searchActive ? 0 : 1, // Fade out when search is active
        duration: _animDuration,
        child: FloatingActionButton.extended(
          heroTag: 'toggle3d',
          backgroundColor: Colors.white,
          label: GradientWidget(
            colors: const [Color(0xFF7B61FF), Color(0xFFEA5CFF)],
            child: Text(
              _is3D ? '2D' : '3D',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          onPressed: () {
            setState(() => _is3D = !_is3D);
            if (_mapboxMap != null) {
              _mapboxMap!.easeTo(
                mb.CameraOptions(pitch: _is3D ? 60.0 : 0.0),
                mb.MapAnimationOptions(duration: 600, startDelay: 0),
              );
            }
          },
        ),
      ),
    ),
  );

  Widget _buildRainButton() => Positioned(
    top: 320,
    right: 20,
    child: AnimatedSlide(
      offset: _searchActive
          ? const Offset(0, -1)
          : Offset.zero, // Slide up when search is active
      duration: _animDuration,
      curve: Curves.easeInOut,
      child: AnimatedOpacity(
        opacity: _searchActive ? 0 : 1, // Fade out when search is active
        duration: _animDuration,
        child: FloatingActionButton(
          heroTag: 'rain_toggle',
          backgroundColor: Colors.white,
          onPressed: () {
            setState(() => _isRaining = !_isRaining);
          },
          child: GradientWidget(
            colors: const [Color(0xFF7B61FF), Color(0xFFEA5CFF)],
            child: Icon(Icons.thunderstorm, color: Colors.white, size: 22),
          ),
        ),
      ),
    ),
  );

  Widget _buildThemesButton() => Positioned(
    top: 250,
    right: 20,
    child: AnimatedSlide(
      offset: _searchActive
          ? const Offset(0, -1)
          : Offset.zero, // Slide up when search is active
      duration: _animDuration,
      curve: Curves.easeInOut,
      child: AnimatedOpacity(
        opacity: _searchActive ? 0 : 1, // Fade out when search is active
        duration: _animDuration,
        child: FloatingActionButton(
          heroTag: 'theme_toggle',
          backgroundColor: Colors.white,
          onPressed: () {
            // Cycle through themes manually
            final currentIndex = MapTheme.values.indexOf(_currentMapTheme);
            final nextIndex = (currentIndex + 1) % MapTheme.values.length;
            setState(() {
              _currentMapTheme = MapTheme.values[nextIndex];
            });
          },
          child: GradientWidget(
            colors: const [Color(0xFF7B61FF), Color(0xFFEA5CFF)],
            child: Icon(
              _getThemeIcon(_currentMapTheme),
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ),
    ),
  );

  Widget _buildTUButton() => Positioned(
    bottom: _bottomOffset,
    right: 90,
    child: AnimatedSlide(
      offset: _searchActive ? const Offset(0, 1) : Offset.zero,
      duration: _animDuration,
      curve: Curves.easeInOut,
      child: AnimatedOpacity(
        opacity: _searchActive ? 0 : 1,
        duration: _animDuration,
        child: FloatingActionButton.extended(
          heroTag: 'tubutton',
          backgroundColor: Colors.white,
          label: GradientWidget(
            colors: const [Color(0xFF7B61FF), Color(0xFFEA5CFF)],
            child: const Text(
              'TU',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          // icon: const Icon(Icons.school, color: Colors.blue),
          onPressed: () {
            _animatedMapboxMove(LatLng(52.5125, 13.3269), 15.0);
            _resetToDefaultState();
          },
        ),
      ),
    ),
  );

  void _resetToDefaultState() {
    // Close any open panels
    if (_panelController.isPanelOpen) {
      _panelController.close();
    }

    // Clear any active states
    setState(() {
      _buildingPanelPointer = null;
      _coordinatePanelLatLng = null;
      _activeCategory = null;
      _activeCategoryColor = null;
      _activeCategoryPointers = [];
    });

    // Reset markers to show all
    _filterMarkersByCategory(null);

    // Clear building highlight if active
    if (_clearBuildingHighlight != null) {
      _clearBuildingHighlight!();
    }

    // Restore camera if zoomed to building
    if (_isBuildingZoomed && _mapboxMap != null) {
      _isBuildingZoomed = false;
      _previousCameraOptions = null;
    }

    _notifyNavBar(false);
  }

  // ── markers, filter & search ─────────────────────────────────────
  Uint8List _loadImageBytesForCategory(String category) {
    final cat = category.trim().toLowerCase();
    switch (cat) {
      case 'café':
      case 'cafe':
        return _categoryImageCache['cafe']!;
      case 'library':
      case 'libraries':
        return _categoryImageCache['library']!;
      case 'canteen':
      case 'mensa':
        return _categoryImageCache['mensa']!;
      default:
        return _categoryImageCache['default']!;
    }
  }

  Future<void> _loadBuildingMarkers() async {
    var response = await sl<GetPointersUseCase>().call();
    response.fold(
      (error) {
        debugPrint('Error loading pointers: $error');
        return;
      },
      (pointers) async {
        _allPointers = pointers;
        final m = _allPointers.map((p) {
          return mapMarker(p);
        }).toList();

        final List<InteractiveAnnotation> annotations = [];

        for (final p in _allPointers) {
          annotations.add(mapBoxMarker(p));
        }

        setState(() {
          _interactiveAnnotations = annotations;
          _markers = m;
        });
      },
    );
  }

  void _searchMarkers(String q) {
    final filtered = _allPointers.where((p) {
      // Check if pointer name matches
      final nameMatches = p.name.toLowerCase().contains(q);

      // Check if any room in this pointer matches
      final roomMatches = p.rooms.any((room) => room.toLowerCase().contains(q));

      // Include pointer if either name or any room matches
      return nameMatches || roomMatches;
    }).toList();

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

  void _filterMarkersByCategory(String? category) {
    List<Pointer> filteredPointers;
    if (category == null) {
      filteredPointers = _allPointers;
    } else {
      final cat = category.trim().toLowerCase();
      filteredPointers = _allPointers.where((p) {
        final pCat = p.category.trim().toLowerCase();
        if (cat.contains('café')) return pCat == 'cafe' || pCat == 'café';
        if (cat.contains('librar')) return pCat.contains('librar');
        if (cat.contains('canteen') || cat.contains('mensa'))
          return pCat == 'canteen' || pCat == 'mensa';
        if (cat.contains('study room')) return pCat == 'study room';
        return false;
      }).toList();
    }

    final newMarkers = filteredPointers
        .map((pointer) => mapMarker(pointer))
        .toList();
    final newAnnotations = filteredPointers
        .map((pointer) => mapBoxMarker(pointer))
        .toList();

    setState(() {
      _markers = newMarkers;
      if (_interactiveAnnotations.length != newAnnotations.length) {
        _interactiveAnnotations = newAnnotations;
      }
    });

    if (category != null && filteredPointers.isNotEmpty) {
      final avgLat =
          filteredPointers.map((p) => p.lat).reduce((a, b) => a + b) /
          filteredPointers.length;
      final avgLng =
          filteredPointers.map((p) => p.lng).reduce((a, b) => a + b) /
          filteredPointers.length;

      // Offsets: (0.001 = ca. 110m)
      final offsetLng = avgLng + 0.0005; // nach Osten
      final offsetLat = avgLat - 0.002; // nach Süden

      final zoom = 14.5; // adjust zoom level

      _animatedMapboxMove(LatLng(offsetLat, offsetLng), zoom);
    }
  }

  Marker mapMarker(Pointer pointer) {
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
  }

  InteractiveAnnotation mapBoxMarker(Pointer pointer) {
    return InteractiveAnnotation(
      options: mb.PointAnnotationOptions(
        geometry: mb.Point(coordinates: mb.Position(pointer.lng, pointer.lat)),
        iconSize: 2.0,
        image: _loadImageBytesForCategory(pointer.category),
        iconAnchor: mb.IconAnchor.BOTTOM,
      ),
      onTap: () => _onMarkerTap(pointer),
      category: pointer.category,
    );
  }

  List<InteractiveAnnotation> buildFavouriteAnnotations(
    List<FavouriteEntity> favourites,
    Uint8List favouriteIcon,
  ) {
    return favourites.map((fav) {
      return InteractiveAnnotation(
        options: mb.PointAnnotationOptions(
          geometry: mb.Point(coordinates: mb.Position(fav.lng, fav.lat)),
          iconSize: 2.0,
          image: favouriteIcon,
          iconAnchor: mb.IconAnchor.BOTTOM,
        ),
        onTap: () {
          // Optional: open Panel or display info
        },
        category: 'favourite',
      );
    }).toList();
  }

  // ── taps ─────────────────────────────────────────────────────────

  void _onMapTap(LatLng latlng) async {
    if (_markerTapJustHandled) {
      _markerTapJustHandled = false;
      return;
    }
    if (_panelController.isPanelOpen || _plannerOverlay != null) return;

    final building = await sl<FindBuildingAtPoint>().call(point: latlng);
    Pointer? p;
    if (building != null) {
      p = _allPointers.firstWhere(
        (x) => x.name == building.name,
        orElse: () => Pointer(
          name: building.name,
          lat: latlng.latitude,
          lng: latlng.longitude,
          category: 'Building',
        ),
      );
    } else {
      // If no building found, check if tap is close to any pointer (marker)
      const double maxDistanceMeters = 20.0; // adjust as needed
      final Distance dist = Distance();
      final closePointers = _allPointers.where(
        (ptr) =>
            dist.as(LengthUnit.Meter, latlng, LatLng(ptr.lat, ptr.lng)) <
            maxDistanceMeters,
      );
      p = closePointers.isNotEmpty ? closePointers.first : null;
    }

    if (p != null) {
      // Save camera state before zooming to building
      if (_mapboxMap != null && !_isBuildingZoomed) {
        final camState = await _mapboxMap!.getCameraState();
        _previousCameraOptions = mb.CameraOptions(
          center: camState.center,
          zoom: camState.zoom,
          bearing: camState.bearing,
          pitch: camState.pitch,
          padding: camState.padding,
        );
        _isBuildingZoomed = true;
        _isAnimatingToBuilding = true;
        _buildingZoomTimer?.cancel();
        // --- Fit camera to building contour using precomputed coordinates if available ---
        bool fitSuccess = false;
        try {
          List<LatLng> coords = [];
          if (p.contourWKT != null && p.contourWKT!.isNotEmpty) {
            coords = p.contourWKT!;
          }
          if (coords.isNotEmpty) {
            double minLat = coords.first.latitude,
                maxLat = coords.first.latitude;
            double minLng = coords.first.longitude,
                maxLng = coords.first.longitude;
            for (final c in coords) {
              if (c.latitude < minLat) minLat = c.latitude;
              if (c.latitude > maxLat) maxLat = c.latitude;
              if (c.longitude < minLng) minLng = c.longitude;
              if (c.longitude > maxLng) maxLng = c.longitude;
            }
            final bounds = mb.CoordinateBounds(
              southwest: mb.Point(coordinates: mb.Position(minLng, minLat)),
              northeast: mb.Point(coordinates: mb.Position(maxLng, maxLat)),
              infiniteBounds: false,
            );
            final camera = await _mapboxMap!.cameraForCoordinateBounds(
              bounds,
              mb.MbxEdgeInsets(top: 0, left: 0, bottom: 0, right: 0),
              null,
              null,
              null,
              null,
            );
            await _mapboxMap!.easeTo(
              camera,
              mb.MapAnimationOptions(duration: 700, startDelay: 0),
            );
            fitSuccess = true;
          }
        } catch (e) {
          fitSuccess = false;
        }
        if (!fitSuccess) {
          await _mapboxMap!.easeTo(
            mb.CameraOptions(
              center: mb.Point(coordinates: mb.Position(p.lng, p.lat)),
              zoom: 18.0,
            ),
            mb.MapAnimationOptions(duration: 600, startDelay: 0),
          );
        }
        _buildingZoomTimer = Timer(const Duration(milliseconds: 750), () {
          _isAnimatingToBuilding = false;
          _removeCameraListener = () {
            // This disables the callback by setting to null
          };
        });
      } else {
        await _mapboxMap!.easeTo(
          mb.CameraOptions(
            center: mb.Point(coordinates: mb.Position(p.lng, p.lat)),
            zoom: 18.0,
          ),
          mb.MapAnimationOptions(duration: 600, startDelay: 0),
        );
      }
      _showBuildingPanel(p);
    } else {
      setState(() => _coordinatePanelLatLng = latlng);
      _panelController.open();
      _notifyNavBar(true);
    }
  }

  void _onMarkerTap(Pointer p) async {
    if (_plannerOverlay != null) return;
    _markerTapJustHandled = true;

    // Try to find the building entity for this pointer (by name)
    Pointer? building;
    try {
      building = _allPointers.firstWhere((b) => b.name == p.name);
    } catch (_) {
      building = null;
    }

    bool fitSuccess = false;
    if (_mapboxMap != null && !_isBuildingZoomed) {
      final camState = await _mapboxMap!.getCameraState();
      _previousCameraOptions = mb.CameraOptions(
        center: camState.center,
        zoom: camState.zoom,
        bearing: camState.bearing,
        pitch: camState.pitch,
        padding: camState.padding,
      );
      _isBuildingZoomed = true;
      _isAnimatingToBuilding = true;
      _buildingZoomTimer?.cancel();
      // Try to fit to polygon if available
      try {
        if (building != null &&
            building.contourWKT != null &&
            building.contourWKT!.isNotEmpty) {
          final List<LatLng> coords = building.contourWKT!;
          // Calculate bounds
          double minLat = coords.first.latitude, maxLat = coords.first.latitude;
          double minLng = coords.first.longitude,
              maxLng = coords.first.longitude;
          for (final c in coords) {
            if (c.latitude < minLat) minLat = c.latitude;
            if (c.latitude > maxLat) maxLat = c.latitude;
            if (c.longitude < minLng) minLng = c.longitude;
            if (c.longitude > maxLng) maxLng = c.longitude;
          }
          final bounds = mb.CoordinateBounds(
            southwest: mb.Point(coordinates: mb.Position(minLng, minLat)),
            northeast: mb.Point(coordinates: mb.Position(maxLng, maxLat)),
            infiniteBounds: false,
          );
          final camera = await _mapboxMap!.cameraForCoordinateBounds(
            bounds,
            mb.MbxEdgeInsets(
              top: 0,
              left: 0,
              bottom: 0,
              right: 0,
            ), // padding (required, zero)
            null,
            null,
            null,
            null,
          );
          await _mapboxMap!.easeTo(
            camera,
            mb.MapAnimationOptions(duration: 600, startDelay: 0),
          );
          fitSuccess = true;
        }
      } catch (e) {
        // fallback below
      }
      if (!fitSuccess) {
        _animatedMapboxMove(LatLng(p.lat, p.lng), 17.5);
      }
      _buildingZoomTimer = Timer(const Duration(milliseconds: 750), () {
        _isAnimatingToBuilding = false;
        _removeCameraListener = () {
          // This disables the callback by setting to null
        };
      });
    } else {
      _animatedMapboxMove(LatLng(p.lat, p.lng), 17.5);
    }
    _showBuildingPanel(p);
  }

  // ── current location ─────────────────────────────────────────────
  Future<void> _goToCurrentLocation({bool moveMap = false}) async {
    final location = await getCurrentLocation();
    if (moveMap) _animatedMapboxMove(location!, 17);
    setState(() {});
  }

  // ── route creation & sheet ───────────────────────────────────────
  Future<void> _handleCreateRoute(
    List<LatLng> route, {
    bool rebuildOnly = false,
  }) async {
    // ◀── NEW: clear any existing route so the sheet enters its "loading" state
    setState(() {
      _routesNotifier.value = {};
    });

    // existing logic kicks off the find-route calls...
    await RouteLogic.onCreateRoute(
      context: context,
      route: route,
      routesNotifier: _routesNotifier,
      setState: setState,
      animatedMapMove: _animatedMapboxMove,
      mounted: mounted,
      currentMode: _currentMode,
      showRouteOptionsSheet: _showRouteOptionsSheet,
      onModeChanged: (m) async {
        await RouteLogic.onModeChanged(
          context: context,
          mode: m,
          route: route,
          routesNotifier: _routesNotifier,
          setState: setState,
          updateCurrentMode: (nm) => setState(() => _currentMode = nm),
        );
      },
      rebuildOnly: rebuildOnly,
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
    _showRouteDetails = false; // always start in “options” mode
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

  void _animatedMapboxMove(
    LatLng dest,
    double zoom, {
    VoidCallback? onComplete,
  }) {
    if (_mapboxMap == null) return;
    _mapboxMap!.easeTo(
      mb.CameraOptions(
        center: mb.Point(
          coordinates: mb.Position(dest.longitude, dest.latitude),
        ),
        zoom: zoom,
      ),
      mb.MapAnimationOptions(
        duration: 500,
        startDelay: 0,
        // If the SDK supports a callback, use it:
        // callback: (_) => onComplete?.call(),
      ),
    );
    // If no callback support, fallback to Future.delayed
    if (onComplete != null) {
      Future.delayed(const Duration(milliseconds: 500), onComplete);
    }
  }

  // void _showPlannerBar() {
  //   final dest = _currentLocation ?? LatLng(matheLat, matheLon);
  //   _startRouteFlow(dest);
  // }

  /*───────────────────────────────────────────────────────────────
   * Route-Plan bar teardown animation (fade & slide out)
   *──────────────────────────────────────────────────────────────*/
  Future<void> _dismissPlannerOverlay() async {
    if (_plannerOverlay == null) return;

    // Play the reverse animation only if the forward one has finished.
    if (_plannerAnimCtr != null && _plannerAnimCtr!.isCompleted) {
      await _plannerAnimCtr!.reverse();
    }

    _plannerOverlay!.remove();
    _plannerOverlay = null;
    _plannerAnimCtr?.dispose();
    _plannerAnimCtr = null;
  }

  // ── utils ───────────────────────────────────────────────────────
  String getPinAssetForCategory(String cat) {
    switch (cat.trim().toLowerCase()) {
      case 'mensa':
      case 'canteen':
        return 'assets/icons/pin_mensa_64.png';
      case 'café':
      case 'cafe':
        return 'assets/icons/pin_cafe_64.png';
      case 'libraries':
      case 'library':
        return 'assets/icons/pin_library_64.png';
      case 'destination':
        return 'assets/icons/pin_destination_64.png';
      case 'favourite':
        return 'assets/icons/pin_favourite_64.png';
      default:
        return 'assets/icons/pin_building_64.png';
    }
  }

  Future<void> _showCategoryListPopup(String category, Color color) async {
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

    final currentLocation = await getCurrentLocation();

    if (currentLocation != null) {
      filtered.sort((a, b) {
        final distA = Distance().as(
          LengthUnit.Meter,
          currentLocation,
          LatLng(a.lat, a.lng),
        );
        final distB = Distance().as(
          LengthUnit.Meter,
          currentLocation,
          LatLng(b.lat, b.lng),
        );
        return distA.compareTo(distB);
      });
    } else {
      filtered.sort((a, b) => a.name.compareTo(b.name));
    }

    setState(() {
      _activeCategory = category;
      _activeCategoryColor = color;
      _activeCategoryPointers = filtered;
      _currentLocation = currentLocation;
    });

    _filterMarkersByCategory(category);

    _panelController.open();

    // Panel open
    _panelController.animatePanelToPosition(
      0.6, //panel höhe
      duration: Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
    _notifyNavBar(true);
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
      route: [_currentLocation!, _routeDestination!],
      routesNotifier: _routesNotifier,
      setState: setState,
      updateCurrentMode: (m) => setState(() => _currentMode = m),
    );
  }

  void _updateMapConfig() {
    if (_mapConfig == null || _mapboxMap == null) return;
    _mapboxMap?.style.setStyleImportConfigProperties("basemap", _mapConfig!);
  }

  Widget _buildCategoryListPanel(ScrollController sc) {
    //print('Build Category List Panel called');
    return Column(
      children: [
        // Panel handle for dragging
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(top: 12, bottom: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${_activeCategory}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade200,
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  splashRadius: 16,
                  padding: const EdgeInsets.all(4),
                  onPressed: () {
                    setState(() {
                      _activeCategory = null;
                      _activeCategoryColor = null;
                      _activeCategoryPointers = [];
                    });
                    _filterMarkersByCategory(null);
                    _animatedMapboxMove(LatLng(52.5125, 13.3256), 15.0);
                    _panelController.close();
                    _notifyNavBar(false);
                  },
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Scrollable list of category items
        Expanded(
          child: ListView.builder(
            controller: sc,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _activeCategoryPointers.length,
            itemBuilder: (context, i) {
              final p = _activeCategoryPointers[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Image.asset(
                    getPinAssetForCategory(p.category),
                    width: 32,
                    height: 32,
                  ),
                  title: Text(
                    p.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Builder(
                        builder: (_) {
                          if (_currentLocation == null) {
                            return const Text(
                              'None of places can be loaded',
                              style: TextStyle(color: Colors.red),
                            );
                          }
                          final distInMeters = Distance().as(
                            LengthUnit.Meter,
                            _currentLocation!,
                            LatLng(p.lat, p.lng),
                          );
                          return Text('${distInMeters.toStringAsFixed(0)} m');
                        },
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.directions, color: Colors.blue),
                    onPressed: () {
                      setState(() {
                        _activeCategory = null;
                        _activeCategoryColor = null;
                        _activeCategoryPointers = [];
                      });
                      _panelController.close();
                      _startRouteFlow(LatLng(p.lat, p.lng));
                    },
                  ),
                  onTap: () {
                    setState(() {
                      _activeCategory = null;
                      _activeCategoryColor = null;
                      _activeCategoryPointers = [];
                    });
                    _filterMarkersByCategory(null);
                    _animatedMapboxMove(LatLng(p.lat, p.lng), 15.0);
                    _panelController.close();
                    _notifyNavBar(false);

                    _showBuildingPanel(p);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
