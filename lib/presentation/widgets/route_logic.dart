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

class RouteLogic {
  static Future<void> onCreateRoute({
    required BuildContext context,
    required LatLng latlng,
    required LatLng? currentLocation,
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
  }) async {
    final params = FindRouteReqParams(
      fromLat: currentLocation?.latitude ?? 52.5135,
      fromLon: currentLocation?.longitude ?? 13.3245,
      toLat: latlng.latitude,
      toLon: latlng.longitude,
    );

    // Fetch and display the walking route immediately
    final walkingResult = await sl<FindWalkingRouteUseCase>().call(param: params);
    walkingResult.fold(
      (error) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $error')));
      },
      (route) {
        setState(() {
          routesNotifier.value[TravelMode.walk] = RouteData(
            segments: [
              RouteSegment(
                mode: TravelMode.walk,
                path: route.foot,
                distanceMeters: route.distanceMeters,
                durrationSeconds: route.durationSeconds,
              ),
            ],
          );
        });
        // Pop the building sheet
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        // Fit map to show entire walking route
        final walkPath = route.foot;
        if (walkPath.isNotEmpty) {
          final bounds = LatLngBounds.fromPoints(walkPath);
          animatedMapMove(bounds.center, 16.5);
        }
        // Show the route options sheet with walking as current default
        showRouteOptionsSheet(
          routesNotifier: routesNotifier,
          currentMode: TravelMode.walk,
          onModeChanged: onModeChanged,
          onClose: () {
            setState(() {
              routesNotifier.value.clear();
            });
            if (mounted && Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        );
      },
    );

    // Instead of immediately applying, simply call bus and scooter to fetch data in background.
    // Their responses will populate the routesNotifier but not override the displayed walking route.
    sl<FindBusRouteUseCase>().call(param: params).then((busResult) {
      busResult.fold(
        (error) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Bus route error: $error')));
        },
        (route) {
          setState(() {
            final segments = <RouteSegment>[];
            for (final seg in route.segments) {
              segments.add(
                RouteSegment(
                  mode: seg.type == 'walk' ? TravelMode.walk : TravelMode.bus,
                  path: seg.polyline,
                  distanceMeters: seg.distanceMeters,
                  durrationSeconds: seg.durationSeconds,
                  precisePolyline: seg.precisePolyline,
                  transportType: seg.transportType,
                  transportLine: seg.transportLine,
                  fromStop: seg.fromStop,
                  toStop: seg.toStop,
                ),
              );
            }
            routesNotifier.value[TravelMode.bus] = RouteData(segments: segments);
          });
          // Note: Do not update currentMode here.
        },
      );
    });
    
    sl<FindScooterRouteUseCase>().call(param: params).then((scooterResult) {
      scooterResult.fold(
        (error) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Scooter route error: $error')));
        },
        (response) {
          final segments = response.segments.map((seg) {
            return RouteSegment(
              mode: seg.type.toLowerCase() == 'walking'
                  ? TravelMode.walk
                  : TravelMode.scooter,
              path: seg.polyline,
              distanceMeters: seg.distanceMeters,
              durrationSeconds: seg.durationSeconds,
            );
          }).toList();
          setState(() {
            routesNotifier.value[TravelMode.scooter] =
                RouteData(segments: segments);
          });
          // Note: Again, do not invoke updateCurrentMode here.
        },
      );
    });
  }

  static Future<void> onModeChanged({
    required BuildContext context,
    required TravelMode mode,
    required LatLng destination,
    required LatLng? currentLocation,
    required ValueNotifier<Map<TravelMode, RouteData>> routesNotifier,
    required void Function(void Function()) setState,
    // A callback to update the current mode in your state
    required ValueChanged<TravelMode> updateCurrentMode,
  }) async {
    if (routesNotifier.value.containsKey(mode)) {
      setState(() {
        updateCurrentMode(mode);
      });
      return;
    }

    if (mode == TravelMode.bus) {
      final params = FindRouteReqParams(
        fromLat: currentLocation?.latitude ?? 52.5135,
        fromLon: currentLocation?.longitude ?? 13.3245,
        toLat: destination.latitude,
        toLon: destination.longitude,
      );
      final result = await sl<FindBusRouteUseCase>().call(param: params);

      result.fold(
        (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $error')),
          );
        },
        (route) {
          final segments = <RouteSegment>[];
          for (final seg in route.segments) {
            segments.add(
              RouteSegment(
                mode: seg.type == 'walk' ? TravelMode.walk : TravelMode.bus,
                path: seg.polyline,
                distanceMeters: seg.distanceMeters,
                durrationSeconds: seg.durationSeconds,
                precisePolyline: seg.precisePolyline,
                transportType: seg.transportType,
                transportLine: seg.transportLine,
                fromStop: seg.fromStop,
                toStop: seg.toStop,
              ),
            );
          }
          setState(() {
            final newMap = Map<TravelMode, RouteData>.from(routesNotifier.value);
            newMap[TravelMode.bus] = RouteData(segments: segments);
            routesNotifier.value = newMap;
            updateCurrentMode(TravelMode.bus);
          });
        },
      );
    } else if (mode == TravelMode.scooter) {
      final params = FindRouteReqParams(
        fromLat: currentLocation?.latitude ?? 52.5135,
        fromLon: currentLocation?.longitude ?? 13.3245,
        toLat: destination.latitude,
        toLon: destination.longitude,
      );
      final result = await sl<FindScooterRouteUseCase>().call(param: params);

      result.fold(
        (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $error')),
          );
        },
        (response) {
          final segments = response.segments
              .map(
                (seg) => RouteSegment(
                  mode: seg.type.toLowerCase() == 'walking'
                      ? TravelMode.walk
                      : TravelMode.scooter,
                  path: seg.polyline,
                  distanceMeters: seg.distanceMeters,
                  durrationSeconds: seg.durationSeconds,
                ),
              )
              .toList();
          setState(() {
            final newMap = Map<TravelMode, RouteData>.from(routesNotifier.value);
            newMap[TravelMode.scooter] = RouteData(segments: segments);
            routesNotifier.value = newMap;
            updateCurrentMode(TravelMode.scooter);
          });
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

List<Marker> buildBusStopMarkers({
  required List<RouteSegment> segments,
  required ClosestPointCalculator closestPointCalculator,
}) {
  final busStopMarkers = <Marker>[];
  for (final seg in segments) {
    if (seg.mode == TravelMode.bus && seg.precisePolyline != null) {
      for (final stop in seg.path) {
        // Calculate the closest point on the precise polyline to the stop.
        final markerPoint = closestPointCalculator(stop, seg.precisePolyline!);
        busStopMarkers.add(
          Marker(
            point: markerPoint,
            width: 18,
            height: 18,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blue.shade700, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }
  }
  return busStopMarkers;
}