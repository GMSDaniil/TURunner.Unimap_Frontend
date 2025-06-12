import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

typedef OnCancelled = void Function();

/// Top-pinned pill with start / up-to-three “additional stops” / destination.
class RoutePlanBar extends StatefulWidget {
  final LatLng?  currentLocation;
  final LatLng?  initialDestination;
  final OnCancelled onCancelled;

  const RoutePlanBar({
    super.key,
    required this.currentLocation,
    this.initialDestination,
    required this.onCancelled,
  });

  @override
  State<RoutePlanBar> createState() => _RoutePlanBarState();
}

class _RoutePlanBarState extends State<RoutePlanBar> {
  late final TextEditingController _startCtl;
  late final TextEditingController _destCtl;
  final List<TextEditingController> _stops = [];           // ← up-to-3

  // ─────────────────────────────────── lifecycle ──────────────────────────
  @override
  void initState() {
    super.initState();
    _startCtl = TextEditingController(
        text: widget.currentLocation != null ? 'Current location' : '');
    _destCtl  = TextEditingController(
        text: widget.initialDestination != null
            ? '${widget.initialDestination!.latitude.toStringAsFixed(5)}, '
              '${widget.initialDestination!.longitude.toStringAsFixed(5)}'
            : '');
  }

  @override
  void dispose() {
    _startCtl.dispose();
    _destCtl.dispose();
    for (final c in _stops) c.dispose();
    super.dispose();
  }

  // ───────────────────────── dummy picker (swap with real search) ─────────
  Future<void> _pick(TextEditingController c, String label) async {
    final res = await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: Text('Choose $label'),
        children: [
          for (final o in const ['Current location', 'Library', 'Café', 'Mensa'])
            SimpleDialogOption(onPressed: () => Navigator.pop(context, o),
                               child: Text(o)),
        ],
      ),
    );
    if (res != null) setState(() => c.text = res);
  }

  // ────────────────────────── compact side-button helper ──────────────────
  Widget _sideBtn({
    required IconData icon,
    required String   tooltip,
    required VoidCallback onTap,
    bool enabled = true,
  }) => GestureDetector(
        onTap: enabled ? onTap : null,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 22, height: 22,
          child: Tooltip(
            message: tooltip,
            child: Icon(icon, size: 20,
                color: enabled ? Colors.black : Colors.black26),
          ),
        ),
      );

  // ────────────────────────── row & divider helpers ───────────────────────
  Widget _divider() => Padding(
        padding: const EdgeInsets.only(left: 4, right: 20),
        child: Container(height: 1, color: const Color(0x33000000)),
      );

  Widget _row({
    required IconData icon,
    required TextEditingController ctl,
    required String hint,
    VoidCallback? onDelete,
  }) => InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _pick(ctl, hint.toLowerCase()),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Row(
            children: [
              Icon(icon, size: 20, color: Colors.grey.shade800),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  ctl.text.isEmpty ? hint : ctl.text,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              if (onDelete != null)
                GestureDetector(
                  onTap: onDelete,
                  behavior: HitTestBehavior.opaque,
                  child: const SizedBox(
                    width: 24, height: 24,
                    child: Center(child: Icon(Icons.close, size: 18)),
                  ),
                ),
            ],
          ),
        ),
      );

  // ─────────────────────────── logic helpers ──────────────────────────────
  void _swap() {
    setState(() {
      final tmp   = _startCtl.text;
      _startCtl.text = _destCtl.text;
      _destCtl.text  = tmp;
    });
  }

  void _addStop() {
    if (_stops.length >= 3) return;               // hard-cap at 3
    setState(() => _stops.add(TextEditingController()));
  }

  void _removeStop(int index) {
    _stops[index].dispose();
    setState(() => _stops.removeAt(index));
  }

  // ─────────────────────────── build ──────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Material(
              color: Colors.white,
              elevation: 8,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── way-points column ───────────────────────────────
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _row(
                            icon: Icons.my_location,
                            ctl: _startCtl,
                            hint: 'Start',
                          ),
                          // dynamic stops
                          for (int i = 0; i < _stops.length; i++) ...[
                            _divider(),
                            _row(
                              icon : Icons.flag_outlined,
                              ctl  : _stops[i],
                              hint : 'Stop ${i + 1}',
                              onDelete: () => _removeStop(i),
                            ),
                          ],
                          // always show divider before destination
                          _divider(),
                          _row(
                            icon: Icons.place_outlined,
                            ctl: _destCtl,
                            hint: 'Destination',
                          ),
                        ],
                      ),
                    ),

                    // ── side buttons (swap / add) ─────────────────────
                    Transform.translate(
                      offset: const Offset(-8, 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _sideBtn(
                            icon: Icons.swap_vert,
                            tooltip: 'Swap',
                            onTap: _swap,
                          ),
                          const SizedBox(height: 8),
                          _sideBtn(
                            icon   : Icons.add,
                            tooltip: 'Add stop',
                            onTap  : _addStop,
                            enabled: _stops.length < 3,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
