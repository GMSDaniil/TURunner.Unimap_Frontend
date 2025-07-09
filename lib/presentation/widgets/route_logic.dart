import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:auth_app/data/models/route_data.dart';
import 'package:auth_app/data/models/route_segment.dart';
import 'package:auth_app/domain/usecases/find_walking_route.dart';
import 'package:auth_app/domain/usecases/find_bus_route.dart';
import 'package:auth_app/domain/usecases/find_scooter_route.dart';
import 'package:auth_app/data/models/findroute_req_params.dart';
import 'package:auth_app/service_locator.dart';
import 'package:auth_app/presentation/widgets/route_options_sheet.dart';
import 'package:flutter_map/flutter_map.dart';

//
// contains the functions onCreateRoute and onModeChanged to be called from the map.dart
//

  double _calculateDynamicZoom(List<LatLng> points) {
  if (points.isEmpty) return 15.0;
  if (points.length == 1) return 17.0;

  // Calculate bounding box
  double minLat = points.first.latitude;
  double maxLat = points.first.latitude;
  double minLng = points.first.longitude;
  double maxLng = points.first.longitude;

  for (final point in points) {
    minLat = math.min(minLat, point.latitude);
    maxLat = math.max(maxLat, point.latitude);
    minLng = math.min(minLng, point.longitude);
    maxLng = math.max(maxLng, point.longitude);
  }

  // Calculate the span
  final latSpan = maxLat - minLat;
  final lngSpan = maxLng - minLng;
  final maxSpan = math.max(latSpan, lngSpan);

  // Dynamic zoom based on span
  // These values can be adjusted based on your needs
  if (maxSpan > 0.05) return 12.0;      // Very wide area
  if (maxSpan > 0.02) return 13.0;      // Large area
  if (maxSpan > 0.01) return 14.0;      // Medium area
  if (maxSpan > 0.005) return 15.0;     // Small area
  if (maxSpan > 0.002) return 16.0;     // Very small area
  return 17.0;                          // Close zoom for tiny areas
}

class RouteLogic {
  /// [rebuildOnly] == true  → called from RoutePlanBar while the planner UI
  /// is already on-screen.  We must **not** pop any routes or auto-fit map.
  static int _busRequestToken = 0;
  static int _modeChangeToken = 0;
  
