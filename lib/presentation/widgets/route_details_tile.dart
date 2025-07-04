import 'package:flutter/material.dart';
import 'package:auth_app/data/models/route_data.dart';

class RouteDetailsTile extends StatelessWidget {
  final RouteData? data;
  const RouteDetailsTile({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (data == null) {
      return const Text('No route details available');
    }
    // You can expand this with more details as needed
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Route Details', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        Text('Segments: ${data!.segments.length}'),
        // Add more fields as needed
        // Example: show all segment types
        ...data!.segments.map((s) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text('- ${s.mode.toString().split('.').last} from ${s.fromStop ?? "?"} to ${s.toStop ?? "?"}'),
        )),
      ],
    );
  }
}
