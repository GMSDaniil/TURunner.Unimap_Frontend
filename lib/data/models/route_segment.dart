import 'package:auth_app/presentation/widgets/route_options_sheet.dart';
import 'package:latlong2/latlong.dart';



class RouteSegment {
  final String? type; // "walk" or "transit" (from JSON)
  final TravelMode mode;
  final List<LatLng> path;
  final double distanceMeters;
  final int durrationSeconds;
  final List<LatLng>? precisePolyline;
  final String? transportType;
  final String? transportLine;
  final String? fromStop;
  final String? toStop;
  // Added fields for timeline UI
  final DateTime? departureTime;
  final DateTime? arrivalTime;
  final int? numStops;
  /// List of stop names or codes for this segment (if available)
  final List<String>? stops;
  final String? headsign;

  RouteSegment({
    this.type,
    required this.mode,
    required this.path,
    required this.distanceMeters,
    required this.durrationSeconds,
    this.precisePolyline,
    this.transportType,
    this.transportLine,
    this.fromStop,
    this.toStop,
    this.departureTime,
    this.arrivalTime,
    this.numStops,
    this.headsign,
    this.stops,
  });

  factory RouteSegment.fromJson(Map<String, dynamic> json) {
    return RouteSegment(
      type: json['Type'] ?? json['type'],
      mode: TravelMode.values.firstWhere(
        (e) => e.toString().split('.').last == (json['mode'] ?? '').toLowerCase(),
        orElse: () => TravelMode.walk,
      ),
      path: (json['Polyline'] ?? json['polyline'] ?? json['path'] ?? [])
          .map<LatLng>((e) => LatLng(e[0], e[1]))
          .toList(),
      distanceMeters: (json['DistanceMeters'] ?? json['distanceMeters'] ?? 0).toDouble(),
      durrationSeconds: json['DurationSeconds'] ?? json['durrationSeconds'] ?? 0,
      precisePolyline: (json['precisePolyline'] as List?)?.map((e) => LatLng(e[0], e[1])).toList(),
      transportType: json['TransportType'] ?? json['transportType'],
      transportLine: json['TransportLine'] ?? json['transportLine'],
      fromStop: json['FromStop'] ?? json['fromStop'],
      toStop: json['ToStop'] ?? json['toStop'],
      departureTime: json['DepartureTime'] != null ? DateTime.tryParse(json['DepartureTime']) : null,
      arrivalTime: json['ArrivalTime'] != null ? DateTime.tryParse(json['ArrivalTime']) : null,
      numStops: json['NumStops'] ?? json['numStops'],
      headsign: json['Headsign'] ?? json['headsign'],
      stops: (json['Stops'] as List?)?.map((e) => e.toString()).toList(),
    );
  }
}

/// Extension to get the number of stops for a segment, falling back to numStops, or inferring from stops list.
extension RouteSegmentStopCount on RouteSegment {
  /// Returns the number of stops for this segment, or a reasonable default if not available.
  int get stopCount {
    if (numStops != null) return numStops!;
    if (stops != null) return stops!.length;
    
    // For public transport segments, provide a reasonable default
    if (transportType != null && transportType != 'walk' && transportType != 'walking') {
      // If we have from and to stops, assume at least 1 stop (the destination)
      if (fromStop != null && toStop != null) return 1;
    }
    
    return 0;
  }
}

extension RouteSegmentTime on RouteSegment {
  String? get departureTimeFormatted =>
      departureTime != null ? _formatTime(departureTime!) : null;
  String? get arrivalTimeFormatted =>
      arrivalTime != null ? _formatTime(arrivalTime!) : null;
}

String _formatTime(DateTime dt) {
  // Use basic formatting to avoid DateFormat dependency issues
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

/// Provide a correctly spelled getter for duration
extension RouteSegmentDuration on RouteSegment {
  /// Returns the segment duration in seconds
  int get durationSeconds => durrationSeconds;
}