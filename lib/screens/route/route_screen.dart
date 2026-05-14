import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../services/api_service.dart';
import '../../services/ors_service.dart';
import '../../utils/constants.dart';

class RouteScreen extends StatefulWidget {
  final void Function(String) onNav;
  final VoidCallback onBack;
  const RouteScreen({super.key, required this.onNav, required this.onBack});

  @override
  State<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  final _api = ApiService();
  final _mapCtrl = MapController();
  final _searchCtrl = TextEditingController();
  Timer? _searchDebounce;

  LatLng? _start;
  LatLng? _end;
  String _endLabel = '';

  List<dynamic> _suggestions = [];
  bool _searching = false;

  bool _routing = false;
  List<LatLng> _routePoints = [];
  String _distanceText = '';
  String _durationText = '';
  Map<String, dynamic>? _backendRisk;

  @override
  void initState() {
    super.initState();
    _initStart();
  }

  Future<void> _initStart() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition().timeout(const Duration(seconds: 6));
      if (!mounted) return;
      setState(() => _start = LatLng(pos.latitude, pos.longitude));
      _mapCtrl.move(_start!, 14);
    } catch (_) {
      if (!mounted) return;
      setState(() => _start = const LatLng(23.8103, 90.4125)); // Dhaka
    }
  }

  void _onSearchChanged(String q) {
    _searchDebounce?.cancel();
    if (q.trim().length < 3) {
      setState(() => _suggestions = []);
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() => _searching = true);
      final list = await _api.geocode(q.trim());
      if (!mounted) return;
      setState(() {
        _suggestions = list;
        _searching = false;
      });
    });
  }

  Future<void> _selectSuggestion(Map<String, dynamic> s) async {
    final lat = (s['latitude'] as num?)?.toDouble();
    final lng = (s['longitude'] as num?)?.toDouble();
    if (lat == null || lng == null) return;
    setState(() {
      _end = LatLng(lat, lng);
      _endLabel = (s['display_name'] ?? '').toString();
      _suggestions = [];
      _searchCtrl.text = _endLabel;
    });
    FocusScope.of(context).unfocus();
    await _calculateRoute();
  }

  Future<void> _calculateRoute() async {
    if (_start == null || _end == null) return;
    setState(() {
      _routing = true;
      _routePoints = [];
      _distanceText = '';
      _durationText = '';
      _backendRisk = null;
    });

    OrsRouteResult? ors;
    if (OrsService.isConfigured) {
      ors = await OrsService.getRoute(start: _start!, end: _end!);
    }

    List<LatLng> points;
    if (ors != null) {
      points = ors.points;
      _distanceText = ors.distanceBn;
      _durationText = ors.durationBn;
    } else {
      points = [_start!, _end!];
      final distance = const Distance().as(LengthUnit.Kilometer, _start!, _end!);
      _distanceText = '${distance.toStringAsFixed(1)} কিমি';
      _durationText = '~${(distance / 4.5 * 60).round()} মিনিট';
    }

    final risk = await _api.getSafestRoute(
      startLat: _start!.latitude, startLng: _start!.longitude,
      endLat: _end!.latitude, endLng: _end!.longitude,
      travelMode: 'foot-walking',
    );

    if (risk != null) {
      final bp = _extractRoutePoints(risk);
      if (bp.isNotEmpty) points = bp;

      final distanceKm = (risk['distance_km'] as num?)?.toDouble();
      final durationMin = (risk['duration_min'] ?? risk['estimated_time_min']) as num?;
      if (distanceKm != null && distanceKm > 0) {
        _distanceText = '${distanceKm.toStringAsFixed(1)} কিমি';
      }
      if (durationMin != null && durationMin > 0) {
        _durationText = '~${durationMin.round()} মিনিট';
      }
    }

    if (!mounted) return;
    setState(() {
      _routePoints = points;
      _backendRisk = risk;
      _routing = false;
    });

    if (points.length >= 2) {
      _mapCtrl.fitCamera(CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        padding: const EdgeInsets.all(60),
      ));
    }
  }


  List<LatLng> _extractRoutePoints(Map<String, dynamic> risk) {
    final raw = risk['route_coordinates'] ??
        risk['polyline_coords'] ??
        risk['coordinates'];

    if (raw is List) {
      final pts = <LatLng>[];
      for (final p in raw) {
        if (p is List && p.length >= 2 && p[0] is num && p[1] is num) {
          // Backend/ORS/FastAPI use [longitude, latitude]
          pts.add(LatLng((p[1] as num).toDouble(), (p[0] as num).toDouble()));
        } else if (p is Map) {
          final lat = (p['latitude'] ?? p['lat']) as num?;
          final lng = (p['longitude'] ?? p['lng']) as num?;
          if (lat != null && lng != null) pts.add(LatLng(lat.toDouble(), lng.toDouble()));
        }
      }
      return pts;
    }

    final waypoints = risk['waypoints'];
    if (waypoints is List) {
      final pts = <LatLng>[];
      for (final p in waypoints) {
        if (p is Map) {
          final lat = (p['latitude'] ?? p['lat']) as num?;
          final lng = (p['longitude'] ?? p['lng']) as num?;
          if (lat != null && lng != null) pts.add(LatLng(lat.toDouble(), lng.toDouble()));
        }
      }
      return pts;
    }

    return [];
  }

  int _safetyScore({int fallback = 70}) {
    final value = _backendRisk?['safety_score'];
    if (value is num) return value.round().clamp(0, 100).toInt();
    return fallback;
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final center = _start ?? const LatLng(23.8103, 90.4125);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Stack(children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapCtrl,
              options: MapOptions(
                initialCenter: center,
                initialZoom: 14,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.safeher.bangladesh',
                ),
                if (_routePoints.isNotEmpty)
                  PolylineLayer(polylines: [
                    Polyline(points: _routePoints, strokeWidth: 5, color: _routeColor()),
                  ]),
                MarkerLayer(markers: _buildMarkers()),
              ],
            ),
          ),
          Positioned(
            left: 12, right: 12, top: 8,
            child: Column(children: [
              Row(children: [
                _RoundIcon(icon: Icons.arrow_back, onTap: widget.onBack),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Where do you want to go?',
                        hintStyle: GoogleFonts.inter(color: AppColors.ink3, fontSize: 13),
                        prefixIcon: _searching
                            ? const Padding(
                                padding: EdgeInsets.all(14),
                                child: SizedBox(
                                  width: 14, height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.green),
                                ),
                              )
                            : const Icon(Icons.search, color: AppColors.ink2, size: 20),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() {
                                    _suggestions = [];
                                    _end = null;
                                    _routePoints = [];
                                    _backendRisk = null;
                                  });
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
              ]),
              if (_suggestions.isNotEmpty) ...[
                const SizedBox(height: 4),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
                  ),
                  child: Column(
                    children: _suggestions.take(5).map((s) {
                      final m = s as Map<String, dynamic>;
                      return InkWell(
                        onTap: () => _selectSuggestion(m),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Row(children: [
                            const Icon(Icons.location_on_outlined, size: 16, color: AppColors.green),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                m['display_name']?.toString() ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(color: AppColors.ink, fontSize: 12.5),
                              ),
                            ),
                          ]),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ]),
          ),
          if (_routePoints.isNotEmpty || _routing)
            Positioned(left: 12, right: 12, bottom: 16, child: _buildRoutePanel()),
        ]),
      ),
    );
  }

  List<Marker> _buildMarkers() {
    final list = <Marker>[];
    if (_start != null) {
      list.add(Marker(
        point: _start!,
        width: 36, height: 36,
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.green, shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: const Icon(Icons.my_location, color: Colors.white, size: 18),
        ),
      ));
    }
    if (_end != null) {
      list.add(Marker(
        point: _end!,
        width: 40, height: 40,
        child: const Icon(Icons.location_pin, color: AppColors.red, size: 38),
      ));
    }
    return list;
  }

  Color _routeColor() {
    final score = _safetyScore();
    if (score >= 75) return AppColors.green;
    if (score >= 50) return AppColors.amber;
    return AppColors.red;
  }

  Widget _buildRoutePanel() {
    final score = _safetyScore(fallback: 0);
    final level = _backendRisk?['risk_level']?.toString() ?? '...';
    final color = _routeColor();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12)],
      ),
      child: _routing
          ? const Row(children: [
              SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.green)),
              SizedBox(width: 12),
              Text('Calculating safest route…'),
            ])
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 50, height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
                  child: Text(
                    score > 0 ? '$score' : '—',
                    style: GoogleFonts.inter(color: color, fontWeight: FontWeight.w900, fontSize: 17),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Safety Score', style: GoogleFonts.inter(color: AppColors.ink3, fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(_endLabel.isEmpty ? 'Destination' : _endLabel,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(color: AppColors.ink, fontWeight: FontWeight.w700, fontSize: 13)),
                  ]),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                  child: Text(level.toUpperCase(),
                      style: GoogleFonts.inter(color: color, fontWeight: FontWeight.w700, fontSize: 10, letterSpacing: 0.4)),
                ),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                _Stat(icon: Icons.straighten, label: _distanceText.isEmpty ? '—' : _distanceText),
                const SizedBox(width: 10),
                _Stat(icon: Icons.access_time, label: _durationText.isEmpty ? '—' : _durationText),
                const Spacer(),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.pushNamed(context, '/sos'),
                  icon: const Icon(Icons.shield, size: 16),
                  label: Text('SOS', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ]),
            ]),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIcon({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40, height: 40,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
          ),
          child: Icon(icon, color: AppColors.ink, size: 20),
        ),
      );
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Stat({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, color: AppColors.ink2, size: 14),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.hindSiliguri(color: AppColors.ink2, fontWeight: FontWeight.w600, fontSize: 12)),
      ]);
}
