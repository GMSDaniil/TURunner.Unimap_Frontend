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

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  List<Marker> _markers = [];
  List<LatLng> _path = [];
  List<Pointer> _allPointers = [];
  List<Pointer> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _loadBuildingMarkers();
    _searchController.addListener(_onSearchChanged);
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
      final markers =
          _allPointers.map((pointer) {
            return Marker(
              point: LatLng(pointer.lat, pointer.lng),
              width: 40,
              height: 40,
              child: GestureDetector(
                onTap: () => _showPointPopup(context, pointer),
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

  // Search logic: filter markers by name
  void _searchMarkers(String query) {
    final filtered =
        _allPointers
            .where(
              (pointer) =>
                  pointer.name.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();

    final filteredMarkers =
        filtered.map((pointer) {
          return Marker(
            point: LatLng(pointer.lat, pointer.lng),
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: () => _showPointPopup(context, pointer),
              child: const Icon(Icons.location_on, color: Colors.deepPurple),
            ),
          );
        }).toList();

    setState(() {
      _markers = filteredMarkers;
    });

    // Optionally move map to first result
    if (filtered.isNotEmpty) {
      _mapController.move(LatLng(filtered.first.lat, filtered.first.lng), 17.0);
    }
  }

  /// Pops up a bottom sheet showing the building info and allows adding to favourites.
  void _showPointPopup(BuildContext context, Pointer pointer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Makes the bottom sheet full width
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (ctx) => SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 24.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Drag handle
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Building name
                  Text(
                    pointer.name,
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    pointer.category,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  // Show the menu button only for Mensa buildings
                  if (pointer.category == 'Mensa')
                    ElevatedButton(
                      onPressed: () async {
                        final jsonStr = await rootBundle.loadString(
                          'assets/sample_mensa_menu.json',
                        );
                        final List data = jsonDecode(jsonStr);
                        showDialog(
                          context: context,
                          builder:
                              (_) => AlertDialog(
                                title: const Text("Today's Menu"),
                                content: SizedBox(
                                  width: double.maxFinite,
                                  child: ListView(
                                    shrinkWrap: true,
                                    children:
                                        data
                                            .map<Widget>(
                                              (meal) => ListTile(
                                                title: Text(meal['name']),
                                                subtitle: Text(
                                                  'Student: ${meal['priceStudent']} € | Employee: ${meal['priceEmployee']} € | Guest: ${meal['priceGast']} €',
                                                ),
                                                trailing:
                                                    meal['vegan'] == true
                                                        ? const Icon(
                                                          Icons.eco,
                                                          color: Colors.green,
                                                        )
                                                        : meal['vegetarian'] ==
                                                            true
                                                        ? const Icon(
                                                          Icons.spa,
                                                          color: Colors.orange,
                                                        )
                                                        : null,
                                              ),
                                            )
                                            .toList(),
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text("Today's Meal Menu"),
                    ),
                  ElevatedButton.icon(
                    onPressed: () {
                      FavouritesManager().add(pointer);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${pointer.name} added to favourites!'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.favorite, color: Colors.white),
                    label: const Text('Add to Favourites'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      elevation: 2,
                    ),
                  ),
                  // Close button
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _resetCompass() {
    _mapController.rotate(0);
  }

  // FindRoute use case to fetch a route between Hauptgebäude and Mathegebäude.
  Future<void> _findRoute() async {
    // Use hardcoded coordinates for simplicity:
    const double hauptLat = 52.5125;
    const double hauptLon = 13.3269;
    const double matheLat = 52.5135;
    const double matheLon = 13.3245;

    final params = FindRouteReqParams(
      startLat: hauptLat,
      startLon: hauptLon,
      endLat: matheLat,
      endLon: matheLon,
      profile: 'foot',
    );
    final findRouteUseCase = sl<FindRouteUseCase>();
    final result = await findRouteUseCase.call(param: params);

    // From findRouteUseCase: error or pointers
    result.fold(
      (error) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      },
      (routePoints) {
        setState(() {
          _path = routePoints;
        });
      },
    );
  }

  /// Filters markers by category and updates the map.
  /// [category] is the category string (e.g., 'Library', 'Mensa').
  /// [markerColor] is the color for the displayed markers.
  void _filterMarkersByCategory(String category, Color markerColor) {
    final filtered =
        _allPointers
            .where((p) => (p.category.toLowerCase() == category.toLowerCase()))
            .toList();

    setState(() {
      _markers =
          filtered
              .map(
                (pointer) => Marker(
                  point: LatLng(pointer.lat, pointer.lng),
                  width: 40,
                  height: 40,
                  child: GestureDetector(
                    onTap: () => _showPointPopup(context, pointer),
                    child: Icon(Icons.location_on, color: markerColor),
                  ),
                ),
              )
              .toList();
    });

    // Optionally move the map to the first result
    if (filtered.isNotEmpty) {
      _mapController.move(LatLng(filtered.first.lat, filtered.first.lng), 17.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildFlutterMap(),
          _buildSearchBarAndSuggestions(),
          _buildFindRouteButton(),
          _buildCompassButton(),
        ],
      ),
    );
  }

  // main map widget with markers and polylines.
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
        MarkerLayer(markers: _markers),
      ],
    );
  }

  // search bar and the horizontal category widgets
  Widget _buildSearchBarAndSuggestions() {
    return Column(
      children: [
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  enabled: true,
                  decoration: InputDecoration(
                    hintText: 'Search location',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _markers =
                              _allPointers.map((pointer) {
                                return Marker(
                                  point: LatLng(pointer.lat, pointer.lng),
                                  width: 40,
                                  height: 40,
                                  child: GestureDetector(
                                    onTap:
                                        () => _showPointPopup(context, pointer),
                                    child: const Icon(
                                      Icons.location_on,
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                );
                              }).toList();
                          _suggestions = [];
                        });
                      },
                    ),
                  ),
                  onSubmitted: (value) {
                    _searchMarkers(value);
                    setState(() {
                      _suggestions = [];
                    });
                  },
                ),
                const SizedBox(height: 8),
                _buildCategoryChips(),
                if (_suggestions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _suggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = _suggestions[index];
                        return ListTile(
                          title: Text(suggestion.name),
                          onTap: () {
                            _searchController.text = suggestion.name;
                            _searchMarkers(suggestion.name);
                            setState(() {
                              _suggestions = [];
                            });
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // category widgets under the search bar
  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children:
            [
                  categoryChip(
                    icon: Icons.my_location,
                    label: 'Current Location',
                    iconColor: Colors.blue,
                    onTap: () {
                      // TODO: Implement current location logic
                    },
                  ),
                  categoryChip(
                    icon: Icons.local_cafe,
                    label: 'Cafe',
                    iconColor: Colors.orange,
                    onTap: () {
                      // TODO: Show only cafes on the map (implement later)
                    },
                  ),
                  categoryChip(
                    icon: Icons.local_library,
                    label: 'Library',
                    iconColor: Colors.yellow[800]!,
                    onTap: () {
                      // Show only library buildings on the map
                      _filterMarkersByCategory('Library', Colors.yellow[800]!);
                    },
                  ),
                  categoryChip(
                    icon: Icons.restaurant,
                    label: 'Mensa',
                    iconColor: Colors.green,
                    onTap: () {
                      // Show only mensa buildings on the map
                      _filterMarkersByCategory('Mensa', Colors.green);
                    },
                  ),
                  // Add more chips as needed
                ]
                .map(
                  (chip) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: chip,
                  ),
                )
                .toList(),
      ),
    );
  }

  Widget categoryChip({
    required IconData icon,
    required String label,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      elevation: 2,
      shadowColor: Colors.black12,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
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

  // Compass reset FloatingAction Button
  Widget _buildCompassButton() {
    return Positioned(
      bottom: 20,
      right: 20,
      child: FloatingActionButton(
        onPressed: _resetCompass,
        backgroundColor: Colors.white,
        child: const Icon(Icons.explore, color: Colors.black),
      ),
    );
  }

  // @override
  // void dispose() {
  //   _debounceTimer?.cancel();
  //   _searchController.dispose(); // Dispose controller
  //   super.dispose();
  // }
}