  static Future<void> onCreateRoute({
    required BuildContext context,
    required List<LatLng> route,
    required ValueNotifier<Map<TravelMode, RouteData>> routesNotifier,
    required void Function(void Function()) setState,
    required void Function(LatLng, double) animatedMapMove,
    required bool mounted,
    required TravelMode currentMode,
    required void Function({
      required ValueNotifier<Map<TravelMode, RouteData>> routesNotifier,
      required TravelMode currentMode,
      required ValueChanged<TravelMode> onModeChanged,
      required VoidCallback onClose,
    }) showRouteOptionsSheet,
    required ValueChanged<TravelMode> onModeChanged,
    bool rebuildOnly = false,     // ← your new arg
  }) async {
    final params = FindRouteReqParams(
      points: route.map((p) => MapPoint(p.latitude, p.longitude)).toList(),
    );

    if (!rebuildOnly) {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop(); // close the building sheet
      }

      showRouteOptionsSheet(
        routesNotifier: routesNotifier,
        currentMode: TravelMode.walk, // Start with walking selected
        onModeChanged: onModeChanged,
        onClose: () {
          setState(() => routesNotifier.value.clear());
          if (mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        },
      );
    }
    // Fetch and display the walking route immediately
    final walkingResult = await sl<FindWalkingRouteUseCase>().call(param: params);
    walkingResult.fold(
      (error) {
        if(context.mounted){
        setState((){
              final newMap = Map<TravelMode, RouteData>.from(routesNotifier.value);
              newMap[TravelMode.walk] = RouteData(segments: [], error: true);
              routesNotifier.value = newMap;
            });
        }
      },
      (routeResponse) {
        if (context.mounted) {
        setState(() {
          final newMap = Map<TravelMode, RouteData>.from(routesNotifier.value);
          newMap[TravelMode.walk] = RouteData(segments: routeResponse.segments.map((route) =>
            
              RouteSegment(
                mode: TravelMode.walk,
                path: route.foot,
                distanceMeters: route.distanceMeters,
                durrationSeconds: route.durationSeconds,
              ),
            
            ).toList());
          routesNotifier.value = newMap;
        });
        }

        // only pop the “Create Route” sheet & open the bottom sheet on first call
        if (!rebuildOnly) {
          if (mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();   // close the building sheet
          }
          
          List<LatLng> walkPath = [];
          for (final segment in routeResponse.segments) {
            walkPath.addAll(segment.foot);
          }
          if (walkPath.isNotEmpty) {
            final bounds = LatLngBounds.fromPoints(walkPath);
            animatedMapMove(bounds.center, _calculateDynamicZoom(walkPath));
          }

          // showRouteOptionsSheet(
          //   routesNotifier: routesNotifier,
          //   currentMode: TravelMode.walk,
          //   onModeChanged: onModeChanged,
          //   onClose: () {
          //     setState(() => routesNotifier.value.clear());
          //     if (mounted && Navigator.of(context).canPop()) {
          //       Navigator.of(context).pop();
          //     }
          //   },
          // );
        }
      },
    );

    // Instead of immediately applying, simply call bus and scooter to fetch data in background.
    // Their responses will populate the routesNotifier but not override the displayed walking route.
    final currentToken = ++_busRequestToken;
    sl<FindBusRouteUseCase>().call(param: params).then((busResult) {
      if (currentToken != _busRequestToken) {
        return;
      }
      busResult.fold(
        (error) {
        if(context.mounted){
          setState((){
              final newMap = Map<TravelMode, RouteData>.from(routesNotifier.value);
              newMap[TravelMode.bus] = RouteData(segments: [], error: true);
              routesNotifier.value = newMap;
            });
        }
        },
        (routeResponse) {
          if (context.mounted) {
          setState(() {
            final segments = <RouteSegment>[];
            for (final seg in routeResponse.segments) {
              // for (final seg in route.segments) {
                // Convert each segment to RouteSegment
              segments.add(
                RouteSegment(
                  mode: seg.type == 'walk' ? TravelMode.walk : TravelMode.bus,
                  path: seg.polyline,
                  distanceMeters: seg.distanceMeters,
                  durrationSeconds: seg.durationSeconds,
                  departureTime: seg.departureTime,
                  arrivalTime: seg.arrivalTime,
                  precisePolyline: seg.precisePolyline,
                  transportType: seg.transportType,
                  transportLine: seg.transportLine,
                  fromStop: seg.fromStop,
                  toStop: seg.toStop,
                  numStops: seg.polyline.length-1
                ),
              );
              // }
            }
            
            
              final newMap = Map<TravelMode, RouteData>.from(routesNotifier.value);
              newMap[TravelMode.bus] = RouteData(segments: segments);
              routesNotifier.value = newMap;
            
            
            
          });
          }
          // Note: Do not update currentMode here.
        },
      );
    });
    
    sl<FindScooterRouteUseCase>().call(param: params).then((scooterResult) {
      scooterResult.fold(
        (error) {
        if(context.mounted){

          setState((){
              final newMap = Map<TravelMode, RouteData>.from(routesNotifier.value);
              newMap[TravelMode.scooter] = RouteData(segments: [], error: true);
              routesNotifier.value = newMap;
            });
        }
        },
        (response) {
          List<RouteSegment> scooterSegments = [];
          for (final seg in response.segments){
              scooterSegments.add(
                RouteSegment(
                  mode: seg.type.toLowerCase() == 'walking'
                      ? TravelMode.walk
                      : TravelMode.scooter,
                  path: seg.polyline,
                  distanceMeters: seg.distanceMeters,
                  durrationSeconds: seg.durationSeconds,
                ),
              );
          }
          if (context.mounted) {
          setState(() {
            final newMap = Map<TravelMode, RouteData>.from(routesNotifier.value);
            newMap[TravelMode.scooter] = RouteData(segments: scooterSegments);
            routesNotifier.value = newMap;
          });
          }
          // Note: Again, do not invoke updateCurrentMode here.
        },
      );
    });
  }

