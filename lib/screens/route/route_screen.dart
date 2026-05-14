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

  bool _loadingSafePlaces = false;
  bool _showSafePlaces = true;
  List<Map<String, dynamic>> _safePlaces = [];
  String? _safePlaceError;

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
      await _loadNearbySafePlaces(silent: true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _start = const LatLng(23.8103, 90.4125));
      await _loadNearbySafePlaces(silent: true);
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

  Future<void> _refreshCurrentLocation() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        if (!mounted) return;
        _showSnack('Location permission denied. Using last known map center.');
        return;
      }
      final pos = await Geolocator.getCurrentPosition().timeout(const Duration(seconds: 8));
      if (!mounted) return;
      setState(() => _start = LatLng(pos.latitude, pos.longitude));
      _mapCtrl.move(_start!, 15);
      await _loadNearbySafePlaces();
      if (_end != null) await _calculateRoute();
    } catch (_) {
      if (!mounted) return;
      _showSnack('Could not refresh location. Try again.');
    }
  }

  Future<void> _loadNearbySafePlaces({bool silent = false}) async {
    final base = _start;
    if (base == null) return;
    if (!silent) {
      setState(() {
        _loadingSafePlaces = true;
        _safePlaceError = null;
      });
    } else {
      setState(() => _loadingSafePlaces = true);
    }

    final places = await _api.getNearbySafePlaces(
      lat: base.latitude,
      lng: base.longitude,
      radiusMeters: _routePoints.isNotEmpty ? 3000 : 1800,
    );

    if (!mounted) return;
    setState(() {
      _safePlaces = places
          .whereType<Map>()
          .map((p) => Map<String, dynamic>.from(p))
          .where((p) => _placeLatLng(p) != null)
          .take(10)
          .toList();
      _loadingSafePlaces = false;
      _safePlaceError = _safePlaces.isEmpty ? 'No nearby safe places found yet.' : null;
      _showSafePlaces = true;
    });
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
      startLat: _start!.latitude,
      startLng: _start!.longitude,
      endLat: _end!.latitude,
      endLng: _end!.longitude,
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
        padding: const EdgeInsets.fromLTRB(60, 90, 60, 230),
      ));
    }

    await _loadNearbySafePlaces(silent: true);
  }

  Future<void> _routeToPlace(Map<String, dynamic> place) async {
    final target = _placeLatLng(place);
    if (target == null) return;
    setState(() {
      _end = target;
      _endLabel = _placeName(place);
      _searchCtrl.text = _endLabel;
      _suggestions = [];
    });
    if (mounted) Navigator.of(context).maybePop();
    await _calculateRoute();
  }

  List<LatLng> _extractRoutePoints(Map<String, dynamic> risk) {
    final raw = risk['route_coordinates'] ?? risk['polyline_coords'] ?? risk['coordinates'];

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

  String _riskLevel() {
    final value = _backendRisk?['risk_level'] ?? _backendRisk?['severity_level'];
    if (value == null) return _routePoints.isEmpty ? 'READY' : 'UNKNOWN';
    return value.toString().toUpperCase();
  }

  String _riskSource() {
    final source = _backendRisk?['source']?.toString();
    if (source != null && source.trim().isNotEmpty) return source;
    return _backendRisk == null ? 'Waiting for destination' : 'SafeHer Risk Engine';
  }

  int _cellsEvaluated() {
    final cells = _backendRisk?['cells_evaluated'];
    if (cells is num) return cells.round();
    final indices = _backendRisk?['h3_path_indices'];
    if (indices is List) return indices.length;
    return 0;
  }

  LatLng? _placeLatLng(Map<String, dynamic> p) {
    final lat = (p['latitude'] ?? p['lat']) as num?;
    final lng = (p['longitude'] ?? p['lng']) as num?;
    if (lat == null || lng == null) return null;
    return LatLng(lat.toDouble(), lng.toDouble());
  }

  String _placeName(Map<String, dynamic> p) {
    final name = p['name']?.toString().trim();
    if (name != null && name.isNotEmpty) return name;
    return p['type_label']?.toString() ?? p['type']?.toString() ?? 'Safe place';
  }

  String _placeLabel(Map<String, dynamic> p) =>
      p['type_label']?.toString() ?? p['type']?.toString() ?? 'Safe place';

  String _placeDistance(Map<String, dynamic> p) {
    final m = (p['distance_m'] as num?)?.round();
    if (m == null || m <= 0) return 'nearby';
    if (m >= 1000) return '~${(m / 1000).toStringAsFixed(1)} km';
    return '~$m m';
  }

  IconData _placeIcon(Map<String, dynamic> p) {
    switch (p['type']?.toString()) {
      case 'police':
      case 'security':
        return Icons.local_police;
      case 'medical':
        return Icons.local_hospital;
      case 'pharmacy':
        return Icons.local_pharmacy;
      case 'bank':
        return Icons.account_balance;
      case 'public':
        return Icons.people_alt;
      default:
        return Icons.verified_user;
    }
  }

  Color _placeColor(Map<String, dynamic> p) {
    switch (p['type']?.toString()) {
      case 'police':
      case 'security':
        return AppColors.green;
      case 'medical':
        return AppColors.red;
      case 'pharmacy':
        return AppColors.amber;
      case 'bank':
        return const Color(0xFF2563EB);
      default:
        return const Color(0xFF0F766E);
    }
  }

  void _showSnack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
  }

  void _showPlaceDetails(Map<String, dynamic> place) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final color = _placeColor(place);
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
                  child: Icon(_placeIcon(place), color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_placeName(place),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.ink)),
                    const SizedBox(height: 3),
                    Text('${_placeLabel(place)} • ${_placeDistance(place)}',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: color, fontSize: 12)),
                  ]),
                ),
              ]),
              const SizedBox(height: 16),
              Text(
                'Use this as a temporary safer stop if it is crowded, open, well-lit, and there are staff/security/other people nearby.',
                style: GoogleFonts.hindSiliguri(height: 1.45, color: AppColors.ink2, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _routeToPlace(place),
                    icon: const Icon(Icons.alt_route, size: 16),
                    label: Text('Route here', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.green,
                      side: const BorderSide(color: AppColors.green),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onNav('sos');
                    },
                    icon: const Icon(Icons.shield, size: 16),
                    label: Text('SOS', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ]),
            ],
          ),
        );
      },
    );
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
            left: 12,
            right: 12,
            top: 8,
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
                                  width: 14,
                                  height: 14,
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
              const SizedBox(height: 8),
              _buildQuickControls(),
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
          Positioned(
            right: 14,
            bottom: (_routePoints.isNotEmpty || _routing || _safePlaces.isNotEmpty) ? 255 : 22,
            child: Column(children: [
              _FloatingMapButton(
                icon: Icons.my_location,
                tooltip: 'Refresh location',
                onTap: _refreshCurrentLocation,
              ),
              const SizedBox(height: 10),
              _FloatingMapButton(
                icon: _showSafePlaces ? Icons.visibility : Icons.visibility_off,
                tooltip: 'Toggle safe places',
                onTap: () => setState(() => _showSafePlaces = !_showSafePlaces),
              ),
            ]),
          ),
          if (_routePoints.isNotEmpty || _routing || _safePlaces.isNotEmpty || _loadingSafePlaces)
            Positioned(left: 12, right: 12, bottom: 16, child: _buildRoutePanel()),
        ]),
      ),
    );
  }

  Widget _buildQuickControls() {
    return Row(children: [
      _ModeChip(icon: Icons.directions_walk, text: 'Walking', selected: true, onTap: () {}),
      const SizedBox(width: 8),
      _ModeChip(
        icon: Icons.verified_user_outlined,
        text: _loadingSafePlaces ? 'Finding safe places…' : 'Safe places',
        selected: _showSafePlaces,
        onTap: _loadingSafePlaces ? null : _loadNearbySafePlaces,
      ),
      const SizedBox(width: 8),
      _ModeChip(
        icon: Icons.refresh,
        text: 'Recalculate',
        selected: false,
        onTap: (_end == null || _routing) ? null : _calculateRoute,
      ),
    ]);
  }

  List<Marker> _buildMarkers() {
    final list = <Marker>[];
    if (_showSafePlaces) {
      for (final place in _safePlaces) {
        final point = _placeLatLng(place);
        if (point == null) continue;
        final color = _placeColor(place);
        list.add(Marker(
          point: point,
          width: 34,
          height: 34,
          child: GestureDetector(
            onTap: () => _showPlaceDetails(place),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
              ),
              child: Icon(_placeIcon(place), color: color, size: 17),
            ),
          ),
        ));
      }
    }
    if (_start != null) {
      list.add(Marker(
        point: _start!,
        width: 38,
        height: 38,
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.green,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: const Icon(Icons.my_location, color: Colors.white, size: 18),
        ),
      ));
    }
    if (_end != null) {
      list.add(Marker(
        point: _end!,
        width: 40,
        height: 40,
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
    final score = _safetyScore(fallback: _routePoints.isEmpty ? 0 : 70);
    final level = _riskLevel();
    final color = _routeColor();

    return Container(
      constraints: const BoxConstraints(maxHeight: 330),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12)],
      ),
      child: _routing
          ? const Row(children: [
              SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.green)),
              SizedBox(width: 12),
              Text('Calculating safest route…'),
            ])
          : SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (_routePoints.isNotEmpty) ...[
                  Row(children: [
                    Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
                      child: Text(
                        score > 0 ? '$score' : '—',
                        style: GoogleFonts.inter(color: color, fontWeight: FontWeight.w900, fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Safety Score', style: GoogleFonts.inter(color: AppColors.ink3, fontSize: 11)),
                        const SizedBox(height: 2),
                        Text(
                          _endLabel.isEmpty ? 'Destination' : _endLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(color: AppColors.ink, fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_riskSource()}${_cellsEvaluated() > 0 ? ' • ${_cellsEvaluated()} cells checked' : ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(color: AppColors.ink3, fontSize: 10.5),
                        ),
                      ]),
                    ),
                    _RiskBadge(level: level, color: color),
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
                      onPressed: () => widget.onNav('sos'),
                      icon: const Icon(Icons.shield, size: 16),
                      label: Text('SOS', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 12)),
                    ),
                  ]),
                  const SizedBox(height: 12),
                ],
                _buildSafePlacesPreview(),
              ]),
            ),
    );
  }

  Widget _buildSafePlacesPreview() {
    if (_loadingSafePlaces) {
      return Row(children: [
        const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.green)),
        const SizedBox(width: 10),
        Text('Finding nearby safe places…', style: GoogleFonts.inter(color: AppColors.ink2, fontSize: 12)),
      ]);
    }

    if (_safePlaces.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(12)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.ink2),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _safePlaceError ?? 'Search a destination or tap Safe places to find nearby police, hospital, pharmacy or public safe stops.',
              style: GoogleFonts.hindSiliguri(color: AppColors.ink2, fontSize: 12.5, height: 1.35),
            ),
          ),
        ]),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.verified_user_outlined, color: AppColors.green, size: 16),
        const SizedBox(width: 6),
        Text('Nearby safe stops', style: GoogleFonts.inter(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 12.5)),
        const Spacer(),
        TextButton(
          onPressed: _loadingSafePlaces ? null : _loadNearbySafePlaces,
          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(52, 28)),
          child: Text('Refresh', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 11)),
        ),
      ]),
      const SizedBox(height: 6),
      ..._safePlaces.take(3).map((p) => _SafePlaceRow(
            name: _placeName(p),
            label: _placeLabel(p),
            distance: _placeDistance(p),
            icon: _placeIcon(p),
            color: _placeColor(p),
            onTap: () => _showPlaceDetails(p),
          )),
      const SizedBox(height: 6),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(color: AppColors.green.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(12)),
        child: Text(
          'Tip: In danger, choose a crowded and well-lit place first, share location with contacts, or press SOS.',
          style: GoogleFonts.hindSiliguri(color: AppColors.green, fontWeight: FontWeight.w700, fontSize: 11.5, height: 1.35),
        ),
      ),
    ]);
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
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
          ),
          child: Icon(icon, color: AppColors.ink, size: 20),
        ),
      );
}

