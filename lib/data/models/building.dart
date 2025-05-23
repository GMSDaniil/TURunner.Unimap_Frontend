import 'dart:typed_data';

class Building {
  final int id;
  final String name;
  final double lat;
  final double lng;

  Building({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
  });

  factory Building.fromJson(Map<String, dynamic> json) {
    final geom = json['geom'] as String;

    try {
      // Extract first lat/lng pair from WKB hex
      // This is NOT a proper parser, but works for your file
      // We're looking for 2 floats right after "010300000001" → Polygon header
      final bytes = _hexToBytes(geom);
      final byteData = ByteData.sublistView(bytes);

      // Skip WKB header (skip 45 bytes = 1 + 4 + 4 + 4 + 4 + 4 + 4 + 4 + 4)
      // The first pair of doubles (lng, lat) starts at byte 57
      final x = byteData.getFloat64(57, Endian.little);
      final y = byteData.getFloat64(65, Endian.little);

      return Building(id: json['id'], name: json['name'], lat: y, lng: x);
    } catch (e) {
      print('❌ Failed to decode geometry for ${json['name']}: $e');
      rethrow;
    }
  }

  static Uint8List _hexToBytes(String hex) {
    final cleaned = hex.replaceAll(RegExp(r'[^0-9A-Fa-f]'), '');
    final length = cleaned.length ~/ 2;
    final result = Uint8List(length);
    for (int i = 0; i < length; i++) {
      result[i] = int.parse(cleaned.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return result;
  }
}