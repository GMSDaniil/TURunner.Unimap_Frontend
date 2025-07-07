import 'package:sunrise_sunset_calc/sunrise_sunset_calc.dart';
import 'package:latlong2/latlong.dart';

enum MapTheme {
  dawn,
  day,
  dusk,
  night;

  @override
  String toString() {
    switch (this) {
      case MapTheme.dawn:
        return 'dawn';
      case MapTheme.day:
        return 'day';
      case MapTheme.dusk:
        return 'dusk';
      case MapTheme.night:
        return 'night';
    }
  }
}



class ThemeManager {
  static const LatLng _berlinLocation = LatLng(52.5125, 13.3269); // TU Berlin
  
  static MapTheme getCurrentTheme() {
    final now = DateTime.now();
    
    // Calculate sunrise and sunset for Berlin
    final sunriseSunset = getSunriseSunset(
      _berlinLocation.latitude,
      _berlinLocation.longitude,
      Duration(hours: 0),
      now,
    );
    
    final sunrise = sunriseSunset.sunrise;
    final sunset = sunriseSunset.sunset;
    
    // Define transition periods (in minutes)
    const dawnDuration = 45; // 45 minutes before sunrise
    const duskDuration = 45; // 45 minutes after sunset
    
    final dawnStart = sunrise.subtract(Duration(minutes: dawnDuration));
    final dawnEnd = sunrise.add(Duration(minutes: 15)); // 15 minutes after sunrise
    final duskStart = sunset.subtract(Duration(minutes: 15)); // 15 minutes before sunset
    final duskEnd = sunset.add(Duration(minutes: duskDuration));
    
    // Determine current theme based on time
    if (now.isAfter(dawnStart) && now.isBefore(dawnEnd)) {
      return MapTheme.dawn;
    } else if (now.isAfter(dawnEnd) && now.isBefore(duskStart)) {
      return MapTheme.day;
    } else if (now.isAfter(duskStart) && now.isBefore(duskEnd)) {
      return MapTheme.dusk;
    } else {
      return MapTheme.night;
    }
  }

}