import 'package:auth_app/data/models/route_data.dart';
import 'package:auth_app/data/models/route_segment.dart';
import 'package:flutter/material.dart';
import 'shimmer_loading.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Possible travel profiles.  Only *walk* is implemented for now but the
/// widget is future-proof for bus / scooter.

// RouteOptionsPanel and RouteDetailsPanel are now split into separate files.

// Export TravelMode for use in other files
enum TravelMode { walk, bus, scooter }

class RouteOptionsPanel extends StatefulWidget {
  final ValueNotifier<Map<TravelMode, RouteData>> routesNotifier;
  final TravelMode currentMode;
  final VoidCallback onClose;
  final ValueChanged<TravelMode> onModeChanged;
  final VoidCallback onShowDetails;
  final ScrollController? scrollController;

  const RouteOptionsPanel({
    super.key,
    required this.routesNotifier,
    required this.currentMode,
    required this.onClose,
    required this.onModeChanged,
    required this.onShowDetails,
    this.scrollController,
  });

  @override
  State<RouteOptionsPanel> createState() => _RouteOptionsPanelState();
}

class _RouteOptionsPanelState extends State<RouteOptionsPanel> {
  String? _routeError;
  late TravelMode _mode;
  // Always start in loading state so shimmer is shown immediately
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _mode = widget.currentMode;
    // Always show shimmer/loading until route data arrives
    _loading = true;
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
        final route = widget.routesNotifier.value[_mode];
        _loading = route == null;
        if (route != null && (route.segments.isEmpty)) {
          _routeError = "No route can be found at the moment";
        } else {
          _routeError = null;
        }
      });
    }
  }

  String get _prettyDuration {
    final mins = ((widget.routesNotifier.value[_mode]?.totalDuration ?? 0) / 60).round();
    return '$mins min';
  }

  String get _prettyDistance {
    final distance = widget.routesNotifier.value[_mode]?.totalDistance ?? 0;
    return distance >= 1000
        ? '${(distance / 1000).toStringAsFixed(1)} km'
        : '${distance.round()} m';
  }

  bool get _hasError {
    final route = widget.routesNotifier.value[_mode];
    return route != null && route.error == true;
  }

  bool get _shouldLoading{
    final route = widget.routesNotifier.value[_mode];
    return route == null;
  }

  @override
  void didUpdateWidget(covariant RouteOptionsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.routesNotifier.value[_mode] != oldWidget.routesNotifier.value[_mode]) {
      setState(() {
        _loading = false;
      });
    }
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
      color: Theme.of(context).colorScheme.surface,
      elevation: 8,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        bottom: true,
        minimum: const EdgeInsets.only(bottom: 16), // Add extra padding to the bottom
        child: Container(
          constraints: const BoxConstraints(minHeight: 320, maxHeight: 600), // Increased maxHeight to make the route options taller
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
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
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
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
                    // Always show the summary box, but with shimmer if loading
                    _shouldLoading
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            child: ShimmerLoading(height: 80, width: double.infinity),
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
                            child: _hasError
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "No route can be found at the moment",
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              color: Theme.of(context).colorScheme.onSurface,
                                              fontWeight: FontWeight.w500,
                                            ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  )
                                : Row(
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
                                      const SizedBox(width: 12),
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Theme.of(context).colorScheme.primary,
                                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                        onPressed: widget.onShowDetails,
                                        icon: const Icon(Icons.expand_circle_down_outlined),
                                        label: const Text('Show details'),
                                      ),
                                    ],
                                  ),
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
    ));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Google Maps-style timeline tile for each segment
// ─────────────────────────────────────────────────────────────────────────────
// Widget _buildSegmentsTimeline(BuildContext context) {
//   ...
// }


// ─────────────────────────────────────────────────────────────────────────────
// Google Maps-style timeline tile for each segment
// ─────────────────────────────────────────────────────────────────────────────
class _SegmentTimelineTile extends StatelessWidget {
  final RouteSegment segment;
  final bool isFirst;
  final bool isLast;

