import 'package:auth_app/data/models/travel_mode.dart';
import 'package:flutter/material.dart';
import 'package:auth_app/data/models/route_data.dart';
import 'package:auth_app/data/models/route_segment.dart';

/// Custom scroll behavior that removes glow/overscroll effects
class _NoGlowScrollBehavior extends ScrollBehavior {
  const _NoGlowScrollBehavior();

  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}

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
    this.scrollController,
  });

  final RouteData? data;
  final VoidCallback onClose;
  final String Function(RouteData?) deriveStartName;
  final String Function(RouteData?) deriveEndName;
  final ScrollController? scrollController;

  // Visual constants
  static const double _railThickness = 24;
  static const double _indicatorSize =
      34.5; // Circle + border should be bigger than rail
  static const double _railAreaWidth = 50; // Fixed width for the rail area
  static const double _contentVerticalOffset = 5.7; // Tune this value to align text with icons


  (Color, IconData) _styleFor(RouteSegment s) {
    // Note: context is not available here, so use static colors for all except bus
    switch (s.transportType) {
      case 'bus':
        return (const Color(0xFFB000B5), Icons.directions_bus); // Purple
      case 'subway':
        return (const Color(0xFF1976D2), Icons.subway); // Blue
      case 'tram':
        return (const Color(0xFFD32F2F), Icons.tram); // Red
      case 'suburban':
      case 'sbahn':
        return (const Color(0xFF388E3C), Icons.train); // Green (S-Bahn)
      case 'regional':
        return (const Color(0xFF795548), Icons.train); // Brown (Regional)
      case 'express':
        return (const Color(0xFFFFD600), Icons.train); // Gold (Express)
      case 'ferry':
        return (const Color(0xFF00B8D4), Icons.directions_boat); // Teal (Ferry)
      case 'scooter':
        return (const Color(0xFFFFA500), Icons.electric_scooter); // Orange
      default:
        return (Colors.grey.shade400, Icons.directions_walk);
    }
  }

  @override
  Widget build(BuildContext context) {
    final segs = data?.segments ?? const <RouteSegment>[];
    final textTheme = Theme.of(context).textTheme;

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
      final pill =
          segment.type != 'walk' && segment.transportType != 'walk' && segment.transportLine != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: colour,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                segment.transportLine!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.surface,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
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
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.surface.withOpacity(0.3),
                          width: 3,
                        ),
                      ),
                      child: Icon(
                        icon,
                        size: 20,
                        color: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                  ),
                  // Rail connector below
                  if (!isLast)
                    Center(
                      child: nextIsWalk
                          ? Container(
                              margin: EdgeInsets.only(top: 34.4),
                              width: _railThickness,
                              height: 114,
                              child: CustomPaint(
                                painter: DashedLinePainter(
                                  color: colour,
                                  thickness: _railThickness / 3,
                                  dash: 3.5,
                                  gap: 15,
                                ),
                              ),
                            )
                          : Container(
                              margin: EdgeInsets.only(top: 34.4),
                              width: _railThickness,
                              height: 114,
                              color: colour,
                            ),
                    ),
                ],
              ),
            ),
            // Right content area
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 8,
                  top: _contentVerticalOffset + 0.7,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            segment.fromStop ?? '',
                            style: textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (pill != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: pill,
                      ),
                    // Add divider line above ride stops text
                    if (segment.type != 'walk' && segment.transportType != 'walk')
                      Padding(
                        padding: const EdgeInsets.only(top: 17, bottom: 0),
                        child: Container(
                          height: 1,
                          color: Colors.grey.shade300,
                        ),
                      ),
                    if (segment.type != 'walk' && segment.transportType != 'walk')
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          'Ride ${stopCount > 0 ? stopCount : 1} stop${(stopCount > 0 ? stopCount : 1) == 1 ? '' : 's'} (${_minutes(segment.durationSeconds)})',
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    // Add divider line after ride stops text
                    if (segment.type != 'walk' && segment.transportType != 'walk')
                      Padding(
                        padding: const EdgeInsets.only(top: 16, bottom: 12),
                        child: Container(
                          height: 1,
                          color: Colors.grey.shade300,
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
    Widget _walkTile(
      RouteSegment segment, {
      required bool isLast,
      required bool isFirst,
      required bool isTransfer,
      String? previousEndStop,
    }) {
      final (colour, icon) = _styleFor(segment);

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
                  // Rail connector below (dashed) - draw first so it's behind the icon
                  Center(
                    child: Container(
                      margin: EdgeInsets.only(top: _indicatorSize / 2),
                      width: _railThickness,
                      height: 95,
                      child: CustomPaint(
                        painter: DashedLinePainter(
                          color: colour,
                          thickness: _railThickness / 3,
                          dash: 3.5, // Smaller dots
                          gap: 15, // Smaller gaps
                        ),
                      ),
                    ),
                  ),
                  // Walk icon circle - draw on top so it covers the dashed line
                  Center(
                    child: Container(
                      width: _indicatorSize,
                      height: _indicatorSize,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colour, width: 3),
                      ),
                      child: Icon(
                        isFirst
                            ? Icons.play_arrow
                            : isTransfer ? Icons.pause : Icons.logout, // Start icon for first segment, hop off icon for others
                        size: 20,
                        color: colour,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Right content area
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: 8, top: _contentVerticalOffset),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isFirst)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          deriveStartName(data),
                          style: textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    // Add divider line after "Start" label for first segment
                    if (isFirst)
                      Padding(
                        padding: const EdgeInsets.only(top: 13, bottom: 14),
                        child: Container(
                          height: 1,
                          color: Colors.grey.shade300,
                        ),
                      ),

                    if (isTransfer)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          'Stopover',
                          style: textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    // Add divider line after "Start" label for first segment
                    if (isTransfer)
                      Padding(
                        padding: const EdgeInsets.only(top: 13, bottom: 14),
                        child: Container(
                          height: 1,
                          color: Colors.grey.shade300,
                        ),
                      ),


                    if (previousEndStop != null)
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: 4,
                        ), //move walk nr 2 down
                        child: Text(
                          previousEndStop,
                          style: textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    // Add divider line above walk row
                    
                    if (previousEndStop != null)
                      (segment.durationSeconds != 0 || segment.distanceMeters != 0) ?
                      Padding(
                        padding: const EdgeInsets.only(top: 20, bottom: 0),
                        child: Container(
                          height: 1,
                          color: Colors.grey.shade300,
                        ),
                      ) : const SizedBox(height: 12,),
                    Padding(
                      padding: EdgeInsets.only(
                        top: previousEndStop != null ? 12 : 0,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.directions_walk,
                            size: 20,
                            color: textTheme.bodyMedium!.color,
                          ),
                          const SizedBox(width: 6),
                          segment.durationSeconds == 0 && segment.distanceMeters == 0 ? 
                          Expanded(child: Text(
                            'Transfer',
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                          )) :

                          Expanded(
                            child: Text(
                              'Walk ${_minutes(segment.durationSeconds)} (${_distance(segment.distanceMeters)})',
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Add divider line after walk time/distance for first segment
                    if (isFirst)
                      Padding(
                        padding: const EdgeInsets.only(top: 17, bottom: 12),
                        child: Container(
                          height: 1,
                          color: Colors.grey.shade300,
                        ),
                      ),
                    
                    if (isTransfer)
                      Padding(
                        padding: const EdgeInsets.only(top: 17, bottom: 12),
                        child: Container(
                          height: 1,
                          color: Colors.grey.shade300,
                        ),
                      ),
                    // Add divider line after walk time/distance for last walk segment (not first)
                    if (!isFirst && isLast)
                      Padding(
                        padding: const EdgeInsets.only(top: 17, bottom: 12),
                        child: Container(
                          height: 1,
                          color: Colors.grey.shade300,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    /// Scooter segment tile ----------------------------------------------------------------
    Widget _scooterTile(
      RouteSegment segment, {
      required bool isLast,
      required bool isFirst,
      String? previousEndStop,
    }) {
      const scooterColor = Color(0xFFFFA500); // Force orange color
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
                  // Rail connector below (solid orange line) - always show for scooter
                  Center(
                    child: Container(
                      margin: EdgeInsets.only(top: _indicatorSize / 2),
                      width: _railThickness / 3, // Same thickness as dashed line
                      height: 95,
                      color: scooterColor, // Force orange color for scooter
                    ),
                  ),
                  // Scooter icon circle
                  Center(
                    child: Container(
                      width: _indicatorSize,
                      height: _indicatorSize,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: scooterColor, width: 3),
                      ),
                      child: Icon(
                        Icons.electric_scooter,
                        size: 20,
                        color: scooterColor,
                      ),
                    ),
                  ),
                  // Ride label positioned in the middle of the orange line
                  Positioned(
                    top: _indicatorSize + 25, // Position it in the middle of the line
                    left: _railAreaWidth + 8, // Extend into the content area
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: scooterColor, width: 1),
                      ),
                      child: Text(
                        'Ride ${_minutes(segment.durationSeconds)} (${_distance(segment.distanceMeters)})',
                        style: textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: scooterColor,
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
                padding: EdgeInsets.only(left: 8, top: _contentVerticalOffset),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isFirst)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          deriveStartName(data),
                          style: textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    // Add divider line after "Start" label for first segment
                    if (isFirst)
                      Padding(
                        padding: const EdgeInsets.only(top: 13, bottom: 14),
                        child: Container(
                          height: 1,
                          color: Colors.grey.shade300,
                        ),
                      ),
                    if (previousEndStop != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 0, bottom: 8), // Removed top padding to align with icon
                        child: Text(
                          "Scooter location",
                          style: textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    // Add divider line above scooter row
                    if (previousEndStop != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 0), // Added spacing to maintain symmetry
                        child: Container(
                          height: 1,
                          color: Colors.grey.shade300,
                        ),
                      ),
                    // Add constant "Scooter location" text
                    if (previousEndStop == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 0, bottom: 8), // Aligned with icon
                        child: Text(
                          "Scooter location",
                          style: textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    // Add divider line above scooter row for first segment
                    if (previousEndStop == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 0), // Reduced to bring closer to ride label
                        child: Container(
                          height: 1,
                          color: Colors.grey.shade300,
                        ),
                      ),
                    Padding(
                      padding: EdgeInsets.only(top: previousEndStop != null ? 12 : 12), // Reduced padding to center around ride label
                      child: Row(
                        children: [
                          Icon(Icons.electric_scooter, size: 20, color: textTheme.bodyMedium!.color),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Ride ${_minutes(segment.durationSeconds)} (${_distance(segment.distanceMeters)})',
                              style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Add divider line after scooter time/distance for first segment
                    if (isFirst)
                      Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 0), // Added spacing to match top symmetry
                        child: Container(
                          height: 1,
                          color: Colors.grey.shade300,
                        ),
                      ),
                    // Add divider line after scooter time/distance for last scooter segment (not first)
                    if (!isFirst && isLast)
                      Padding(
                        padding: const EdgeInsets.only(top: 17, bottom: 12),
                        child: Container(
                          height: 1,
                          color: Colors.grey.shade300,
                        ),
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
                      child: Icon(Icons.stop, size: 24, color: grey),
                    ),
                  ),
                  // No rail connector for end tile
                ],
              ),
            ),
            // Right content area
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: 8, top: _contentVerticalOffset),
                child: Text(
                  content,
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
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
        
        // Use both type field and transportType for walk detection
        final isWalk = seg.type == 'walk' || seg.transportType == 'walk' || seg.transportType == null || seg.mode.toString() == TravelMode.walk.toString();
        final isTransfer = (i > 0 && segs[i - 1].mode.toString() == TravelMode.walk.toString() && isWalk);
        // Use the helper method to detect scooter segments
        final isScoot = isScooter(seg);
        
        // Check if this is a zero-duration/distance walk
        // bool isZeroWalk = false;
        // if (isWalk) {
        //   isZeroWalk = seg.durationSeconds == 0 && seg.distanceMeters == 0;
        // }

        // Skip zero walks completely
        // if (isZeroWalk) {
        //   continue;
        // }

        /// look-ahead: is the next segment a walk?
        final nextIsWalk = !isLast && (segs[i + 1].type == 'walk' || segs[i + 1].transportType == 'walk');

        // Get previous segment's end stop if this is a walking or scooter segment
        String? previousEndStop;
        if ((isWalk || isScoot) && i > 0) {
          final prevSeg = segs[i - 1];
          if (prevSeg.type != 'walk' && prevSeg.transportType != 'walk' && !isScooter(prevSeg)) {
            previousEndStop = prevSeg.toStop;
          }
        }

        tiles.add(
          isScoot
              ? _scooterTile(
                  seg,
                  isLast: isLast,
                  isFirst: isFirst,
                  previousEndStop: previousEndStop,
                )
              : isWalk
                  ? _walkTile(
                      seg,
                      isLast: isLast,
                      isFirst: isFirst,
                      isTransfer: isTransfer,
                      previousEndStop: previousEndStop,
                    )
                  : _vehicleTile(seg, isLast: isLast, nextIsWalk: nextIsWalk),
        );
      }
      tiles.add(_flagTile(isStart: false));
    }

    // UI scaffold ---------------------------------------------------------------------------
    return Material(
      color: Theme.of(context).colorScheme.surface, // Use theme surface color
      elevation: 12,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            // --- Compact route summary bar ---
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ..._buildRouteSummaryBar(segs, textTheme, context),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    margin: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                      splashRadius: 20,
                      onPressed: onClose,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Expanded(
              child: ScrollConfiguration(
                behavior: const _NoGlowScrollBehavior(),
                child: CustomScrollView(
                  controller: scrollController,
                  physics: const ClampingScrollPhysics(),
                  slivers: [
                    // Timeline itself (with left padding to keep rail on screen)
                    SliverPadding(
                      padding: const EdgeInsets.only(left: 16, right: 16),
                      sliver: SliverToBoxAdapter(
                        child: Column(children: [...tiles]),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// Builds the compact route summary bar (chips/icons/arrows)
  List<Widget> _buildRouteSummaryBar(List<RouteSegment> segs, TextTheme textTheme, BuildContext context) {
    final List<Widget> widgets = [];
    for (int i = 0; i < segs.length; i++) {
      final seg = segs[i];
      final isScoot = isScooter(seg);
      final isWalk = seg.type == 'walk' || seg.transportType == 'walk' || seg.transportType == null || seg.mode.toString() == TravelMode.walk.toString();
      final style = _styleFor(seg);
      final colour = style.$1;
      final icon = style.$2;

      if (i > 0) {
        if(seg.distanceMeters == 0 && seg.durrationSeconds == 0) continue;
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
        ));
      }

      if (isScoot) {
        widgets.add(Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: const Color(0xFFFFA500),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(Icons.electric_scooter, size: 16, color: Colors.white),
              const SizedBox(width: 4),
              Text(
                _minutes(seg.durationSeconds),
                style: textTheme.bodySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ));
      } else if (isWalk) {
        // if(seg.distanceMeters == 0 && seg.durrationSeconds == 0) continue;
        widgets.add(Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: Colors.grey.shade800,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(Icons.directions_walk, size: 16, color: Colors.white),
              const SizedBox(width: 4),
              Text(
                _minutes(seg.durationSeconds),
                style: textTheme.bodySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ));
      } else {
        // Vehicle: show colored chip with line name
        widgets.add(Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: colour,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: Colors.white),
              if (seg.transportLine != null) ...[
                const SizedBox(width: 4),
                Text(
                  seg.transportLine!,
                  style: textTheme.bodySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ]
            ],
          ),
        ));
      }
    }
    return widgets;
  }

  // ---------------------------------------------------------------------------
  // Helpers -------------------------------------------------------------------
  // ---------------------------------------------------------------------------
  String _minutes(int seconds) => '${(seconds / 60).round()} min';

  String _distance(double meters) => meters >= 1000
      ? '${(meters / 1000).toStringAsFixed(1)} km'
      : '${meters.round()} m';

  // Helper: is this a scooter segment?
  bool isScooter(RouteSegment s) => s.transportType == 'scooter' || s.mode.toString().contains('scooter');
}
