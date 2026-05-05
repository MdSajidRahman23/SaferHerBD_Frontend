// ════════════════════════════════════════════════════════════════
//  OpenRouteService — Real Road Routing
//  Free tier: 2000 requests/day
//  Gives actual road-following coordinates (not straight lines)
// ════════════════════════════════════════════════════════════════
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class OrsService {
  // ORS API key from your backend .env
  static const _apiKey =
      'eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6IjE2NTU1YzExNWIwNjRiOGQ4N2IwMjQzMGEzYmY1ODFiIiwiaCI6Im11cm11cjY0In0=';

  static const _baseUrl = 'https://api.openrouteservice.org/v2';

  /// Get real road-following route between two points
  /// Returns list of LatLng coordinates along actual roads
  static Future<OrsRouteResult?> getRoute({
    required LatLng start,
    required LatLng end,
    String profile = 'foot-walking', // foot-walking | driving-car | cycling-regular
  }) async {
    try {
      final url = '$_baseUrl/directions/$profile';
      final res = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': _apiKey,
          'Content-Type': 'application/json',
          'Accept': 'application/json, application/geo+json',
        },
        body: jsonEncode({
          'coordinates': [
            [start.longitude, start.latitude],
            [end.longitude, end.latitude],
          ],
          'instructions': false,
          'geometry': true,
        }),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final route = data['routes'][0];

        // Decode polyline geometry
        final geometry = route['geometry'] as String;
        final points = _decodePolyline(geometry);

        final summary = route['summary'];
        final distanceM  = (summary['distance'] as num).toDouble();
        final durationS  = (summary['duration'] as num).toDouble();

        return OrsRouteResult(
          points: points,
          distanceKm: distanceM / 1000,
          durationMin: durationS / 60,
        );
      }
    } catch (e) {
      // Silently fail — caller shows fallback straight line
    }
    return null;
  }

  /// Decode ORS polyline encoding to LatLng list
  static List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    int index = 0;
    int lat = 0, lng = 0;

    while (index < encoded.length) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dLat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dLat;

      shift = 0; result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dLng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dLng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }
}

class OrsRouteResult {
  final List<LatLng> points;
  final double distanceKm;
  final double durationMin;

  OrsRouteResult({
    required this.points,
    required this.distanceKm,
    required this.durationMin,
  });

  String get distanceBn {
    if (distanceKm < 1) return '${(distanceKm * 1000).round()} মিটার';
    return '${distanceKm.toStringAsFixed(1)} কিমি';
  }

  String get durationBn {
    if (durationMin < 60) return '${durationMin.round()} মিনিট';
    final h = (durationMin / 60).floor();
    final m = (durationMin % 60).round();
    return '$h ঘণ্টা $m মিনিট';
  }
}
