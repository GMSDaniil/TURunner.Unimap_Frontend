import 'package:auth_app/data/models/coordinates.dart';
import 'package:dartz/dartz.dart' hide State;
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:auth_app/service_locator.dart';
import 'package:auth_app/domain/usecases/get_weather_info.dart';
import 'package:auth_app/data/models/get_weather_info_req_params.dart';
import 'package:auth_app/data/models/weather_response.dart';
import 'package:auth_app/data/models/weather_info.dart';



class WeatherWidget extends StatefulWidget {
  final LatLng location;

  const WeatherWidget({super.key, required this.location});

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  Future<Either<String, WeatherResponse>>? _weatherFuture;
  DateTime? _lastFetchTime;

  @override
  void initState() {
    super.initState();
    _fetchWeatherIfNeeded(force: true);
  }

  void _fetchWeatherIfNeeded({bool force = false}) {
    final now = DateTime.now();
    if (force ||
        _lastFetchTime == null ||
        now.difference(_lastFetchTime!).inMinutes >= 15) {
      _weatherFuture = sl<GetWeatherInfoUseCase>().call(
        param: GetWeatherInfoReqParams(
          lat: widget.location.latitude,
          lon: widget.location.longitude,
        ),
      );
      _lastFetchTime = now;
    }
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
    return FutureBuilder<Either<String, WeatherResponse>>(
      future: _weatherFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _weatherBox(
            child: const CircularProgressIndicator(strokeWidth: 2),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isLeft()) {
          return _weatherBox(
            child: const Icon(Icons.cloud_off, color: Colors.grey),
          );
        }
        final weather = snapshot.data!
            .fold(
              (l) => WeatherResponse(
                weather: WeatherInfo(
                  iconUrl: '',
                  temperature: 0.0,
                  description: '',
                  airQualityIndex: 0,
                  location: '',
                  lat: 0.0,
                  lon: 0.0,
                ),
                location: '',
                coordinates: Coordinates(lat: 0.0, lon: 0.0),
              ),
              (r) => r,
            )
            .weather;
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
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
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
      },
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
          color: Colors.white.withOpacity(0.95),
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