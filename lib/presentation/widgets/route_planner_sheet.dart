import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

typedef RouteConfirmed = void Function(LatLng start, LatLng destination);

/// Draggable sheet with two pill fields (“From” & “To”) plus a gradient CTA
/// that matches the UniMap brand palette.
class RoutePlannerSheet extends StatefulWidget {
  final LatLng? currentLocation;            // default “From”
  final LatLng? initialDestination;         // pre-filled “To”
  final RouteConfirmed onConfirm;           // user tapped “Create route”
  final VoidCallback   onCancel;            // user tapped “Cancel”

  const RoutePlannerSheet({
    super.key,
    required this.onConfirm,
    required this.onCancel,
    this.currentLocation,
    this.initialDestination,
  });

  @override
  State<RoutePlannerSheet> createState() => _RoutePlannerSheetState();
}

class _RoutePlannerSheetState extends State<RoutePlannerSheet> {
  late TextEditingController _fromCtl;
  late TextEditingController _toCtl;

  @override
  void initState() {
    super.initState();
    _fromCtl = TextEditingController(
      text: widget.currentLocation != null ? 'Current location' : '',
    );
    _toCtl = TextEditingController(
      text: widget.initialDestination != null
          ? '(${widget.initialDestination!.latitude.toStringAsFixed(5)}, '
            '${widget.initialDestination!.longitude.toStringAsFixed(5)})'
          : '',
    );
  }

  @override
  void dispose() {
    _fromCtl.dispose();
    _toCtl.dispose();
    super.dispose();
  }

  Future<void> _pickPlace(TextEditingController ctl, {required bool isStart}) async {
    // Simple placeholder search dialog – plug in your real search here.
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(isStart ? 'Select start' : 'Select destination'),
        children: [
          if (isStart)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, 'Current location'),
              child: const Text('Current location'),
            ),
          ...['Café A', 'Library B', 'Mensa C', 'Custom pin']
              .map((s) => SimpleDialogOption(
                    onPressed: () => Navigator.pop(ctx, s),
                    child: Text(s),
                  )),
        ],
      ),
    );
    if (result != null) ctl.text = result;
  }

  @override
  Widget build(BuildContext context) {
    BoxDecoration pill([Color? bg]) => BoxDecoration(
          color: bg ?? Colors.grey.shade100,
          borderRadius: BorderRadius.circular(24),
        );

    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            children: [
              // drag handle
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // “From” pill
              InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => _pickPlace(_fromCtl, isStart: true),
                child: Ink(
                  decoration: pill(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.my_location_outlined),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_fromCtl.text.isEmpty
                            ? 'Choose start…'
                            : _fromCtl.text),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // “To” pill
              InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => _pickPlace(_toCtl, isStart: false),
                child: Ink(
                  decoration: pill(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.place_outlined),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_toCtl.text.isEmpty
                            ? 'Choose destination…'
                            : _toCtl.text),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // gradient CTA pill
              GestureDetector(
                onTap: () {
                  // Convert to LatLng – placeholder implementation
                  final start = widget.currentLocation ??
                      const LatLng(52.5125, 13.3269);
                  final dest = widget.initialDestination ??
                      const LatLng(52.5140, 13.3270);
                  widget.onConfirm(start, dest);
                },
                child: Container(
                  height: 48,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF7B61FF), Color(0xFFB750FF)],
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(24)),
                  ),
                  child: const Center(
                    child: Text(
                      'Create route',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: widget.onCancel,
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
