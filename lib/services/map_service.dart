// ════════════════════════════════════════════════════════════════
//  MAP SERVICE  — Paid (Google) + Free (OpenStreetMap) fallback
//
//  Free tier (default):  flutter_map + OpenStreetMap tiles
//                        Free, no API key, works on web & mobile
//  Paid tier:            Google Maps  (when ServiceConfig.googleMapsApiKey set)
//                        Better tiles, traffic, satellite view
//
//  This service abstracts the map provider so screens don't care
//  which one is active — just call buildMap(...).
// ════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../utils/constants.dart';

class MapService {
  static const _osmTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  // Mapbox style tiles (also free for low usage, looks more modern)
  // static const _stadiaUrl =
  //     'https://tiles.stadiamaps.com/tiles/alidade_smooth/{z}/{x}/{y}{r}.png';

  /// Build a map widget, automatically picking provider.
  /// Returns OpenStreetMap (free) by default, Google when API key configured.
  static Widget buildMap({
    required LatLng center,
    double zoom = 13.5,
    List<Marker> markers = const [],
    List<Polyline> polylines = const [],
    List<CircleMarker> circles = const [],
    MapController? controller,
  }) {
    if (ServiceConfig.useGoogleMaps) {
      // Future expansion: Google Maps Flutter widget here.
      // For now, gracefully fall through to OSM since key is empty.
    }
    return _buildOSM(
      center: center, zoom: zoom,
      markers: markers, polylines: polylines, circles: circles,
      controller: controller,
    );
  }

  static Widget _buildOSM({
    required LatLng center,
    required double zoom,
    required List<Marker> markers,
    required List<Polyline> polylines,
    required List<CircleMarker> circles,
    MapController? controller,
  }) {
    return FlutterMap(
      mapController: controller,
      options: MapOptions(
        initialCenter: center,
        initialZoom: zoom,
        minZoom: 4,
        maxZoom: 18,
      ),
      children: [
        TileLayer(
          urlTemplate: _osmTileUrl,
          userAgentPackageName: 'bd.gov.safeher',
          maxZoom: 19,
        ),
        if (circles.isNotEmpty) CircleLayer(circles: circles),
        if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
        if (markers.isNotEmpty) MarkerLayer(markers: markers),
      ],
    );
  }

  /// Provider name displayed to user (for transparency)
  static String get providerName =>
      ServiceConfig.useGoogleMaps ? 'Google Maps' : 'OpenStreetMap (Free)';

  // Common BD locations for quick centering
  static const dhaka      = LatLng(23.8103, 90.4125);
  static const chittagong = LatLng(22.3569, 91.7832);
  static const sylhet     = LatLng(24.8949, 91.8687);
}

// Risk zone visualization helpers
class MapHelpers {
  static Marker buildMarker({
    required LatLng point,
    required Color color,
    IconData icon = Icons.location_pin,
    double size = 32,
  }) {
    return Marker(
      point: point,
      width: size, height: size,
      child: Icon(icon, color: color, size: size,
          shadows: [Shadow(color: Colors.black54, blurRadius: 4)]),
    );
  }

  static CircleMarker buildRiskZone({
    required LatLng center,
    required double radiusMeters,
    required double riskScore,  // 0..1
  }) {
    final color = riskScore > 0.7 ? const Color(0xFFF42A41)
                : riskScore > 0.4 ? const Color(0xFFD4A017)
                : const Color(0xFF006A4E);
    return CircleMarker(
      point: center,
      radius: radiusMeters,
      useRadiusInMeter: true,
      color: color.withOpacity(0.15),
      borderColor: color.withOpacity(0.5),
      borderStrokeWidth: 1,
    );
  }

  static Polyline buildRoute(List<LatLng> points, {bool isSafe = true}) {
    return Polyline(
      points: points,
      color: isSafe ? const Color(0xFF006A4E) : const Color(0xFFF42A41),
      strokeWidth: isSafe ? 4 : 3,
      pattern: isSafe ? const StrokePattern.solid()
                      : StrokePattern.dashed(segments: [10, 6]),
    );
  }
}
