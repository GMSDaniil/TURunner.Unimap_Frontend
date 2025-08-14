import 'package:dartz/dartz.dart' hide State;
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:auth_app/service_locator.dart';
import 'package:auth_app/domain/usecases/get_weather_info.dart';
import 'package:auth_app/data/models/get_weather_info_req_params.dart';
import 'package:auth_app/data/models/weather_response.dart';
import 'package:auth_app/data/models/weather_info.dart';

/* Widget to display current weather information for a given location
   Uses FutureBuilder to fetch weather data asynchronously*/
class WeatherWidget extends StatefulWidget {
  // The location for which weather should be displayed (used when useCurrentLocation is false)
  final LatLng? location;

  // If true, resolve the user's current location once before fetching.
  final bool useCurrentLocation;

  // Fallback location if current location is unavailable or permissions are denied.
  final LatLng? fallbackLocation;

  final void Function(WeatherInfo weather)? onWeatherChanged;

  const WeatherWidget({
    super.key,
    required this.location,
    this.onWeatherChanged,
  })  : useCurrentLocation = false,
        fallbackLocation = null;

  const WeatherWidget.useCurrentLocation({
    super.key,
    this.fallbackLocation,
    this.onWeatherChanged,
  })  : useCurrentLocation = true,
        location = null;

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  Future<Either<String, WeatherResponse>>? _weatherFuture;
  WeatherResponse? _cached;
  LatLng? _resolvedLocation; // the actual location used for fetching

  // ── shared, in-memory cache across every WeatherWidget instance ──────────
  static final Map<String, WeatherResponse> _globalCache = {};
  static final Map<String, DateTime> _globalFetchTime = {};

  void _fetchWeatherIfNeeded({bool force = false}) {
    // Ensure we have a location to query. If in current-location mode and not yet resolved, skip.
    final loc = _resolvedLocation;
    if (loc == null) return;
    // Prevent spamming multiple requests if build runs repeatedly while a fetch is in-flight
    if (_weatherFuture != null && !force) {
      return;
    }

    final now = DateTime.now();

    // key with ~100 m precision — plenty for a campus map
    final key = '${loc.latitude.toStringAsFixed(2)},'
        '${loc.longitude.toStringAsFixed(2)}';

    // If we already fetched <15 min ago, just reuse it
    if (!force &&
        _globalCache.containsKey(key) &&
        now.difference(_globalFetchTime[key]!).inMinutes < 15) {
      _cached = _globalCache[key];
      _weatherFuture ??= Future.value(Right<String, WeatherResponse>(_cached!));
      return;
    }

    // Otherwise fetch fresh data and store it globally
    _weatherFuture = sl<GetWeatherInfoUseCase>().call(
      param: GetWeatherInfoReqParams(
        lat: loc.latitude,
        lon: loc.longitude,
      ),
    )..then((either) {
        either.fold((_) => null, (r) {
          _globalCache[key] = r;

          widget.onWeatherChanged?.call(r.weather);
          _globalFetchTime[key] = DateTime.now();
        });
      });
  }

  @override
  void initState() {
    super.initState();
    _fetchWeatherIfNeeded(force: true);
    if (widget.useCurrentLocation) {
      _resolveCurrentLocationOnce();
    } else {
  // If a static location is provided, use it immediately
  _resolvedLocation = widget.location;
    }
  }

  @override
  void didUpdateWidget(covariant WeatherWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If switching from a provided location to another provided location
    if (!widget.useCurrentLocation && widget.location != null) {
      final newLoc = widget.location!;
      if (_resolvedLocation != newLoc) {
        _resolvedLocation = newLoc;
        _fetchWeatherIfNeeded(force: false);
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Trigger fetch only when we have a resolved location
    _fetchWeatherIfNeeded();
    if (_resolvedLocation == null) {
      // Still resolving location
      return _weatherBox(
          child: const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ));
    }
        // Fetch weather data for the given location using the injected UseCase
    return FutureBuilder<Either<String, WeatherResponse>>(
      future: _weatherFuture,
      builder: (context, snapshot) {
        // ── 1) While waiting, keep last good data (no spinner) ────────────
        if (snapshot.connectionState == ConnectionState.waiting) {
          if (_cached != null) return _buildWeatherContent(_cached!.weather);
          // First fetch after login: show spinner until data arrives
          return _weatherBox(
              child: const CircularProgressIndicator(strokeWidth: 2));
        }
        
        // Show error icon if no data or an error occurred
        // ── 2) Error → fall back to last good (or cloud-off if none) ──────
        if (!snapshot.hasData || snapshot.data!.isLeft()) {
          if (_cached != null) return _buildWeatherContent(_cached!.weather);
          return _weatherBox(
              child: const Icon(Icons.cloud_off, color: Colors.grey));
        }

        // ── 3) Success → cache & show ─────────────────────────────────────
        final result = snapshot.data!.fold((l) => null, (r) => r)!;
        _cached = result;
        return _buildWeatherContent(result.weather);
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helper that renders the temperature-plus-AQI pill
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildWeatherContent(WeatherInfo weather) {
    final aqi = weather.airQualityIndex;
    final aqiColor = _getAqiColor(aqi);

    return _weatherBox(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (weather.iconUrl.isNotEmpty)
            Image.network(weather.iconUrl, width: 35, height: 35),
          const SizedBox(width: 6),
          Text(
            '${weather.temperature.toStringAsFixed(0)}°',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: aqiColor,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

   Color _getAqiColor(int aqi) {
    if (aqi <= 50) {
      return Colors.green;
    } else if (aqi <= 100) {
      return Colors.yellow[700]!;
    } else if (aqi <= 150) {
      return Colors.orange;
    } else if (aqi <= 200) {
      return Colors.red;
    } else if (aqi <= 300) {
      return Colors.purple;
    } else {
      return Colors.brown;
    }
  }

  Widget _weatherBox({required Widget child}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: child,
      );

  Future<void> _resolveCurrentLocationOnce() async {
    try {
      // Quick permission check and request once
      if (!await Geolocator.isLocationServiceEnabled()) {
        _resolvedLocation = widget.fallbackLocation;
        if (mounted) setState(() {});
        return;
      }

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        _resolvedLocation = widget.fallbackLocation;
        if (mounted) setState(() {});
        return;
      }

      // One-shot current position with a reasonable timeout
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );
      final candidate = LatLng(pos.latitude, pos.longitude);
      // If outside Berlin bounds, prefer campus (fallback) if provided
      _resolvedLocation = _isWithinBerlinBounds(candidate)
          ? candidate
          : (widget.fallbackLocation ?? candidate);
      if (mounted) setState(() {});
    } catch (_) {
      _resolvedLocation = widget.fallbackLocation;
      if (mounted) setState(() {});
    }
  }

  // Berlin bounds: SW (12.964, 52.313) – NE (13.826, 52.727)
  bool _isWithinBerlinBounds(LatLng p) {
    const double minLng = 12.964;
    const double maxLng = 13.826;
    const double minLat = 52.313;
    const double maxLat = 52.727;
    return p.longitude >= minLng &&
        p.longitude <= maxLng &&
        p.latitude >= minLat &&
        p.latitude <= maxLat;
  }
}
// removed unused _AqiInfo class