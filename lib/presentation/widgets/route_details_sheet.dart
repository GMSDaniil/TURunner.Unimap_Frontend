import 'package:flutter/material.dart';
import 'package:auth_app/data/models/route_data.dart';
import 'package:auth_app/data/models/route_segment.dart';

/// Custom painter for dashed lines
class DashedLinePainter extends CustomPainter {
  final Color color;
  final double thickness;
  final double dash;
  final double gap;

  DashedLinePainter({
    required this.color,
    required this.thickness,
    required this.dash,
    required this.gap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;

    double startY = 0;
    while (startY < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, startY),
        Offset(size.width / 2, (startY + dash).clamp(0, size.height)),
        paint,
      );
      startY += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Re‑implementation that mirrors the latest reference:
///
/// * Extra‑thick rail (12 px) glued to the sheet’s left padding.
/// * Small indicators (16 px) so the rail is visually dominant.
/// * No grey bubble backgrounds – just plain text rows.
/// * For every **vehicle** segment show **start stop, end stop _and_ stop count**.
/// * Dividers between legs for clarity; walk legs stay minimal.
class RouteDetailsPanel extends StatelessWidget {
  const RouteDetailsPanel({
    super.key,
    required this.data,
    required this.onClose,
    required this.deriveStartName,
    required this.deriveEndName,
  });

  final RouteData? data;
  final VoidCallback onClose;
  final String Function(RouteData?) deriveStartName;
  final String Function(RouteData?) deriveEndName;

  // Visual constants
  static const double _railThickness = 24;
  static const double _indicatorSize = 34.5; // Circle + border should be bigger than rail
  static const double _railAreaWidth = 50; // Fixed width for the rail area

  @override
  Widget build(BuildContext context) {
    final segs = data?.segments ?? const <RouteSegment>[];
    final textTheme = Theme.of(context).textTheme;

    (Color colour, IconData icon) _styleFor(RouteSegment s) {
      switch (s.transportType) {
        case 'bus':
          return (Theme.of(context).colorScheme.primary, Icons.directions_bus);
        case 'subway':
          return (Colors.blue.shade700, Icons.subway);
        case 'suburban':
          return (const Color(0xff388e3c), Icons.train);
        default:
          return (Colors.grey.shade400, Icons.directions_walk);
      }
    }

    /// Vehicle (bus / train) segment tile ---------------------------------------------------
    /// `nextIsWalk` tells us whether the **following** tile is a walk leg.  
    /// If so, we end the solid rail with a **dotted** connector so the walk
    /// section appears dotted all the way.
    Widget _vehicleTile(
      RouteSegment segment, {
      required bool isLast,
      required bool nextIsWalk,
    }) {
      final (colour, icon) = _styleFor(segment);
      // Only create pill for vehicle segments (not walking segments)
      final pill = segment.transportType != 'walk' && segment.transportLine != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: colour, borderRadius: BorderRadius.circular(8)),
              child: Text(segment.transportLine!,
                  style: TextStyle(color: Theme.of(context).colorScheme.surface, fontWeight: FontWeight.bold, fontSize: 13)),
            )
          : null;
      final stopCount = segment.stopCount;

      return Container(
        padding: const EdgeInsets.only(bottom: 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left rail area with fixed width
            Container(
              width: _railAreaWidth,
              child: Stack(
                children: [
                  // Transport icon circle
                  Center(
                    child: Container(
                      width: _indicatorSize,
                      height: _indicatorSize,
                      decoration: BoxDecoration(
                        color: colour,
                        borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Theme.of(context).colorScheme.surface.withOpacity(0.3), width: 3),
                      ),
                    child: Icon(icon, size: 16, color: Theme.of(context).colorScheme.surface),
                    ),
                  ),
                  // Rail connector below
                  if (!isLast)
                    Center(
                      child: Container(
                        width: _railThickness,
                        height: 80,
                        color: nextIsWalk ? Colors.grey.shade400 : colour,
                      ),
                    ),
                ],
              ),
            ),
            // Right content area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            segment.fromStop ?? '',
                            style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(_minutes(segment.durationSeconds),
                            style: textTheme.bodyMedium?.copyWith(color: colour)),
                      ],
                    ),
                    if (pill != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: pill,
                      ),
                    if (segment.transportType != 'walk')
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Ride ${stopCount > 0 ? stopCount : 1} stop${(stopCount > 0 ? stopCount : 1) == 1 ? '' : 's'}',
                          style: textTheme.bodySmall?.copyWith(
                              color: textTheme.bodySmall!.color!.withOpacity(0.6)),
                        ),
                      ),
                    // End stop moved to walking tile
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    /// Walk segment tile --------------------------------------------------------------------
    Widget _walkTile(RouteSegment segment, {required bool isLast, required bool isFirst, String? previousEndStop}) {
      final (colour, icon) = _styleFor(segment);
      
      return Container(
        padding: const EdgeInsets.only(bottom: 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left rail area with fixed width
            Container(
              width: _railAreaWidth,
              child: Column(
                children: [
                  // Walk icon circle
                  Center(
                    child: Container(
                      width: _indicatorSize,
                      height: _indicatorSize,
                      decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colour, width: 3),
                      ),
                      child: Icon(icon, size: 10, color: colour),
                    ),
                  ),
                  // Rail connector below (dashed)
                  // Always show connector except if this is the very last tile and there's no flag tile after
                  Center(
                    child: Container(
                      width: _railThickness ,
                      height: 60,
                      child: CustomPaint(
                        painter: DashedLinePainter(
                          color: colour,
                          thickness: _railThickness / 4,
                          dash: 4, // Smaller dots
                          gap: 15,  // Smaller gaps
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Right content area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isFirst)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          deriveStartName(data),
                          style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    if (previousEndStop != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          previousEndStop,
                          style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    Row(
                      children: [
                        Icon(Icons.directions_walk, size: 14, color: textTheme.bodyMedium!.color),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Walk ${_minutes(segment.durationSeconds)} • ${_distance(segment.distanceMeters)}',
                            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    /// Flag tiles (end only) ----------------------------------------------------------------
    Widget _flagTile({required bool isStart}) {
      final grey = Colors.grey.shade400;
      
      // Only show end content since we removed start flag
      String content = deriveEndName(data);
      
      return Container(
        padding: const EdgeInsets.only(bottom: 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left rail area with fixed width
            Container(
              width: _railAreaWidth,
              child: Column(
                children: [
                  // Flag icon circle (always end flag now)
                  Center(
                    child: Container(
                      width: _indicatorSize,
                      height: _indicatorSize,
                      decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: grey, width: 3),
                      ),
                      child: Icon(
                        Icons.flag, 
                        size: 10, 
                        color: grey
                      ),
                    ),
                  ),
                  // No rail connector for end tile
                ],
              ),
            ),
            // Right content area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  content,
                  style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Build list of tiles -------------------------------------------------------------------
    final tiles = <Widget>[];
    
    // Debug: Add some info about the data
    if (segs.isEmpty) {
      tiles.add(
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No route segments available',
            style: textTheme.bodyMedium?.copyWith(color: Colors.red),
          ),
        ),
      );
    } else {
      // Process segments normally
      for (int i = 0; i < segs.length; i++) {
        final seg = segs[i];
        final isLast = i == segs.length - 1;
        final isFirst = i == 0;

        /// look-ahead: is the next segment a walk?
        final nextIsWalk =
            !isLast && segs[i + 1].transportType == 'walk';

        // Get previous segment's end stop if this is a walking segment
        String? previousEndStop;
        if ((seg.transportType == 'walk' || seg.transportType == null) && i > 0) {
          final prevSeg = segs[i - 1];
          if (prevSeg.transportType != 'walk') {
            previousEndStop = prevSeg.toStop;
          }
        }

        tiles.add(
          seg.transportType == 'walk' || seg.transportType == null
              ? _walkTile(seg, isLast: isLast, isFirst: isFirst, previousEndStop: previousEndStop)
              : _vehicleTile(
                  seg,
                  isLast: isLast,
                  nextIsWalk: nextIsWalk,
                ),
        );
      }
      tiles.add(_flagTile(isStart: false));
    }

    // UI scaffold ---------------------------------------------------------------------------
    return Material(
      color: Theme.of(context).colorScheme.surface, // Use theme surface color
      elevation: 12,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Route details',
                          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                    ),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1), shape: BoxShape.circle),
                      child: IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                        splashRadius: 20,
                        onPressed: onClose,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // Timeline itself (with left padding to keep rail on screen)
            SliverPadding(
              padding: const EdgeInsets.only(left: 16, right: 16),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    ...tiles,
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers -------------------------------------------------------------------
  // ---------------------------------------------------------------------------
  String _minutes(int seconds) => '${(seconds / 60).round()} min';

  String _distance(double meters) =>
      meters >= 1000 ? '${(meters / 1000).toStringAsFixed(1)} km' : '${meters.round()} m';
}
