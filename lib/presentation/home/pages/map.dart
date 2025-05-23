import 'dart:convert';
import 'package:flutter/material.dart';
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

  List<LatLng> _path = [];

  void _resetCompass() {
    _mapController.rotate(0);
  }

  /// New method: Call the FindRoute use case to fetch a route between Hauptgebäude and Mathegebäude.
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
      // You can uncomment or add an AppBar if needed
      // appBar: AppBar(title: const Text('Map')),
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
            ],
          ),
          // Existing widgets (search bar, compass button, etc.)
          Column(
            children: [
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GestureDetector(
                    onTap: () => print('Search bar clicked'),
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
            ],
          ),
          Positioned(
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
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: _resetCompass,
              backgroundColor: Colors.white,
              child: const Icon(
                Icons.explore,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}