class _FloatingMapButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _FloatingMapButton({required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
            ),
            child: Icon(icon, color: AppColors.green, size: 20),
          ),
        ),
      );
}

class _ModeChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool selected;
  final VoidCallback? onTap;
  const _ModeChip({required this.icon, required this.text, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.green : AppColors.ink2;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.green.withValues(alpha: 0.10) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? AppColors.green.withValues(alpha: 0.35) : AppColors.border),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(color: color, fontWeight: FontWeight.w800, fontSize: 11),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _RiskBadge extends StatelessWidget {
  final String level;
  final Color color;
  const _RiskBadge({required this.level, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
        child: Text(
          level,
          style: GoogleFonts.inter(color: color, fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 0.4),
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
        Text(label, style: GoogleFonts.hindSiliguri(color: AppColors.ink2, fontWeight: FontWeight.w700, fontSize: 12)),
      ]);
}

class _SafePlaceRow extends StatelessWidget {
  final String name;
  final String label;
  final String distance;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _SafePlaceRow({
    required this.name,
    required this.label,
    required this.distance,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 15),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(color: AppColors.ink, fontWeight: FontWeight.w800, fontSize: 12.2)),
                const SizedBox(height: 1),
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(color: AppColors.ink3, fontWeight: FontWeight.w600, fontSize: 10.8)),
              ]),
            ),
            const SizedBox(width: 8),
            Text(distance, style: GoogleFonts.inter(color: color, fontWeight: FontWeight.w900, fontSize: 11)),
          ]),
        ),
      );
}
