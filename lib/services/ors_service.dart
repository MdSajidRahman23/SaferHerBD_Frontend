// ═══════════════════════════════════════════════════════════════
//  OpenRouteService — Real Road Routing
// ═══════════════════════════════════════════════════════════════
//
// 🔐 SECURITY: API key is NEVER hardcoded. Pass it at build time:
//
//   flutter run --dart-define=ORS_API_KEY=eyJxxx...
//   flutter build apk --dart-define=ORS_API_KEY=eyJxxx...
//
// If the key is empty, the service will return null and the caller
// will fall back to either the backend's safest-route endpoint or
// a straight-line preview.
//
// Free tier: 2000 requests/day
// Docs:      https://openrouteservice.org/dev/

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../utils/constants.dart';

class OrsService {
  static const String _baseUrl = 'https://api.openrouteservice.org/v2';

  static bool get isConfigured => ServiceConfig.orsApiKey.isNotEmpty;

  /// Get real road-following route between two points.
  /// Returns null if API key not configured or request fails.
  static Future<OrsRouteResult?> getRoute({
    required LatLng start,
    required LatLng end,
    String profile = 'foot-walking', // foot-walking | driving-car | cycling-regular
  }) async {
    if (!isConfigured) {
      // No key — caller will use backend or straight-line fallback
      return null;
    }

    try {
      final url = '$_baseUrl/directions/$profile';
      final res = await http
          .post(
            Uri.parse(url),
            headers: {
              'Authorization': ServiceConfig.orsApiKey,
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
          )
          .timeout(const Duration(seconds: 12));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final route = data['routes'][0];
        final geometry = route['geometry'] as String;
        final points = _decodePolyline(geometry);

        final summary = route['summary'];
        final distanceM = (summary['distance'] as num).toDouble();
        final durationS = (summary['duration'] as num).toDouble();

        return OrsRouteResult(
          points: points,
          distanceKm: distanceM / 1000,
          durationMin: durationS / 60,
        );
      }
    } catch (_) {
      // Silent fail — caller handles fallback
    }
    return null;
  }

  /// Decode ORS-encoded polyline to LatLng list.
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

      shift = 0;
      result = 0;
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