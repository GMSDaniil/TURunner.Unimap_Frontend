import 'package:auth_app/domain/entities/weather.dart';

class WeatherInfo extends WeatherInfoEntity {
  WeatherInfo({
    required super.temperature,
    required super.description,
    required super.iconUrl,
    required super.airQualityIndex,
    required super.location,
    required super.lat,
    required super.lon,
  });

  factory WeatherInfo.fromJson(Map<String, dynamic> json) {
    return WeatherInfo(
      temperature: (json['temperature'] as num).toDouble(),
      description: json['description'] ?? '',
      iconUrl: json['icon_url'] ?? '',
      airQualityIndex: json['air_quality_index'] ?? 0,
      location: json['location'] ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lon: (json['lon'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
