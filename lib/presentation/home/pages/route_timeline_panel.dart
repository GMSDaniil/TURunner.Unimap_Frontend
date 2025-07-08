// import 'package:flutter/material.dart';
// import 'package:auth_app/data/models/route_data.dart';
// import 'package:auth_app/data/models/route_segment.dart';
// import 'package:auth_app/data/models/travel_mode.dart';

// class RouteTimelinePanel extends StatelessWidget {
//   final RouteData? data;
//   final String Function(RouteData?) deriveStartName;
//   final String Function(RouteData?) deriveEndName;
//   final VoidCallback onClose;

//   const RouteTimelinePanel({
//     Key? key,
//     required this.data,
//     required this.deriveStartName,
//     required this.deriveEndName,
//     required this.onClose,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     final segments = data?.segments ?? [];
//     final startName = deriveStartName(data);
//     final endName = deriveEndName(data);
//     final theme = Theme.of(context);
//     final isDark = theme.brightness == Brightness.dark;
//     final departureTime = data?.departureTimeFormatted;
//     final arrivalTime = data?.arrivalTimeFormatted;

//     return ClipRRect(
//       borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
//       child: Material(
//         color: isDark ? const Color(0xFF18181C) : Colors.white,
//         child: SafeArea(
//           top: false,
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               // Top handle and close button
//               Padding(
//                 padding: const EdgeInsets.only(top: 12, left: 20, right: 8, bottom: 0),
//                 child: Row(
//                   children: [
//                     Container(
//                       width: 40,
//                       height: 4,
//                       decoration: BoxDecoration(
//                         color: Colors.grey.shade400,
//                         borderRadius: BorderRadius.circular(2),
//                       ),
//                     ),
//                     const Spacer(),
//                     IconButton(
//                       icon: const Icon(Icons.close, size: 22),
//                       splashRadius: 20,
//                       onPressed: onClose,
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 8),
//               // Timeline
//               Expanded(
//                 child: ListView(
//                   padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
//                   children: [
//                     _TimelineStep(
//                       icon: Icons.my_location,
//                       color: Colors.purple,
//                       title: startName,
//                       time: departureTime,
//                     ),
//                     ..._buildTimelineSteps(segments),
//                     _TimelineStep(
//                       icon: Icons.flag,
//                       color: Colors.green,
//                       title: endName,
//                       time: arrivalTime,
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   List<Widget> _buildTimelineSteps(List<RouteSegment> segments) {
//     final List<Widget> steps = [];
//     for (final seg in segments) {
//       if (seg.mode == TravelMode.walk) {
//         steps.add(_TimelineStep(
//           icon: Icons.directions_walk,
//           color: Colors.grey,
//           title: 'Walk ${(seg.durrationSeconds / 60).round()} min (${seg.distanceMeters.round()} m)',
//           subtitle: seg.toStop != null ? 'to ${seg.toStop}' : null,
//           time: seg.departureTimeFormatted,
//         ));
//       } else if (seg.mode == TravelMode.bus) {
//         steps.add(_TimelineStep(
//           icon: Icons.directions_bus,
//           color: Colors.purple,
//           title: '${seg.transportLine ?? seg.transportType?.toUpperCase() ?? 'Bus'}',
//           subtitle: 'Ride ${seg.numStops ?? ''} stops${seg.durrationSeconds != 0 ? ' (${(seg.durrationSeconds / 60).round()} min)' : ''}',
//           from: seg.fromStop,
//           to: seg.toStop,
//           time: seg.departureTimeFormatted,
//         ));
//       } else if (seg.mode == TravelMode.subway) {
//         steps.add(_TimelineStep(
//           icon: Icons.subway,
//           color: Colors.blue,
//           title: '${seg.transportLine ?? seg.transportType?.toUpperCase() ?? 'Subway'}',
//           subtitle: 'Ride ${seg.numStops ?? ''} stops${seg.durrationSeconds != 0 ? ' (${(seg.durrationSeconds / 60).round()} min)' : ''}',
//           from: seg.fromStop,
//           to: seg.toStop,
//           time: seg.departureTimeFormatted,
//         ));
//       } else if (seg.mode == TravelMode.scooter) {
//         steps.add(_TimelineStep(
//           icon: Icons.electric_scooter,
//           color: Colors.teal,
//           title: 'Scooter ${(seg.durrationSeconds / 60).round()} min (${seg.distanceMeters.round()} m)',
//           from: seg.fromStop,
//           to: seg.toStop,
//           time: seg.departureTimeFormatted,
//         ));
//       } else {
//         steps.add(_TimelineStep(
//           icon: Icons.directions,
//           color: Colors.blueGrey,
//           title: seg.transportType ?? 'Segment',
//           time: seg.departureTimeFormatted,
//         ));
//       }
//     }
//     return steps;
//   }
// }

// class _TimelineStep extends StatelessWidget {
//   final IconData icon;
//   final Color color;
//   final String title;
//   final String? subtitle;
//   final String? from;
//   final String? to;
//   final String? time;

//   const _TimelineStep({
//     Key? key,
//     required this.icon,
//     required this.color,
//     required this.title,
//     this.subtitle,
//     this.from,
//     this.to,
//     this.time,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 10),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             margin: const EdgeInsets.only(top: 2),
//             decoration: BoxDecoration(
//               color: color.withOpacity(0.12),
//               shape: BoxShape.circle,
//             ),
//             child: Icon(icon, color: color, size: 28),
//           ),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
//                 if (subtitle != null)
//                   Padding(
//                     padding: const EdgeInsets.only(top: 2),
//                     child: Text(subtitle!, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
//                   ),
//                 if (from != null || to != null)
//                   Padding(
//                     padding: const EdgeInsets.only(top: 2),
//                     child: Text(
//                       '${from != null ? 'From: $from' : ''}${from != null && to != null ? '  →  ' : ''}${to != null ? 'To: $to' : ''}',
//                       style: TextStyle(fontSize: 14, color: Colors.grey[500]),
//                     ),
//                   ),
//                 if (time != null)
//                   Padding(
//                     padding: const EdgeInsets.only(top: 2),
//                     child: Text(time!, style: TextStyle(fontSize: 13, color: Colors.grey[400])),
//                   ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
