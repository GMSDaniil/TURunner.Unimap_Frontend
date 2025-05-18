import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();

  void _resetCompass() {
    _mapController.rotate(0); // Reset the map's rotation to north
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: const Text('Map'), automaticallyImplyLeading: false,),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(52.5125, 13.3269), // TU Berlin
              initialZoom: 17.0,
              maxZoom: 18.0,
              cameraConstraint: CameraConstraint.contain(
                bounds: LatLngBounds(
                  LatLng(52.507, 13.317), // Southwest corner
                  LatLng(52.519, 13.335), // Northeast corner
                ),
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
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
                      // No functionality for now
                      print('Search bar clicked');
                    },
                    child: TextField(
                      enabled: false, // Disable direct input
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
            right: 20,
            child: FloatingActionButton(
              onPressed: _resetCompass,
              backgroundColor: Colors.white,
              child: const Icon(
                Icons.explore, // Compass icon
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}