  Future<void> waitForBusRoute(ValueNotifier<Map<TravelMode, RouteData>> routesNotifier) {
    final completer = Completer<void>();
    void listener() {
      final busRoute = routesNotifier.value[TravelMode.bus];
      if (busRoute != null && busRoute.segments.isNotEmpty) {
        routesNotifier.removeListener(listener);
        completer.complete();
      }
    }
    routesNotifier.addListener(listener);
    // In case the value is already present
    listener();
    return completer.future;
  }

  static Future<void> onModeChanged({
    required BuildContext context,
    required TravelMode mode,
    required List<LatLng> route,
    required ValueNotifier<Map<TravelMode, RouteData>> routesNotifier,
    required void Function(void Function()) setState,
    // A callback to update the current mode in your state
    required ValueChanged<TravelMode> updateCurrentMode,
  }) async {

    final currentModeToken = ++_modeChangeToken;
    if (routesNotifier.value.containsKey(mode)) {
      setState(() {
        updateCurrentMode(mode);
      });
      return;
    }
    if (mode == TravelMode.bus) {
      // final params = FindRouteReqParams(
      //   fromLat: currentLocation?.latitude ?? 52.5135,
      //   fromLon: currentLocation?.longitude ?? 13.3245,
      //   toLat: destination.latitude,
      //   toLon: destination.longitude,
      // );
      // final result = await sl<FindBusRouteUseCase>().call(param: params);

      // result.fold(
      //   (error) {
      //     ScaffoldMessenger.of(context).showSnackBar(
      //       SnackBar(content: Text('Error: $error')),
      //     );
      //   },
      //   (route) {
      //     final segments = <RouteSegment>[];
      //     for (final seg in route.segments) {
      //       segments.add(
      //         RouteSegment(
      //           mode: seg.type == 'walk' ? TravelMode.walk : TravelMode.bus,
      //           path: seg.polyline,
      //           distanceMeters: seg.distanceMeters,
      //           durrationSeconds: seg.durationSeconds,
      //           precisePolyline: seg.precisePolyline,
      //           transportType: seg.transportType,
      //           transportLine: seg.transportLine,
      //           fromStop: seg.fromStop,
      //           toStop: seg.toStop,
      //         ),
      //       );
      //     }
      //     setState(() {
      //       final newMap = Map<TravelMode, RouteData>.from(routesNotifier.value);
      //       newMap[TravelMode.bus] = RouteData(segments: segments);
      //       routesNotifier.value = newMap;
      //       updateCurrentMode(TravelMode.bus);
      //     });
      //   },
      // );


      //KOSITL N1 with timeout (max 30 seconds)
      final startTime = DateTime.now();
      bool timedOut = false;
      while (!routesNotifier.value.containsKey(mode)) {
        if (DateTime.now().difference(startTime).inSeconds >= 30) {
          timedOut = true;
          break;
        }
        print("delaying bus route creation");
        await Future.delayed(const Duration(milliseconds: 300));
      }

      if (timedOut) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No route can be found at the moment (timeout)')),
        );
        return;
      }

      if (currentModeToken != _modeChangeToken) {
        print("Mode changed after bus route loaded, not updating current mode");
        return;
      }

      //KOSTIL N2
      if (!routesNotifier.value.containsKey(TravelMode.walk) || 
          routesNotifier.value[TravelMode.walk]!.segments.last.path.last != route.last) {
        return;
      }

