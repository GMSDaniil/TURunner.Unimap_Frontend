class WeatherResponse {
  final Weather weather;
  final String location;
  final Coordinates coordinates;

  WeatherResponse({
    required this.weather,
    required this.location,
    required this.coordinates,
  });

  factory WeatherResponse.fromJson(Map<String, dynamic> json) {
    return WeatherResponse(
      weather: Weather.fromJson(json['weather']),
      location: json['location'] ?? '',
      coordinates: Coordinates.fromJson(json['coordinates']),
    );
  }
}

class Weather {
  final double temperature;
  final String description;
  final String iconUrl;
  final int airQualityIndex;

  Weather({
    required this.temperature,
    required this.description,
    required this.iconUrl,
    required this.airQualityIndex,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      temperature: (json['temperature'] as num).toDouble(),
      description: json['description'] ?? '',
      iconUrl: json['icon_url'] ?? '',
      airQualityIndex: json['air_quality_index'] ?? 0,
    );
  }
}

class Coordinates {
  final double lat;
  final double lon;

  Coordinates({required this.lat, required this.lon});

  factory Coordinates.fromJson(Map<String, dynamic> json) {
    return Coordinates(
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
    );
  }
}
