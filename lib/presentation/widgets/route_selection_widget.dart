import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

typedef OnRouteSelected = void Function(LatLng start, LatLng destination);

class RouteSelectionWidget extends StatefulWidget {
  // the destination can be pre-filled (from when user tapped on map)
  final LatLng destination;
  // the current location will be the default start
  final LatLng? currentLocation;
  // callback used when user confirms the route selection
  final OnRouteSelected onRouteSelected;
  // callback called when user cancels the route selection mode
  final VoidCallback onCancel;

  const RouteSelectionWidget({
    Key? key,
    required this.destination,
    required this.currentLocation,
    required this.onRouteSelected,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<RouteSelectionWidget> createState() => _RouteSelectionWidgetState();
}

class _RouteSelectionWidgetState extends State<RouteSelectionWidget> {
  late TextEditingController _startController;
  late TextEditingController _destController;
  // For simplicity, these controllers hold simple strings.
  // In a full implementation these would trigger search suggestions.
  // Always show "Current Location" as first suggestion for Start.
  
  @override
  void initState() {
    super.initState();
    // default start is current location (formatted as a string) if available.
    final defaultStart = widget.currentLocation != null
        ? 'Current Location'
        : '';
    _startController = TextEditingController(text: defaultStart);
    
    // the destination text: here we simply use lat,lng as string
    _destController = TextEditingController(text: '(${widget.destination.latitude.toStringAsFixed(5)}, ${widget.destination.longitude.toStringAsFixed(5)})');
  }

  @override
  void dispose() {
    _startController.dispose();
    _destController.dispose();
    super.dispose();
  }

  void _onSearchStart() async {
    // Here you would open a search UI for start.
    // For now, we simply simulate a result.
    // Always ensure the top suggestion is the “Current Location”.
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Select Start Location'),
          children: [
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, 'Current Location');
              },
              child: const Text('Current Location'),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, 'Custom Place A');
              },
              child: const Text('Custom Place A'),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, 'Custom Place B');
              },
              child: const Text('Custom Place B'),
            ),
          ],
        );
      },
    );
    if (result != null) {
      _startController.text = result;
    }
  }

  void _onSearchDest() async {
    // Similarly, simulate a destination search.
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Select Destination'),
          children: [
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, 'Destination Place 1');
              },
              child: const Text('Destination Place 1'),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, 'Destination Place 2');
              },
              child: const Text('Destination Place 2'),
            ),
          ],
        );
      },
    );
    if (result != null) {
      _destController.text = result;
    }
  }

  // In a complete implementation, you would convert the text fields into LatLng values
  // For now we simulate that by returning the current location as start 
  // (if "Current Location" is selected) and the widget.destination as destination.
  void _onConfirm() {
    final start = widget.currentLocation ?? LatLng(52.5135, 13.3245);
    // For destination, use widget.destination (which could be updated from search in a real case)
    final destination = widget.destination;
    widget.onRouteSelected(start, destination);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Start field
            TextField(
              controller: _startController,
              readOnly: true,
              onTap: _onSearchStart,
              decoration: const InputDecoration(
                labelText: 'Start',
                suffixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 12),
            // Destination field
            TextField(
              controller: _destController,
              readOnly: true,
              onTap: _onSearchDest,
              decoration: const InputDecoration(
                labelText: 'Destination',
                suffixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 20),
            // Buttons to confirm or cancel
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _onConfirm,
                  child: const Text('Create Route'),
                ),
                TextButton(
                  onPressed: widget.onCancel,
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}