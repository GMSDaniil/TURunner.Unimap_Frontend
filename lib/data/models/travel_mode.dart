// /// Central enum for all travel modes in UniMap.
// /// Import this everywhere you need TravelMode.

enum TravelMode { walk, bus, scooter, subway }

extension TravelModeExtension on TravelMode {
  bool isEqual(TravelMode other) {
    return this == other;
  }
}