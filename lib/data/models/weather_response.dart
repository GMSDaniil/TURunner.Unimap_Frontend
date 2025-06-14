import 'package:auth_app/data/models/weather_info.dart';
import 'package:auth_app/data/models/coordinates.dart';

class WeatherResponse {
  final WeatherInfo weather;
  final String location;
  final Coordinates coordinates;

  WeatherResponse({
    required this.weather,
    required this.location,
    required this.coordinates,
  });

  factory WeatherResponse.fromJson(Map<String, dynamic> json) {
    return WeatherResponse(
      weather: WeatherInfo.fromJson(json['weather']),
      location: json['location'] ?? '',
      coordinates: Coordinates.fromJson(json['coordinates']),
    );
  }
}
