import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Animation Test',
      home: AnimationTestPage(),
    );
  }
}

class AnimationTestPage extends StatefulWidget {
  @override
  _AnimationTestPageState createState() => _AnimationTestPageState();
}

class _AnimationTestPageState extends State<AnimationTestPage> with TickerProviderStateMixin {
  AnimationController? _bounceAnimationController;
  late Animation<double> _bounceAnimation;
  LatLng? _selectedMarkerPosition;
  bool _isAnimationActive = false;
  
  final LatLng testPosition = LatLng(52.5125, 13.3269);
  List<Marker> _markers = [];

  @override
  void initState() {
    super.initState();
    
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

    // Add animation status listener
    _bounceAnimationController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isAnimationActive = false;
        });
      }
    });

    // Create initial marker
    _createMarkers();
  }

  void _createMarkers() {
    _markers = [
      Marker(
        point: testPosition,
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () => _handleMarkerSelection(testPosition),
          child: _buildMarkerIcon(testPosition),
        ),
      ),
    ];
  }

  void _handleMarkerSelection(LatLng position) {
    print('DEBUG: _handleMarkerSelection called with position: $position');
    
    setState(() {
      _selectedMarkerPosition = position;
      _isAnimationActive = true;
    });
    
    print('DEBUG: Animation state set - selected: $_selectedMarkerPosition, active: $_isAnimationActive');
    
    // Start bounce animation
    _bounceAnimationController?.reset();
    _bounceAnimationController?.forward();
    
    print('DEBUG: Animation controller forward called');
  }

  Widget _buildMarkerIcon(LatLng position) {
    final isSelected = _selectedMarkerPosition != null && 
                      _selectedMarkerPosition!.latitude == position.latitude && 
                      _selectedMarkerPosition!.longitude == position.longitude;
    final color = isSelected ? Colors.red : Colors.deepPurple;
    
    print('DEBUG: _buildMarkerIcon for $position - selected: $isSelected, active: $_isAnimationActive, color: $color');
    
    if (isSelected && _isAnimationActive) {
      print('DEBUG: Creating animated marker icon');
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
    
    print('DEBUG: Creating static marker icon');
    return Icon(
      Icons.location_on,
      color: color,
      size: 30,
    );
  }

  @override
  void dispose() {
    _bounceAnimationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Animation Test')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () => _handleMarkerSelection(testPosition),
            child: Text('Test Animation'),
          ),
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: testPosition,
                initialZoom: 17.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.app',
                ),
                MarkerLayer(markers: _markers),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
