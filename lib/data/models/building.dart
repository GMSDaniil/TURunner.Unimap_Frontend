import 'dart:typed_data';
import 'dart:math';

class Building {
  final int id;
  final String name;
  final List<List<double>> polygon; // [ [lng, lat], ... ]
  final double centroidLat;
  final double centroidLng;

  Building({
    required this.id,
    required this.name,
    required this.polygon,
    required this.centroidLat,
    required this.centroidLng,
  });

  factory Building.fromJson(Map<String, dynamic> json) {
    final geom = json['geom'] as String;
    final points = _decodePolygonFromWkbHex(geom);
    final centroid = _polygonCentroid(points);

    return Building(
      id: json['id'],
      name: json['name'],
      polygon: points,
      centroidLat: centroid[1],
      centroidLng: centroid[0],
    );
  }

  // Decode WKB hex for Polygon (SRID, MultiPolygon not supported here)
  static List<List<double>> _decodePolygonFromWkbHex(String hex) {
    final bytes = _hexToBytes(hex);
    final byteData = ByteData.sublistView(bytes);

    // Skip WKB header: 0-4 (byte order + type), 4-8 (SRID), 8-9 (num polygons), 9-13 (num rings), 13-17 (num points)
    // For your data, the first point count is at byte 45 (0x2D)
    // Let's parse the number of points
    final numPoints = byteData.getUint32(45, Endian.little);
    final points = <List<double>>[];
    int offset = 49; // Points start here

    for (int i = 0; i < numPoints; i++) {
      final lng = byteData.getFloat64(offset, Endian.little);
      final lat = byteData.getFloat64(offset + 8, Endian.little);
      points.add([lng, lat]);
      offset += 16;
    }
    return points;
  }

  // Centroid of polygon (Shoelace formula)
  static List<double> _polygonCentroid(List<List<double>> pts) {
    double area = 0, cx = 0, cy = 0;
    for (int i = 0; i < pts.length - 1; i++) {
      final x0 = pts[i][0], y0 = pts[i][1];
      final x1 = pts[i + 1][0], y1 = pts[i + 1][1];
      final a = x0 * y1 - x1 * y0;
      area += a;
      cx += (x0 + x1) * a;
      cy += (y0 + y1) * a;
    }
    area *= 0.5;
    if (area == 0) return pts[0];
    cx /= (6 * area);
    cy /= (6 * area);
    return [cx, cy];
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