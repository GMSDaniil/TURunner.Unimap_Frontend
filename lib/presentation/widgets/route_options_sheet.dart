import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// Possible travel profiles.  Only *walk* is implemented for now but the
/// widget is future-proof for bus / scooter.
enum TravelMode { walk, bus, scooter }

/// A sleek bottom-sheet that mimics Google Maps’ route card but matches the
/// UniMap style language (soft radius, gradient buttons, pill chips).
///
/// * Displays total distance & duration for the currently selected mode.
/// * Lets the user switch mode via a pill-segment row.
/// * Has a trailing "close" icon that dismisses the sheet and calls [onClose].
///
/// The sheet is **stateless** for the parent – we only report mode changes via
/// [onModeChanged].  Everything else is handled locally.
class RouteOptionsSheet extends StatefulWidget {
  final List<LatLng> route;
  final double distance; // ⟂ meters
  final int duration; // ⟂ milliseconds
  final VoidCallback onClose;
  final ValueChanged<TravelMode> onModeChanged;

  const RouteOptionsSheet({
    super.key,
    required this.route,
    required this.distance,
    required this.duration,
    required this.onClose,
    required this.onModeChanged,
  });

  @override
  State<RouteOptionsSheet> createState() => _RouteOptionsSheetState();
}

class _RouteOptionsSheetState extends State<RouteOptionsSheet> {
  TravelMode _mode = TravelMode.walk;

  /// Human-readable duration rounded to the nearest minute.
  String get _prettyDuration {
    final mins = (widget.duration / 60000).round();
    return '$mins min';
  }

  /// Human-readable distance with 1-decimal km if ≥1 km, otherwise integer m.
  String get _prettyDistance {
    return widget.distance >= 1000
        ? '${(widget.distance / 1000).toStringAsFixed(1)} km'
        : '${widget.distance.round()} m';
  }

  /// Colour helpers to keep chips/glows on brand.
  Color get _activeColor => Theme.of(context).colorScheme.primary;
  Color get _onActive   => Theme.of(context).colorScheme.onPrimary;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,                    // ← force white
      elevation: 8,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(                  // ← moved inside Material
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header row ───────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Route options',
                      style: Theme.of(context).textTheme.titleLarge!
                        .copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    splashRadius: 20,
                    onPressed: widget.onClose,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Drag-handle mimic
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _ModeSelector(
                selected: _mode,
                onChanged: (m) {
                  setState(() => _mode = m);
                  widget.onModeChanged(m);
                },
              ),
              const SizedBox(height: 24),
              // ── Info card ───────────────────────────────────────────
              Container(
                padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12, blurRadius: 8, offset: Offset(0,2)
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.timer, size: 22),
                        const SizedBox(width: 6),
                        Text(_prettyDuration,
                          style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.social_distance_rounded, size: 22),
                        const SizedBox(width: 6),
                        Text(_prettyDistance,
                          style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              // … any additional children …
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small isolated widget for the pill-segment mode selector
// ─────────────────────────────────────────────────────────────────────────────
class _ModeSelector extends StatelessWidget {
  final TravelMode selected;
  final ValueChanged<TravelMode> onChanged;

  const _ModeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget pill(TravelMode mode, IconData icon, String label) {
      final bool active = selected == mode;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(mode),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: active ? theme.colorScheme.primary : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon,
                  size: 20,
                  color: active ? theme.colorScheme.onPrimary : Colors.black87,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: active ? theme.colorScheme.onPrimary : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        pill(TravelMode.walk, Icons.directions_walk, 'Walk'),
        const SizedBox(width: 6),
        pill(TravelMode.bus, Icons.directions_bus, 'Bus'),
        const SizedBox(width: 6),
        pill(TravelMode.scooter, Icons.electric_scooter, 'Scooter'),
      ],
    );
  }
}