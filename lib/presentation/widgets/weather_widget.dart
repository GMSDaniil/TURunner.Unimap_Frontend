import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:auth_app/service_locator.dart';
import 'package:auth_app/domain/usecases/get_weather_info.dart';
import 'package:auth_app/data/models/get_weather_info_req_params.dart';
import 'package:auth_app/data/models/weather_response.dart';
import 'package:auth_app/data/models/weather_info.dart';
import 'package:auth_app/data/models/coordinates.dart';
import 'package:dartz/dartz.dart';

/* Widget to display current weather information for a given location
   Uses FutureBuilder to fetch weather data asynchronously*/
class WeatherWidget extends StatelessWidget {
  // The location for which weather should be displayed
  final LatLng location;

  // If true, displays weather info vertically (column), otherwise horizontally (row)
  final bool vertical;

  const WeatherWidget({Key? key, required this.location, this.vertical = false})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Fetch weather data for the given location using the injected UseCase
    return FutureBuilder<Either<String, WeatherResponse>>(
      future: sl<GetWeatherInfoUseCase>().call(
        param: GetWeatherInfoReqParams(
          lat: location.latitude,
          lon: location.longitude,
        ),
      ),
      builder: (context, snapshot) {
        // Show loading indicator while waiting for data
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _weatherBox(
            child: const CircularProgressIndicator(strokeWidth: 2),
          );
        }
        // Show error icon if no data or an error occurred
        if (!snapshot.hasData || snapshot.data!.isLeft()) {
          return _weatherBox(
            child: const Icon(Icons.cloud_off, color: Colors.grey),
          );
        }
        // Extract weather data from the response
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

        // Display weather info in either a column or row layout
        return _weatherBox(
          child: vertical
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Weather icon if available
                        if (weather.iconUrl.isNotEmpty)
                          Image.network(weather.iconUrl, width: 22, height: 22),
                        const SizedBox(width: 6),
                        // Temperature
                        Text(
                          '${weather.temperature.toStringAsFixed(1)}°C',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    // Weather description (z.B. "clear sky")
                    Text(
                      weather.description,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Weather icon if available
                    if (weather.iconUrl.isNotEmpty)
                      Image.network(weather.iconUrl, width: 22, height: 22),
                    const SizedBox(width: 6),

                    // Temperature
                    Text(
                      '${weather.temperature.toStringAsFixed(1)}°C',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Weather description (z.B. "clear sky")
                    Text(
                      weather.description,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
        );
      },
    );
  }

  // widget to style the weather info box
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
