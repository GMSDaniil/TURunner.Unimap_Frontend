class GetWeatherInfoReqParams {
  final double lat;
  final double lon;

  GetWeatherInfoReqParams({required this.lat, required this.lon});

  Map<String, dynamic> toMap() => {'lat': lat, 'lon': lon};
}
