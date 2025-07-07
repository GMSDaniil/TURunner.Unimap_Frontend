import 'package:auth_app/data/models/route_segment.dart';

class RouteData {
  final List<RouteSegment> segments;

  /// Custom start name provided by the route plan bar.
  final String? customStartName;

  final bool error;

  /// Custom end name provided by the route plan bar.
  final String? customEndName;

  RouteData({
    required this.segments,
    this.error = false,
    this.customStartName,
    this.customEndName,
  });

  double get totalDistance => segments.fold(0, (sum, s) => sum + s.distanceMeters);
  int get totalDuration => segments.fold(0, (sum, s) => sum + s.durrationSeconds);
}

extension RouteDataLabels on RouteData {
  /// Returns the real "start" label (first segment’s fromStop), or a sensible default.
  String get startName {
    // prefer user-entered custom name, then first segment stop
    if (customStartName != null && customStartName!.trim().isNotEmpty) {
      return customStartName!;
    }
    if (segments.isNotEmpty && segments.first.fromStop != null && segments.first.fromStop!.trim().isNotEmpty) {
      return segments.first.fromStop!;
    }
    return 'Start';
  }

  /// Returns the real "end" label (last segment’s toStop), or a sensible default.
  String get endName {
    // prefer user-entered custom name, then last segment stop
    if (customEndName != null && customEndName!.trim().isNotEmpty) {
      return customEndName!;
    }
    if (segments.isNotEmpty && segments.last.toStop != null && segments.last.toStop!.trim().isNotEmpty) {
      return segments.last.toStop!;
    }
    return 'Destination';
  }
}