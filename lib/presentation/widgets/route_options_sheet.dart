import 'package:auth_app/data/models/route_data.dart';
import 'package:auth_app/data/models/route_segment.dart';
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
  final ValueNotifier<Map<TravelMode, RouteData>> routesNotifier;
  final TravelMode currentMode;
  final VoidCallback onClose;
  final ValueChanged<TravelMode> onModeChanged;

  /// If the sheet is wrapped in a `DraggableScrollableSheet`, Flutter will
  /// hand us its internal ScrollController so the content keeps scrolling
  /// smoothly while the panel is being dragged.
  final ScrollController? scrollController;

  const RouteOptionsSheet({
    super.key,
    required this.routesNotifier,
    required this.currentMode,
    required this.onClose,
    required this.onModeChanged,
    this.scrollController,
  });

  @override
  State<RouteOptionsSheet> createState() => _RouteOptionsSheetState();
}

class _RouteOptionsSheetState extends State<RouteOptionsSheet> {
  late TravelMode _mode;
  bool _loading = false;

  /// Human-readable duration rounded to the nearest minute.
  @override
  void initState() {
    super.initState();
    _mode = widget.currentMode;
    _loading = widget.routesNotifier.value[_mode] == null;
    widget.routesNotifier.addListener(_onRoutesChanged);
  }

  @override
  void dispose() {
    widget.routesNotifier.removeListener(_onRoutesChanged);
    super.dispose();
  }

  void _onRoutesChanged() {
    if (mounted) {
      setState(() {
        _loading = widget.routesNotifier.value[_mode] == null;
      });
    }
  }

  String get _prettyDuration {
    final mins = ((widget.routesNotifier.value[_mode]?.totalDuration ?? 0) / 60)
        .round();
    return '$mins min';
  }

  String get _prettyDistance {
    final distance = widget.routesNotifier.value[_mode]?.totalDistance ?? 0;
    return distance >= 1000
        ? '${(distance / 1000).toStringAsFixed(1)} km'
        : '${distance.round()} m';
  }

  /// Colour helpers to keep chips/glows on brand.
  Color get _activeColor => Theme.of(context).colorScheme.primary;
  Color get _onActive => Theme.of(context).colorScheme.onPrimary;

  @override
  void didUpdateWidget(covariant RouteOptionsSheet oldWidget) {
    print('RouteOptionsSheet didUpdateWidget');
    super.didUpdateWidget(oldWidget);
    // If new data for the currently selected mode arrives, stop loading
    if (widget.routesNotifier.value[_mode] !=
        oldWidget.routesNotifier.value[_mode]) {
      setState(() {
        _loading = false;
      });
    }
    // If parent changes the currentMode (e.g. after sheet reopens), sync local mode
    if (widget.currentMode != oldWidget.currentMode) {
      setState(() {
        _mode = widget.currentMode;
        _loading = widget.routesNotifier.value[widget.currentMode] == null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 8,
      clipBehavior: Clip.antiAlias, // ← clip to shape
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false, // keep top inset only
        bottom: false, // ← disable bottom inset
        child: SingleChildScrollView(
          controller: widget.scrollController,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag-handle mimic
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // ── Header row ───────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Route options',
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  // close button in a light-grey circular pill
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.close, size: 18),
                      splashRadius: 18,
                      onPressed: widget.onClose,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const SizedBox(height: 20),
              _ModeSelector(
                selected: _mode,
                onChanged: (m) {
                  setState(() {
                    _mode = m;
                    _loading = widget.routesNotifier.value[m] == null;
                  });
                  widget.onModeChanged(m);
                },
              ),
              const SizedBox(height: 24),
              // ── Info card ───────────────────────────────────────────
              _loading
                  ? const SizedBox(
                      height: 60,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 2),
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
                              Text(
                                _prettyDuration,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.social_distance_rounded,
                                size: 22,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _prettyDistance,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
              const SizedBox(height: 28),
              // ── Segments info ──────────────────────────────────────
              // if (segments.isNotEmpty)
              //   ...segments.map((seg) => Padding(
              //     padding: const EdgeInsets.only(bottom: 12),
              //     child: _SegmentInfoCard(segment: seg),
              //   )),
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
                Icon(
                  icon,
                  size: 20,
                  color: active ? theme.colorScheme.onPrimary : Colors.black87,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: active
                        ? theme.colorScheme.onPrimary
                        : Colors.black87,
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

// ─────────────────────────────────────────────────────────────────────────────
// Widget to display info about each segment
// ─────────────────────────────────────────────────────────────────────────────
class _SegmentInfoCard extends StatelessWidget {
  final RouteSegment segment;

  const _SegmentInfoCard({required this.segment});

  @override
  Widget build(BuildContext context) {
    final isBus = segment.mode == TravelMode.bus;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isBus ? Colors.blue.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isBus ? 'Bus segment' : 'Walk segment',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isBus ? Colors.blue : Colors.green,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Distance: ${segment.distanceMeters >= 1000 ? (segment.distanceMeters / 1000).toStringAsFixed(1) + ' km' : segment.distanceMeters.round().toString() + ' m'}',
          ),
          Text('Duration: ${(segment.durrationSeconds / 60).round()} min'),
          if (isBus && segment.transportType != null)
            Text('Type: ${segment.transportType}'),
          if (isBus && segment.transportLine != null)
            Text('Line: ${segment.transportLine}'),
          if (isBus && segment.fromStop != null)
            Text('From: ${segment.fromStop}'),
          if (isBus && segment.toStop != null) Text('To: ${segment.toStop}'),
        ],
      ),
    );
  }
}
