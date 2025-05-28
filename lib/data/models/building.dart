import 'dart:typed_data';
import 'package:latlong2/latlong.dart';
import 'package:auth_app/domain/entities/building_entity.dart';

class BuildingModel extends BuildingEntity {
  BuildingModel({required String name, required List<LatLng> polygon})
      : super(name: name, polygon: polygon);

  factory BuildingModel.fromJson(Map<String, dynamic> json) {
    return BuildingModel(
      name: json['name'],
      polygon: parsePolygonOrMultiPolygonFromWKB(json['geom']),
    );
  }
}

/// Parses an EWKB hex string for Polygon or MultiPolygon and returns the largest ring as List<LatLng>.
///
/// This function reads the byte order (first byte) then the 4-byte geometry type which may include an SRID flag
/// (0x20000000). If that flag is set, the next 4 bytes are the SRID (which we discard) and the geometry type is
/// masked to its lower bits. Then, depending on whether the geometry is a Polygon (3) or MultiPolygon (6), we parse accordingly.
/// Finally, we return the largest ring (outer boundary) among all rings.
List<LatLng> parsePolygonOrMultiPolygonFromWKB(String wkbHex) {
  // Remove optional "0x" prefix.
  if (wkbHex.startsWith('0x')) wkbHex = wkbHex.substring(2);
  
  final bytes = Uint8List.fromList([
    for (int i = 0; i < wkbHex.length; i += 2)
      int.parse(wkbHex.substring(i, i + 2), radix: 16)
  ]);
  final byteData = ByteData.sublistView(bytes);

  int offset = 0;

  // Read byte order.
  bool isLE = byteData.getUint8(offset) == 1;
  offset += 1;

  // Read the raw geometry type.
  int rawGeomType = _readUint32(byteData, offset, isLE);
  offset += 4;
  
  // Check if SRID flag is present (0x20000000). If so, read and skip SRID.
  if ((rawGeomType & 0x20000000) != 0) {
    int srid = _readUint32(byteData, offset, isLE);
    offset += 4;
    // Mask out the SRID flag to get the actual geometry type.
    rawGeomType = rawGeomType & 0xFF;
  }
  
  // Now rawGeomType should be 3 (Polygon) or 6 (MultiPolygon)
  List<List<LatLng>> allRings = [];

  // Function to parse a single Polygon at the given start offset.
  void parsePolygon(int startOffset) {
    int localOffset = startOffset;
    // Each polygon has its own byte order.
    final bool polyIsLE = byteData.getUint8(localOffset) == 1;
    localOffset += 1;
    final int polyGeomType = _readUint32(byteData, localOffset, polyIsLE);
    localOffset += 4;
    if (polyGeomType != 3) {
      throw Exception('Expected Polygon geometry type, got $polyGeomType');
    }
    final int numRings = _readUint32(byteData, localOffset, polyIsLE);
    localOffset += 4;
    for (int r = 0; r < numRings; r++) {
      final int numPoints = _readUint32(byteData, localOffset, polyIsLE);
      localOffset += 4;
      final List<LatLng> points = [];
      for (int i = 0; i < numPoints; i++) {
        final double x = _readFloat64(byteData, localOffset, polyIsLE);
        localOffset += 8;
        final double y = _readFloat64(byteData, localOffset, polyIsLE);
        localOffset += 8;
        points.add(LatLng(y, x));
      }
      allRings.add(points);
    }
    offset = localOffset;
  }

  // Now parse based on geometry type.
  if (rawGeomType == 3) {
    // Single Polygon
    final int numRings = _readUint32(byteData, offset, isLE);
    offset += 4;
    for (int r = 0; r < numRings; r++) {
      final int numPoints = _readUint32(byteData, offset, isLE);
      offset += 4;
      final List<LatLng> points = [];
      for (int i = 0; i < numPoints; i++) {
        final double x = _readFloat64(byteData, offset, isLE);
        offset += 8;
        final double y = _readFloat64(byteData, offset, isLE);
        offset += 8;
        points.add(LatLng(y, x));
      }
      allRings.add(points);
    }
  } else if (rawGeomType == 6) {
    // MultiPolygon
    final int numPolygons = _readUint32(byteData, offset, isLE);
    offset += 4;
    for (int p = 0; p < numPolygons; p++) {
      parsePolygon(offset);
    }
  } else {
    throw Exception('Unsupported geometry type: $rawGeomType');
  }

  // Return the largest ring (by point count) – typically the outer boundary.
  allRings.sort((a, b) => b.length.compareTo(a.length));
  return allRings.isNotEmpty ? allRings.first : [];
}

// Helper to read a 32-bit unsigned integer.
int _readUint32(ByteData byteData, int offset, bool isLE) =>
    isLE ? byteData.getUint32(offset, Endian.little) : byteData.getUint32(offset, Endian.big);

// Helper to read a 64-bit float.
double _readFloat64(ByteData byteData, int offset, bool isLE) =>
    isLE ? byteData.getFloat64(offset, Endian.little) : byteData.getFloat64(offset, Endian.big);