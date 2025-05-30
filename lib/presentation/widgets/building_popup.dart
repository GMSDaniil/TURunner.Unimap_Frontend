// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong.dart';
// import 'package:auth_app/domain/usecases/find_building_at_point.dart';
// import 'package:auth_app/service_locator.dart';

// class BuildingPopup extends StatelessWidget {
//   final String title;
//   final String? details;

//   const BuildingPopup({
//     Key? key,
//     required this.title,
//     this.details,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       child: SizedBox(
//         width: MediaQuery.of(context).size.width,
//         child: Padding(
//           padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Drag-handle
//               Center(
//                 child: Container(
//                   width: 40,
//                   height: 4,
//                   margin: const EdgeInsets.only(bottom: 16),
//                   decoration: BoxDecoration(
//                     color: Colors.grey[300],
//                     borderRadius: BorderRadius.circular(2),
//                   ),
//                 ),
//               ),

//               // Header row: title left, close button right
//               Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Title text
//                   Expanded(
//                     child: Text(
//                       title,
//                       style: Theme.of(context)
//                           .textTheme
//                           .titleLarge
//                           ?.copyWith(fontWeight: FontWeight.bold),
//                     ),
//                   ),

//                   // Close button
//                   Container(
//                     width: 28,
//                     height: 28,
//                     decoration: BoxDecoration(
//                       shape: BoxShape.circle,
//                       color: Colors.grey.shade200,
//                     ),
//                     child: IconButton(
//                       icon: const Icon(Icons.close, size: 16),
//                       splashRadius: 16,
//                       padding: const EdgeInsets.all(4),
//                       onPressed: () => Navigator.of(context).pop(),
//                     ),
//                   ),
//                 ],
//               ),

//               const SizedBox(height: 12),

//               // Details text
//               if (details != null) ...[
//                 Text(
//                   details!,
//                   style: Theme.of(context).textTheme.bodyMedium,
//                 ),
//                 const SizedBox(height: 16),
//               ],
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class MapScreen extends StatefulWidget {
//   @override
//   _MapScreenState createState() => _MapScreenState();
// }

// class _MapScreenState extends State<MapScreen> {
//   late MapController _mapController;
//   List<Marker> _markers = [];

//   @override
//   void initState() {
//     super.initState();
//     _mapController = MapController();
//     // Example: You should generate _markers from your building data
//     _markers = [
//       Marker(
//         point: LatLng(52.5200, 13.4050),
//         width: 40,
//         height: 40,
//         child: GestureDetector(
//           onTap: () => _onAnyTap(LatLng(52.5200, 13.4050)),
//           child: const Icon(Icons.location_on, color: Colors.purple, size: 30),
//         ),
//       ),
//     ];
//   }

//   Future<void> _onAnyTap(LatLng latlng) async {
//     // Use your use case to find a building at this point
//     final building = await sl<FindBuildingAtPoint>().call(latlng);

//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//       ),
//       builder: (_) => building != null
//           ? BuildingPopup(
//               title: building.name,
//               details: 'Coordinates: ${latlng.latitude}, ${latlng.longitude}',
//             )
//           : BuildingPopup(
//               title: 'Coordinates',
//               details: '${latlng.latitude}, ${latlng.longitude}',
//             ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Map Screen'),
//       ),
//       body: FlutterMap(
//         mapController: _mapController,
//         options: MapOptions(
//           onTap: (tapPosition, latlng) => _onAnyTap(latlng),
//         ),
//         children: [
//           TileLayer(
//             urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
//             userAgentPackageName: 'com.example.app',
//           ),
//           MarkerLayer(
//             markers: _markers,
//           ),
//         ],
//       ),
//     );
//   }
// }