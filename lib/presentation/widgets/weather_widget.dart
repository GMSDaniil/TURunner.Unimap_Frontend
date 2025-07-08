import 'package:auth_app/data/models/coordinates.dart';
import 'package:dartz/dartz.dart' hide State;
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:auth_app/service_locator.dart';
import 'package:auth_app/domain/usecases/get_weather_info.dart';
import 'package:auth_app/data/models/get_weather_info_req_params.dart';
import 'package:auth_app/data/models/weather_response.dart';
import 'package:auth_app/data/models/weather_info.dart';

/* Widget to display current weather information for a given location
   Uses FutureBuilder to fetch weather data asynchronously*/
class WeatherWidget extends StatefulWidget {
    // The location for which weather should be displayed
  final LatLng location;

  // If true, displays weather info vertically (column), otherwise horizontally (row)
  //final bool vertical;
  final void Function(WeatherInfo weather)? onWeatherChanged;

  const WeatherWidget({super.key, required this.location, this.onWeatherChanged});

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  Future<Either<String, WeatherResponse>>? _weatherFuture;
  WeatherResponse? _cached;

  // ── shared, in-memory cache across every WeatherWidget instance ──────────
  static final Map<String, WeatherResponse> _globalCache = {};
  static final Map<String, DateTime> _globalFetchTime = {};

  void _fetchWeatherIfNeeded({bool force = false}) {
    final now = DateTime.now();

    // key with ~100 m precision — plenty for a campus map
    final key = '${widget.location.latitude.toStringAsFixed(3)},'
                '${widget.location.longitude.toStringAsFixed(3)}';

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
        lat: widget.location.latitude,
        lon: widget.location.longitude,
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
  void didUpdateWidget(covariant WeatherWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location != widget.location) {
      _fetchWeatherIfNeeded(force: true);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    _fetchWeatherIfNeeded();
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
}
class _AqiInfo {
  final String label;
  final Color color;
  _AqiInfo(this.label, this.color);
}