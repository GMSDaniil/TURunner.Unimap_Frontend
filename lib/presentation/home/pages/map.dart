import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:auth_app/data/models/get_pointers_req_params.dart';
import 'package:auth_app/data/models/pointer.dart';
import 'package:auth_app/data/models/building.dart';
import 'package:auth_app/data/source/pointer_api_service.dart';
import 'package:auth_app/domain/usecases/find_route.dart';
import 'package:auth_app/data/models/findroute_req_params.dart';
import 'package:auth_app/service_locator.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

Timer? _debounceTimer;

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  List<Marker> _markers = [];
  List<Marker> _buildingMarkers = [];
  List<Marker> _pointerMarkers = [];
  String? _selectedCategory = 'All';
  List<LatLng> _path = [];

  final pointerApi = PointerApiService();

  void _onMapInteractionEnd() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 700), () {
      _fetchPointersFromBackend();
    });
  }

  Future<void> _fetchPointersFromBackend() async {
    print('🟢 Fetching pointers from backend...');
    final bounds = _mapController.camera.visibleBounds;
    final req = GetPointersRequest(
      northEastLat: bounds.northEast.latitude,
      northEastLng: bounds.northEast.longitude,
      southWestLat: bounds.southWest.latitude,
      southWestLng: bounds.southWest.longitude,
      category: _selectedCategory == 'All' ? null : _selectedCategory,
    );

    try {
      final pointers = await pointerApi.getPointers(req);
      final pointerMarkers = pointers.map((p) => Marker(
        point: LatLng(p.lat, p.lng),
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () => _showPointPopup(context, p.name, p.category),
          child: Icon(Icons.place, color: Colors.blue),
        ),
      )).toList();

      setState(() {
        _pointerMarkers = pointerMarkers;
        _markers = [..._buildingMarkers, ..._pointerMarkers];
        print('🟠 Pointer markers added: ${_pointerMarkers.length}');
      });
    } catch (e) {
      print('❌ Error fetching pointers: $e');
    }
  }

  void _showPointPopup(BuildContext context, String name, String category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(name),
        content: Text("Category: $category"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close"),
          )
        ],
      ),
    );
  }

  void _resetCompass() {
    _mapController.rotate(0);
  }

  /// Find route logic using FindRouteUseCase
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
              onPositionChanged: (MapPosition position, bool hasGesture) {
                if (hasGesture) {
                  _onMapInteractionEnd();
                }
              },
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
              MarkerLayer(
                markers: _markers,
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
            ],
          ),
          Column(
            children: [
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GestureDetector(
                    onTap: () {
                      print('Search bar clicked');
                    },
                    child: TextField(
                      enabled: false,
                      decoration: InputDecoration(
                        hintText: 'Search location',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              DropdownButton<String>(
                value: _selectedCategory,
                items: ['All', 'Library', 'Cafeteria', 'Lab'].map((cat) =>
                  DropdownMenuItem(value: cat, child: Text(cat))
                ).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedCategory = val!;
                  });
                  _fetchPointersFromBackend();
                },
              ),
            ],
          ),
          Positioned(
            bottom: 20,
            left: 20,
            child: ElevatedButton(
              onPressed: _findRoute,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Find Route',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: _resetCompass,
              backgroundColor: Colors.white,
              child: const Icon(Icons.explore,
                color: Colors.black,
              ),
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
    super.dispose();
  }
}