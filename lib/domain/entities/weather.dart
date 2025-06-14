class WeatherInfoEntity {
  final double temperature;
  final String description;
  final String iconUrl;
  final int airQualityIndex;
  final String location;
  final double lat;
  final double lon;

  WeatherInfoEntity({
    required this.temperature,
    required this.description,
    required this.iconUrl,
    required this.airQualityIndex,
    required this.location,
    required this.lat,
    required this.lon,
  });
}


/*
{
    "weather": {
        "temperature": 13.74,
        "description": "few clouds",
        "icon_url": "https://openweathermap.org/img/w/02d.png",
        "air_quality_index": 2
    },
    "location": "TU Berlin Campus",
    "coordinates": {
        "lat": 52.51254994596774,
        "lon": 13.326949151892109
    }
}  */