      setState(() {
        updateCurrentMode(mode);
      });

    } else if (mode == TravelMode.scooter) {
      final params = FindRouteReqParams(
        points: route.map((p) => MapPoint(p.latitude, p.longitude)).toList(),
      );
      final result = await sl<FindScooterRouteUseCase>().call(param: params);

      result.fold(
        (error) {
        if(context.mounted){
          setState((){
              final newMap = Map<TravelMode, RouteData>.from(routesNotifier.value);
              newMap[TravelMode.scooter] = RouteData(segments: [], error: true);
              routesNotifier.value = newMap;
            });
        }
        },
        (response) {
          List<RouteSegment> scooterSegments = [];
          for (final seg in response.segments){
              scooterSegments.add(
                RouteSegment(
                  mode: seg.type.toLowerCase() == 'walking'
                      ? TravelMode.walk
                      : TravelMode.scooter,
                  path: seg.polyline,
                  distanceMeters: seg.distanceMeters,
                  durrationSeconds: seg.durationSeconds,
                ),
              );
          }
          if (context.mounted) {
          setState(() {
            final newMap = Map<TravelMode, RouteData>.from(routesNotifier.value);
            newMap[TravelMode.scooter] = RouteData(segments: scooterSegments);
            routesNotifier.value = newMap;
            updateCurrentMode(TravelMode.scooter);
          });
          }
        },
      );
    }
  }


  
}

List<Marker> buildScooterMarkers(List<RouteSegment> segments) {
  final scooterMarkers = <Marker>[];
  for (final seg in segments) {
    if (seg.mode == TravelMode.scooter && seg.path.isNotEmpty) {
      scooterMarkers.add(
        Marker(
          point: seg.path.first,
          width: 38,
          height: 38,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.orange.shade700, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.directions_bike,
                color: Colors.orange.shade700,
                size: 20,
              ),
            ),
          ),
        ),
      );
    }
  }
  return scooterMarkers;
}

typedef ClosestPointCalculator = LatLng Function(LatLng stop, List<LatLng> polyline);

List<LatLng> buildBusStopMarkers({
  required List<RouteSegment> segments,
  required ClosestPointCalculator closestPointCalculator,
}) {
  final busStopPoints = <LatLng>[];
  for (final seg in segments) {
    if (seg.mode == TravelMode.bus && seg.precisePolyline != null) {
      for (final stop in seg.path) {
        // Calculate the closest point on the precise polyline to the stop.
        final markerPoint = closestPointCalculator(stop, seg.precisePolyline!);
        busStopPoints.add(markerPoint);
      }
    }
  }
  return busStopPoints;
}

class RoutePlanningPage extends StatefulWidget {
  @override
  _RoutePlanningPageState createState() => _RoutePlanningPageState();
}

class _RoutePlanningPageState extends State<RoutePlanningPage> {
  final TextEditingController _startCtl = TextEditingController();
  final TextEditingController _destCtl = TextEditingController();
  final List<TextEditingController> _stopCtls = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Route Planning'),
        actions: [
          IconButton(
            icon: Icon(Icons.swap_horiz),
            onPressed: _swap,
          ),
        ],
      ),
      body: Column(
        children: [
          // Start and Destination Fields
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _startCtl,
                    decoration: InputDecoration(
                      labelText: 'Start',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _destCtl,
                    decoration: InputDecoration(
                      labelText: 'Destination',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Intermediate Stops
          Expanded(
            child: ListView.builder(
              itemCount: _stopCtls.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: TextField(
                    controller: _stopCtls[index],
                    decoration: InputDecoration(
                      labelText: 'Stop ${index + 1}',
                      border: OutlineInputBorder(),
                    ),
                  ),
                );
              },
            ),
          ),
          // Add Stop Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _stopCtls.add(TextEditingController());
                });
              },
              child: Text('Add Stop'),
            ),
          ),
        ],
      ),
    );
  }

  /* ═══════════════════════━  actions  ━═════════════════════════ */
   void _swap() {
  setState(() {
    // ➊ gather every controller in order
    final ctrls = <TextEditingController>[
      _startCtl,
      ..._stopCtls,
      _destCtl,
    ];

    // ➋ take their texts, reverse the list,
    //    then put the texts back into the same controllers
    final reversedTexts =
        ctrls.map((c) => c.text).toList().reversed.toList();

    for (var i = 0; i < ctrls.length; i++) {
      ctrls[i].text = reversedTexts[i];
    }
  });
}

}