  const _SegmentTimelineTile({
    required this.segment,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Use transportType for correct icon/color
    final isBus = segment.transportType == 'bus';
    final isSubway = segment.transportType == 'subway';
    final isTram = segment.transportType == 'tram';
    final isSuburban = segment.transportType == 'suburban';
    
    final Color timelineColor = isBus
        ? theme.colorScheme.primary
        : isSubway
            ? Colors.blue.shade700
            : isTram
                ? const Color(0xFFD32F2F)
                : isSuburban
                    ? const Color(0xff388e3c)
                    : Colors.grey.shade400;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline
        Container(
          width: 32,
          child: Column(
            children: [
              if (!isFirst)
                Center(
                  child: Container(
                    width: 4,
                    height: 16,
                    color: timelineColor,
                  ),
                ),
              Center(
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isBus
                        ? theme.colorScheme.primary
                        : isSubway
                            ? Colors.blue.shade700
                            : isTram
                                ? const Color(0xFFD32F2F)
                                : isSuburban
                                    ? const Color(0xff388e3c)
                                    : Colors.white,
                    border: Border.all(
                      color: timelineColor,
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: isBus
                        ? Icon(Icons.directions_bus, size: 12, color: Colors.white)
                        : isSubway
                            ? Icon(Icons.subway, size: 12, color: Colors.white)
                            : isTram
                                ? Icon(Icons.tram, size: 12, color: Colors.white)
                                : isSuburban
                                    ? Icon(Icons.train, size: 12, color: Colors.white)
                                    : Icon(Icons.directions_walk, size: 12, color: timelineColor),
                  ),
                ),
              ),
              if (!isLast)
                Center(
                  child: Container(
                    width: 4,
                    height: 32,
                    color: timelineColor,
                  ),
                ),
            ],
          ),
        ),
        // Content
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(14),
            ),
            child: _buildSegmentContent(context, isBus, isSubway, isTram, isSuburban),
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentContent(BuildContext context, bool isBus, bool isSubway, bool isTram, bool isSuburban) {
    final theme = Theme.of(context);
    final isTransport = isBus || isSubway || isTram || isSuburban;
    if (isTransport) {
      final Color pillColor = isBus
          ? theme.colorScheme.primary
          : isSubway
              ? Colors.blue.shade700
              : isTram
                  ? const Color(0xFFD32F2F)
                  : isSuburban
                      ? const Color(0xff388e3c)
                      : Colors.grey.shade400;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (segment.transportLine != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: pillColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    segment.transportLine!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              Expanded(
                child: Text(
                  segment.toStop ?? (isBus ? 'Bus segment' : isSubway ? 'Subway segment' : isTram ? 'Tram segment' : 'Train segment'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              Text(
                _prettyTime(segment.durrationSeconds),
                style: TextStyle(
                  color: pillColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (segment.fromStop != null)
            Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Text(
                'From: ${segment.fromStop}',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      );
    } else {
      return Row(
        children: [
          Icon(Icons.directions_walk, size: 16, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Walk ${_prettyTime(segment.durrationSeconds)} (${_prettyDistance(segment.distanceMeters)})',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      );
    }
  }

  // Removed duplicate _buildSegmentContent

  String _prettyTime(int seconds) {
    final mins = (seconds / 60).round();
    return '$mins min';
  }

  String _prettyDistance(double meters) {
    return meters >= 1000
        ? '${(meters / 1000).toStringAsFixed(1)} km'
        : '${meters.round()} m';
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

    Widget pill(TravelMode mode, Widget iconWidget, String label) {
      final bool active = selected == mode;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(mode),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: active ? theme.colorScheme.primary : Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                iconWidget,
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: active
                        ? Theme.of(context).colorScheme.surface
                        : Theme.of(context).colorScheme.onSurface,
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
        pill(
          TravelMode.walk,
          Icon(
            Icons.directions_walk,
            size: 20,
            color: selected == TravelMode.walk ? theme.colorScheme.surface : theme.colorScheme.onSurface,
          ),
          'Walk',
        ),
        const SizedBox(width: 6),
        // Use custom SVG for public transport
        pill(
          TravelMode.bus,
          SizedBox(
            width: 24,
            height: 24,
            child: Padding(
              padding: const EdgeInsets.all(2.0),
              child: SvgPicture.asset(
                'assets/icons/public_transport.svg',
                color: selected == TravelMode.bus ? theme.colorScheme.surface : theme.colorScheme.onSurface,
              ),
            ),
          ),
          'Transit',
        ),
        const SizedBox(width: 6),
        pill(
          TravelMode.scooter,
          Icon(
            Icons.electric_scooter,
            size: 20,
            color: selected == TravelMode.scooter ? theme.colorScheme.surface : theme.colorScheme.onSurface,
          ),
          'Scooter',
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget to display info about each segment
// ─────────────────────────────────────────────────────────────────────────────
// class _SegmentInfoCard extends StatelessWidget {
//   ...
// }

// ─────────────────────────────────────────────────────────────────────────────
// Custom ScrollBehavior to remove overscroll/scroll glow
// ─────────────────────────────────────────────────────────────────────────────
class _NoGlowScrollBehavior extends ScrollBehavior {
  const _NoGlowScrollBehavior();

  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}

/// A bottom sheet that shows the full route timeline/segment list, with close button.
class RouteDetailsSheet extends StatelessWidget {
  final RouteData? data;
  final VoidCallback onClose;
  final String Function(RouteData?) deriveStartName;
  final String Function(RouteData?) deriveEndName;

  const RouteDetailsSheet({
    Key? key,
    required this.data,
    required this.onClose,
    required this.deriveStartName,
    required this.deriveEndName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final segs = data?.segments ?? const <RouteSegment>[];
    final ScrollController scrollController = ScrollController();
    return Material(
      color: Colors.white,
      elevation: 8,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: ScrollConfiguration(
          behavior: const _NoGlowScrollBehavior(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Route details',
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
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
                        onPressed: onClose,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is OverscrollNotification &&
                        notification.overscroll < 0 &&
                        scrollController.position.pixels <= 0) {
                      // Only allow panel to close if at the top and user is dragging down
                      onClose();
                      return true;
                    }
                    return false;
                  },
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                    child: Builder(
                      builder: (ctx) {
                        if (segs.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: Text('No route segments', style: Theme.of(ctx).textTheme.bodyMedium),
                            ),
                          );
                        }
                        // Old style: vertical timeline with endpoints and segment tiles
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Start endpoint
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 32,
                                  child: Column(
                                    children: [
                                      // No line above start
                                      Center(
                                        child: Container(
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            border: Border.all(
                                              color: Colors.grey.shade400,
                                              width: 3,
                                            ),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Center(
                                            child: Icon(Icons.flag, size: 12, color: Colors.grey.shade400),
                                          ),
                                        ),
                                      ),
                                      Center(
                                        child: Container(
                                          width: 4,
                                          height: 32,
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surfaceVariant,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Text(
                                    deriveStartName(data),
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // Segments (filter out zero-duration walking segments)
                          for (int i = 0; i < segs.length; i++)
                            if (!((segs[i].transportType == 'walk' || segs[i].transportType == 'walking') && segs[i].durrationSeconds <= 0 && segs[i].distanceMeters <= 0))
                              _SegmentTimelineTile(
                                segment: segs[i],
                                isFirst: i == 0,
                                isLast: i == segs.length - 1,
                              ),
                          // End endpoint
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 32,
                                child: Column(
                                  children: [
                                    Center(
                                      child: Container(
                                        width: 4,
                                        height: 32,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                    Center(
                                      child: Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          border: Border.all(
                                            color: Colors.grey.shade400,
                                            width: 3,
                                          ),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Center(
                                          child: Icon(Icons.flag, size: 12, color: Colors.grey.shade400),
                                        ),
                                      ),
                                    ),
                                    // No line below end
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surfaceVariant,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Text(
                                    deriveEndName(data),
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
          )],
          ),
      ),
    ));
  }
}
