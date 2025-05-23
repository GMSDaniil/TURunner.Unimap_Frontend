import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:auth_app/domain/usecases/find_route.dart';
import 'package:auth_app/data/models/findroute_req_params.dart';
import 'package:auth_app/service_locator.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController(); // Add this
  List<Marker> _markers = [];
  List<LatLng> _path = [];

  @override
  void initState() {
    super.initState();
    _loadBuildingMarkers();
  }

  // Loads the markers using the new JSON file which already contains centroid data.
  Future<void> _loadBuildingMarkers() async {
    try {
      // Ensure that campus_buildings_centroids.json is declared in pubspec.yaml under assets.
      final jsonStr = await rootBundle.loadString('assets/campus_buildings_centroids.json');
      final List data = jsonDecode(jsonStr);
      print('Loaded ${data.length} building centroids');

      // Create markers from the decoded data.
      final markers = data.map((entry) {
        final double lat = (entry['latitude'] as num).toDouble();
        final double lng = (entry['longitude'] as num).toDouble();
        final String name = entry['name'] as String;

        return Marker(
          point: LatLng(lat, lng),
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => _showPointPopup(context, name),
            child: const Icon(
              Icons.location_on,
              color: Colors.deepPurple,
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

  /// Pops up an AlertDialog showing the building name.
  void _showPointPopup(BuildContext context, String name) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Makes the bottom sheet full width
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SizedBox(
        width: MediaQuery.of(context).size.width, // Ensures full width
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
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
                name,
                style: Theme.of(context).textTheme.titleLarge, // Use theme-defined text style
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              // Additional details
              const Text(
                'Additional details can be added here.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              // Close button
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary, // Use primary color
                  foregroundColor: Theme.of(context).colorScheme.onPrimary, // Use onPrimary color
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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

  /// Uses the FindRoute use case to fetch a route between Hauptgebäude and Mathegebäude.
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

    // From findRouteUseCase you'll get either an error or points.
    result.fold(
      (error) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      },
      (routePoints) {
        setState(() {
          _path = routePoints;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(52.5125, 13.3269),
              initialZoom: 17.0,
              maxZoom: 18.0,
              cameraConstraint: CameraConstraint.contain(
                bounds: LatLngBounds(
                  LatLng(52.507, 13.317),
                  LatLng(52.519, 13.335),
                ),
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
                    Polyline(
                      points: _path,
                      color: Colors.blue,
                      strokeWidth: 4.0,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: _markers,
              ),
            ],
          ),
          // Search bar widget
          Column(
            children: [
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    enabled: true,
                    decoration: InputDecoration(
                      hintText: 'Search location',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    onSubmitted: (value) {
                      print('User searched: $value');
                      // TODO: Implement search logic here
                    },
                  ),
                ),
              ),
            ],
          ),
          // 'Find Route' button
          Positioned(
            bottom: 20,
            left: 20,
            child: ElevatedButton(
              onPressed: _findRoute,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Find Route', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ),
          // Reset compass FloatingActionButton
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: _resetCompass,
              backgroundColor: Colors.white,
              child: const Icon(Icons.explore, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadMockBuildings() async {
    try {
      print('🟡 Loading campus_buildings.json...');
      final jsonStr = await rootBundle.loadString('assets/campus_buildings.json');
      print('✅ JSON loaded: ${jsonStr.length} characters');

      final List data = jsonDecode(jsonStr);
      print('📦 Total buildings found: ${data.length}');

      final buildings = data.map((e) => Building.fromJson(e)).toList();

      final markers = buildings.map((b) {
        return Marker(
          point: LatLng(b.lat, b.lng),
          width: 80,
          height: 80,
          child: GestureDetector(
            onTap: () => _showPointPopup(context, b.name, 'Building'),
            child: const Icon(Icons.location_on, color: Colors.green),
          ),
        );
      }).toList();

      setState(() {
        _buildingMarkers = markers;
        _markers = [..._buildingMarkers, ..._pointerMarkers];
      });

      print('📍 Total markers added: ${markers.length}');
    } catch (e) {
      print('❌ Error loading buildings: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadMockBuildings();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.move(LatLng(52.5125, 13.3269), 17.0);
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose(); // Dispose controller
    super.dispose();
  }
}