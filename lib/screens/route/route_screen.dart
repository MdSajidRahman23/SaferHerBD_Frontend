import 'dart:async';
import 'dart:math' as math;

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
  List<Map<String, dynamic>> _routeOptions = [];
  int _selectedRouteIndex = 0;

  bool _loadingSafePlaces = false;
  bool _showSafePlaces = true;
  bool _showCoverageLayer = true;
  List<Map<String, dynamic>> _safePlaces = [];
  String? _safePlaceError;

  _TransportMode _selectedMode = _TransportModes.walk;
  _RoutePreference _selectedPreference = _RoutePreferences.mainRoads;

  Map<String, dynamic>? _activeJourney;
  bool _journeyBusy = false;

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
      await _loadActiveJourney(silent: true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _start = const LatLng(23.8103, 90.4125));
      await _loadNearbySafePlaces(silent: true);
      await _loadActiveJourney(silent: true);
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


  Future<void> _selectTransportMode(_TransportMode mode) async {
    if (_selectedMode.id == mode.id) return;
    setState(() {
      _selectedMode = mode;
      _backendRisk = null;
      _routePoints = [];
      _distanceText = '';
      _durationText = '';
    });

    if (_end != null) {
      await _calculateRoute();
    }
  }

  Future<void> _selectRoutePreference(_RoutePreference preference) async {
    if (_selectedPreference.id == preference.id) return;
    setState(() {
      _selectedPreference = preference;
      _backendRisk = null;
      _routePoints = [];
      _distanceText = '';
      _durationText = '';
    });

    if (_end != null) {
      await _calculateRoute();
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
      _routeOptions = [];
      _selectedRouteIndex = 0;
      _distanceText = '';
      _durationText = '';
      _backendRisk = null;
    });

    OrsRouteResult? ors;
    if (OrsService.isConfigured) {
      ors = await OrsService.getRoute(
        start: _start!,
        end: _end!,
        profile: _selectedMode.routeProfile,
        vehicleType: _selectedMode.vehicleType,
        routePreference: _selectedPreference.id,
      );
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
      final speedKmh = _selectedMode.fallbackSpeedKmh;
      _durationText = '~${(distance / speedKmh * 60).round()} মিনিট';
    }

    final risk = await _api.getSafestRoute(
      startLat: _start!.latitude,
      startLng: _start!.longitude,
      endLat: _end!.latitude,
      endLng: _end!.longitude,
      travelMode: _selectedMode.backendMode,
      routeProfile: _selectedMode.routeProfile,
      vehicleType: _selectedMode.vehicleType,
      modeLabel: _selectedMode.label,
      routePreference: _selectedPreference.id,
      safeStopCount: _safePlaces.length,
    );

    var routeOptions = <Map<String, dynamic>>[];
    var selectedRouteIndex = 0;

    if (risk != null) {
      routeOptions = _normalizeRouteOptions(risk);
      if (routeOptions.isNotEmpty) {
        selectedRouteIndex = _initialSelectedRouteIndex(routeOptions);
        final selected = routeOptions[selectedRouteIndex];
        final optionPoints = _pointsFromRouteOption(selected);
        if (optionPoints.isNotEmpty) points = optionPoints;
        _distanceText = _formatDistanceFromData(selected, fallback: _distanceText);
        _durationText = _formatDurationFromData(selected, fallback: _durationText);
      } else {
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
    }

    if (!mounted) return;
    setState(() {
      _routePoints = points;
      _routeOptions = routeOptions;
      _selectedRouteIndex = selectedRouteIndex;
      _backendRisk = risk;
      _routing = false;
    });

    if (points.length >= 2) {
      _mapCtrl.fitCamera(CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(_allVisibleRoutePoints(points)),
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
    final pts = _pointsFromRaw(raw);
    if (pts.isNotEmpty) return pts;

    final waypoints = risk['waypoints'];
    final wp = _pointsFromRaw(waypoints);
    if (wp.isNotEmpty) return wp;

    return [];
  }

  List<LatLng> _pointsFromRaw(dynamic raw) {
    if (raw is! List) return [];
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

  List<Map<String, dynamic>> _normalizeRouteOptions(Map<String, dynamic> risk) {
    final raw = risk['route_options'] ?? risk['interactive_route_options'];
    if (raw is! List) return [];
    final options = <Map<String, dynamic>>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final data = Map<String, dynamic>.from(item);
      if (_pointsFromRouteOption(data).length < 2) continue;
      options.add(data);
    }
    return options.take(4).toList();
  }

  List<LatLng> _pointsFromRouteOption(Map<String, dynamic> option) {
    return _pointsFromRaw(option['route_coordinates'] ?? option['coordinates'] ?? option['polyline_coords'] ?? option['waypoints']);
  }

  int _initialSelectedRouteIndex(List<Map<String, dynamic>> options) {
    final explicit = options.indexWhere((o) => o['selected'] == true || o['recommended'] == true);
    if (explicit >= 0) return explicit;
    // Main-road-first default: high-support roads are preferred unless a safer route clearly wins.
    var bestIndex = 0;
    var bestScore = -9999.0;
    for (var i = 0; i < options.length; i++) {
      final o = options[i];
      final safety = ((o['safety_score'] ?? o['score'] ?? 0) as num?)?.toDouble() ?? 0;
      final main = ((o['main_road_score'] ?? 0) as num?)?.toDouble() ?? 0;
      final stops = ((o['safe_stop_score'] ?? 0) as num?)?.toDouble() ?? 0;
      final duration = ((o['duration_min'] ?? o['estimated_time_min'] ?? 999) as num?)?.toDouble() ?? 999;
      final rank = (main * 0.44) + (safety * 0.38) + (stops * 0.12) - (duration * 0.05);
      if (rank > bestScore) {
        bestScore = rank;
        bestIndex = i;
      }
    }
    return bestIndex;
  }

  Map<String, dynamic>? _selectedRouteOption() {
    if (_routeOptions.isEmpty) return null;
    final i = _selectedRouteIndex.clamp(0, _routeOptions.length - 1).toInt();
    return _routeOptions[i];
  }

  Map<String, dynamic>? _routeData() => _selectedRouteOption() ?? _backendRisk;

  List<LatLng> _allVisibleRoutePoints(List<LatLng> fallback) {
    final all = <LatLng>[];
    for (final option in _routeOptions) {
      all.addAll(_pointsFromRouteOption(option));
    }
    if (all.length >= 2) return all;
    return fallback;
  }

  String _formatDistanceFromData(Map<String, dynamic> data, {required String fallback}) {
    final km = (data['distance_km'] as num?)?.toDouble();
    if (km != null && km > 0) return km < 1 ? '${(km * 1000).round()} মিটার' : '${km.toStringAsFixed(1)} কিমি';
    final meters = (data['distance_meters'] as num?)?.toDouble();
    if (meters != null && meters > 0) {
      final k = meters / 1000;
      return k < 1 ? '${meters.round()} মিটার' : '${k.toStringAsFixed(1)} কিমি';
    }
    return fallback;
  }

  String _formatDurationFromData(Map<String, dynamic> data, {required String fallback}) {
    final min = ((data['traffic_adjusted_duration_min'] ??
            data['duration_min'] ??
            data['estimated_time_min']) as num?)
        ?.toDouble();
    if (min != null && min > 0) {
      if (min < 60) return '~${min.round()} মিনিট';
      final h = (min / 60).floor();
      final m = (min % 60).round();
      return '~$h ঘণ্টা $m মিনিট';
    }
    final sec = ((data['traffic_adjusted_duration_seconds'] ?? data['duration_seconds']) as num?)?.toDouble();
    if (sec != null && sec > 0) return _formatDurationFromData({'duration_min': sec / 60}, fallback: fallback);
    return fallback;
  }

  void _selectRouteOption(int index, {bool fromMap = false}) {
    if (index < 0 || index >= _routeOptions.length) return;
    final selected = _routeOptions[index];
    final points = _pointsFromRouteOption(selected);
    if (points.length < 2) return;
    setState(() {
      _selectedRouteIndex = index;
      _routePoints = points;
      _distanceText = _formatDistanceFromData(selected, fallback: _distanceText);
      _durationText = _formatDurationFromData(selected, fallback: _durationText);
    });
    if (fromMap) {
      _showSnack('Selected ${selected['label'] ?? 'route option'}');
    }
  }

  void _handleMapTap(LatLng point) {
    if (_routeOptions.length < 2) return;
    var bestIndex = -1;
    var bestDistance = double.infinity;
    for (var i = 0; i < _routeOptions.length; i++) {
      final points = _pointsFromRouteOption(_routeOptions[i]);
      if (points.length < 2) continue;
      final d = _minDistanceToPolylineMeters(point, points);
      if (d < bestDistance) {
        bestDistance = d;
        bestIndex = i;
      }
    }
    // A generous hit area makes line selection usable on touch screens.
    if (bestIndex >= 0 && bestDistance <= 85) {
      _selectRouteOption(bestIndex, fromMap: true);
    }
  }

  double _minDistanceToPolylineMeters(LatLng p, List<LatLng> line) {
    var best = double.infinity;
    for (var i = 0; i < line.length - 1; i++) {
      final d = _distancePointToSegmentMeters(p, line[i], line[i + 1]);
      if (d < best) best = d;
    }
    return best;
  }

  double _distancePointToSegmentMeters(LatLng p, LatLng a, LatLng b) {
    const metersPerDegreeLat = 111320.0;
    final cosLat = math.cos(p.latitude * 0.017453292519943295).abs();
    final metersPerDegreeLng = metersPerDegreeLat * cosLat;

    final px = p.longitude * metersPerDegreeLng;
    final py = p.latitude * metersPerDegreeLat;
    final ax = a.longitude * metersPerDegreeLng;
    final ay = a.latitude * metersPerDegreeLat;
    final bx = b.longitude * metersPerDegreeLng;
    final by = b.latitude * metersPerDegreeLat;

    final dx = bx - ax;
    final dy = by - ay;
    if (dx.abs() < 0.0001 && dy.abs() < 0.0001) {
      final x = px - ax;
      final y = py - ay;
      return math.sqrt((x * x + y * y).abs());
    }
    final t = (((px - ax) * dx) + ((py - ay) * dy)) / ((dx * dx) + (dy * dy));
    final clamped = t.clamp(0.0, 1.0).toDouble();
    final projX = ax + clamped * dx;
    final projY = ay + clamped * dy;
    final x = px - projX;
    final y = py - projY;
    return math.sqrt((x * x + y * y).abs());
  }

  int _safetyScore({int fallback = 70}) {
    final value = _routeData()?['safety_score'] ?? _routeData()?['score'];
    if (value is num) return value.round().clamp(0, 100).toInt();
    return fallback;
  }

  String _riskLevel() {
    final value = _routeData()?['risk_level'] ?? _routeData()?['severity_level'];
    if (value == null) return _routePoints.isEmpty ? 'READY' : 'UNKNOWN';
    return value.toString().toUpperCase();
  }

  String _riskSource() {
    final source = _routeData()?['source']?.toString() ?? _backendRisk?['source']?.toString();
    if (source != null && source.trim().isNotEmpty) return source;
    return _backendRisk == null ? 'Waiting for destination' : 'SafeHer Risk Engine';
  }

  int _cellsEvaluated() {
    final cells = _routeData()?['cells_evaluated'] ?? _backendRisk?['cells_evaluated'];
    if (cells is num) return cells.round();
    final indices = _routeData()?['h3_path_indices'] ?? _backendRisk?['h3_path_indices'];
    if (indices is List) return indices.length;
    return 0;
  }


  Map<String, dynamic> _coverageData() {
    final raw = _routeData()?['risk_data_coverage'] ?? _backendRisk?['risk_data_coverage'];
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {
      'label': _routeData()?['coverage_label'] ?? _backendRisk?['coverage_label'] ?? 'Estimated',
      'note': _routeData()?['coverage_note'] ?? _backendRisk?['coverage_note'] ?? '',
      'coverage_percent': _routeData()?['coverage_percent'] ?? _backendRisk?['coverage_percent'] ?? 0,
      'confidence': _routeData()?['coverage_confidence'] ?? _backendRisk?['coverage_confidence'] ?? 'estimated',
      'zones': _routeData()?['coverage_zones'] ?? _backendRisk?['coverage_zones'] ?? [],
    };
  }

  String _coverageText() {
    final data = _coverageData();
    final label = (data['label'] ?? _routeData()?['coverage_label'] ?? _backendRisk?['coverage_label'] ?? 'Estimated').toString();
    final percent = _coveragePercent();
    if (_routePoints.isEmpty && _backendRisk == null) return 'Coverage: waiting';
    return percent > 0 ? 'Coverage: $label • $percent%' : 'Coverage: $label';
  }

  int _coveragePercent() {
    final value = _coverageData()['coverage_percent'] ?? _routeData()?['coverage_percent'] ?? _backendRisk?['coverage_percent'];
    if (value is num) return value.round().clamp(0, 100).toInt();
    return int.tryParse(value?.toString() ?? '')?.clamp(0, 100).toInt() ?? 0;
  }

  String _coverageConfidence() {
    return (_coverageData()['confidence'] ?? _routeData()?['coverage_confidence'] ?? _backendRisk?['coverage_confidence'] ?? 'estimated').toString();
  }

  String _coverageNote() {
    return (_coverageData()['note'] ?? _routeData()?['coverage_note'] ?? _backendRisk?['coverage_note'] ?? '').toString();
  }

  Color _coverageColor() {
    final label = (_coverageData()['label'] ?? _routeData()?['coverage_label'] ?? _backendRisk?['coverage_label'] ?? '').toString().toLowerCase();
    final percent = _coveragePercent();
    if (label.contains('high') || percent >= 70) return AppColors.green;
    if (label.contains('medium') || percent >= 35) return const Color(0xFF2563EB);
    if (label.contains('partial') || percent > 0) return AppColors.amber;
    return AppColors.ink3;
  }

  List<Map<String, dynamic>> _coverageZones() {
    final raw = _routeData()?['coverage_zones'] ?? _backendRisk?['coverage_zones'] ?? _coverageData()['zones'];
    if (raw is! List) return [];
    return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  List<Polygon> _buildCoveragePolygons() {
    final polygons = <Polygon>[];
    for (final zone in _coverageZones()) {
      final rawPolygon = zone['polygon'];
      final points = <LatLng>[];
      if (rawPolygon is List) {
        for (final pair in rawPolygon) {
          if (pair is List && pair.length >= 2 && pair[0] is num && pair[1] is num) {
            points.add(LatLng((pair[0] as num).toDouble(), (pair[1] as num).toDouble()));
          } else if (pair is Map) {
            final lat = (pair['lat'] ?? pair['latitude']) as num?;
            final lng = (pair['lng'] ?? pair['longitude']) as num?;
            if (lat != null && lng != null) points.add(LatLng(lat.toDouble(), lng.toDouble()));
          }
        }
      }

      if (points.length < 3 && zone['bounds'] is Map) {
        final b = Map<String, dynamic>.from(zone['bounds'] as Map);
        final south = (b['south'] as num?)?.toDouble();
        final west = (b['west'] as num?)?.toDouble();
        final north = (b['north'] as num?)?.toDouble();
        final east = (b['east'] as num?)?.toDouble();
        if (south != null && west != null && north != null && east != null) {
          points.addAll([LatLng(south, west), LatLng(north, west), LatLng(north, east), LatLng(south, east)]);
        }
      }

      if (points.length >= 3) {
        final color = _coverageColor();
        polygons.add(Polygon(
          points: points,
          color: color.withValues(alpha: 0.10),
          borderColor: color.withValues(alpha: 0.45),
          borderStrokeWidth: 2,
        ));
      }
    }
    return polygons;
  }

  String _routeRecommendation() {
    final value = (_routeData()?['route_recommendation'] ?? _backendRisk?['route_recommendation'])?.toString();
    if (value != null && value.trim().isNotEmpty) return value;
    return 'Choose crowded, well-lit roads and keep your location shared with trusted contacts.';
  }

  List<String> _routeWarnings() {
    final raw = _routeData()?['route_warnings'] ?? _backendRisk?['route_warnings'];
    if (raw is List) {
      return raw.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).take(3).toList();
    }
    return [];
  }

  int _breakdownScore(String key) {
    final data = _routeData()?['safety_breakdown'] ?? _backendRisk?['safety_breakdown'];
    if (data is Map && data[key] is num) return (data[key] as num).round().clamp(0, 100).toInt();
    final direct = _routeData()?[key] ?? _backendRisk?[key];
    if (direct is num) return direct.round().clamp(0, 100).toInt();
    return 0;
  }

  int _timeAdjustment() {
    final data = _routeData()?['safety_breakdown'] ?? _backendRisk?['safety_breakdown'];
    if (data is Map && data['time_adjustment'] is num) return (data['time_adjustment'] as num).round();
    final direct = _routeData()?['time_adjustment'] ?? _backendRisk?['time_adjustment'];
    if (direct is num) return direct.round();
    return 0;
  }

  Map<String, dynamic> _trafficData() {
    final direct = _routeData()?['traffic_insight'] ?? _backendRisk?['traffic_insight'];
    if (direct is Map<String, dynamic>) return direct;
    if (direct is Map) return Map<String, dynamic>.from(direct);

    return {
      'label': _routeData()?['traffic_label'] ?? _backendRisk?['traffic_label'] ?? 'Light',
      'delay_minutes': _routeData()?['traffic_delay_min'] ?? _backendRisk?['traffic_delay_min'] ?? 0,
      'provider': _routeData()?['traffic_provider'] ?? _backendRisk?['traffic_provider'] ?? 'local',
      'score': _routeData()?['traffic_score'] ?? _backendRisk?['traffic_score'] ?? 100,
      'recommendation': _routeData()?['traffic_recommendation'] ?? _backendRisk?['traffic_recommendation'],
    };
  }

  String _trafficLabel() => (_trafficData()['label'] ?? 'Light').toString();

  num _trafficDelay() {
    final value = _trafficData()['delay_minutes'] ?? _trafficData()['traffic_delay_min'] ?? 0;
    if (value is num) return value;
    return num.tryParse(value.toString()) ?? 0;
  }

  String _trafficProvider() {
    final provider = (_trafficData()['provider'] ?? 'local').toString();
    return provider == 'local' ? 'Local estimate' : provider.toUpperCase();
  }

  String _trafficRecommendation() {
    final value = _trafficData()['recommendation']?.toString();
    if (value != null && value.trim().isNotEmpty) return value;
    return 'Traffic estimate uses local rush-hour logic and user road reports when paid APIs are unavailable.';
  }

  LatLng? _reportPoint() {
    final selected = _selectedRouteOption();
    final points = selected == null ? _routePoints : _pointsFromRouteOption(selected);
    if (points.isNotEmpty) return points[points.length ~/ 2];
    return _start;
  }

  Future<void> _showReportIssueSheet() async {
    final point = _reportPoint();
    if (point == null) {
      _showSnack('Route/location not ready yet.');
      return;
    }

    final options = <_RouteIssueOption>[
      const _RouteIssueOption(id: 'jam', label: 'Traffic jam', icon: Icons.traffic, severity: 'medium'),
      const _RouteIssueOption(id: 'road_blocked', label: 'Road blocked', icon: Icons.block, severity: 'high'),
      const _RouteIssueOption(id: 'felt_unsafe', label: 'Felt unsafe', icon: Icons.warning_amber, severity: 'high'),
      const _RouteIssueOption(id: 'low_light', label: 'Low light / isolated', icon: Icons.nightlight_round, severity: 'medium'),
      const _RouteIssueOption(id: 'harassment_spot', label: 'Harassment spot', icon: Icons.report_problem_outlined, severity: 'high'),
    ];

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Report route issue', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.ink)),
            const SizedBox(height: 6),
            Text(
              'Your report helps SafeHerBD avoid jammed or unsafe segments for future users. Reports expire automatically.',
              style: GoogleFonts.hindSiliguri(color: AppColors.ink2, height: 1.35),
            ),
            const SizedBox(height: 12),
            ...options.map((option) => ListTile(
                  dense: true,
                  leading: Icon(option.icon, color: AppColors.green),
                  title: Text(option.label, style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
                  onTap: () async {
                    Navigator.of(context).pop();
                    await _submitRoadReport(option, point);
                  },
                )),
          ]),
        ),
      ),
    );
  }

  Future<void> _submitRoadReport(_RouteIssueOption option, LatLng point) async {
    final result = await _api.reportRouteIssue(
      reportType: option.id,
      latitude: point.latitude,
      longitude: point.longitude,
      severity: option.severity,
      routeId: _backendRisk?['route_id']?.toString(),
      travelMode: _selectedMode.id,
      routePreference: _selectedPreference.id,
    );
    if (!mounted) return;
    _showSnack(result['success'] == true ? 'Report saved. Thank you.' : (result['message']?.toString() ?? 'Could not save report'));
    if (result['success'] == true && _end != null) {
      await _calculateRoute();
    }
  }

  Future<void> _loadActiveJourney({bool silent = false}) async {
    if (!silent && mounted) setState(() => _journeyBusy = true);
    final journey = await _api.getActiveJourneySafety();
    if (!mounted) return;
    setState(() {
      _activeJourney = journey;
      _journeyBusy = false;
    });
  }

  Future<void> _startJourneySafety() async {
    if (_start == null || _routePoints.length < 2) {
      _showSnack('Calculate a route first.');
      return;
    }
    setState(() => _journeyBusy = true);
    final selected = _selectedRouteOption();
    final result = await _api.startJourneySafety(
      startLat: _start!.latitude,
      startLng: _start!.longitude,
      endLat: _end?.latitude,
      endLng: _end?.longitude,
      startLabel: 'Current location',
      endLabel: _endLabel.isEmpty ? null : _endLabel,
      routeLabel: selected?['label']?.toString() ?? _selectedPreference.label,
      travelMode: _selectedMode.id,
      routePreference: _selectedPreference.id,
      safetyScore: _safetyScore(),
      expectedDurationMin: _durationMinutesForJourney(),
      metadata: {
        'distance_text': _distanceText,
        'duration_text': _durationText,
        'risk_level': _riskLevel(),
        'traffic': _trafficData(),
      },
    );
    if (!mounted) return;
    setState(() {
      _activeJourney = result['journey'] is Map ? Map<String, dynamic>.from(result['journey']) : null;
      _journeyBusy = false;
    });
    _showSnack(result['message']?.toString() ?? (result['success'] == true ? 'Journey started' : 'Could not start journey'));
  }

  int _durationMinutesForJourney() {
    final data = _selectedRouteOption() ?? _backendRisk;
    final v = data?['traffic_adjusted_duration_min'] ?? data?['duration_min'] ?? data?['estimated_time_min'];
    if (v is num && v > 0) return v.round().clamp(1, 1440).toInt();
    final match = RegExp(r'(\d+)').firstMatch(_durationText);
    if (match != null) return (int.tryParse(match.group(1) ?? '') ?? 30).clamp(1, 1440).toInt();
    return 30;
  }

  Future<void> _journeyCheckIn(String status, {String? note}) async {
    final id = _activeJourney?['id']?.toString();
    if (id == null || id.isEmpty) return;
    setState(() => _journeyBusy = true);
    final loc = _start;
    final result = await _api.checkInJourneySafety(
      journeyId: id,
      status: status,
      latitude: loc?.latitude,
      longitude: loc?.longitude,
      note: note,
    );
    if (!mounted) return;
    setState(() {
      if (result['journey'] is Map) _activeJourney = Map<String, dynamic>.from(result['journey']);
      _journeyBusy = false;
    });
    _showSnack(result['message']?.toString() ?? 'Journey updated');
  }

  Future<void> _completeJourneySafety() async {
    final id = _activeJourney?['id']?.toString();
    if (id == null || id.isEmpty) return;
    setState(() => _journeyBusy = true);
    final result = await _api.completeJourneySafety(id);
    if (!mounted) return;
    setState(() {
      _activeJourney = null;
      _journeyBusy = false;
    });
    _showSnack(result['message']?.toString() ?? 'Journey completed');
  }

  Future<void> _cancelJourneySafety() async {
    final id = _activeJourney?['id']?.toString();
    if (id == null || id.isEmpty) return;
    setState(() => _journeyBusy = true);
    final result = await _api.cancelJourneySafety(id);
    if (!mounted) return;
    setState(() {
      _activeJourney = null;
      _journeyBusy = false;
    });
    _showSnack(result['message']?.toString() ?? 'Journey cancelled');
  }

  List<Map<String, dynamic>> _alternatives() {
    if (_routeOptions.isNotEmpty) return _routeOptions;
    final raw = _backendRisk?['alternative_route_options'];
    if (raw is List) {
      return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).take(4).toList();
    }
    return [];
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


  void _showModeInfo(_TransportMode mode) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 22),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: AppColors.green.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(mode.icon, color: AppColors.green, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${mode.label} route mode',
                style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: AppColors.ink, fontSize: 16),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          Text(
            mode.description,
            style: GoogleFonts.hindSiliguri(color: AppColors.ink2, height: 1.45, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Text(
            'Profile: ${mode.routeProfile}${mode.vehicleType == null ? '' : ' • Vehicle: ${mode.vehicleType}'}',
            style: GoogleFonts.inter(color: AppColors.ink3, fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ]),
      ),
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
                onTap: (_, point) => _handleMapTap(point),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.safeher.bangladesh',
                ),
                if (_showCoverageLayer && _coverageZones().isNotEmpty)
                  PolygonLayer(polygons: _buildCoveragePolygons()),
                if (_routeOptions.isNotEmpty || _routePoints.isNotEmpty)
                  PolylineLayer(polylines: _buildRoutePolylines()),
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
                                    _routeOptions = [];
                                    _selectedRouteIndex = 0;
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
              const SizedBox(height: 10),
              _FloatingMapButton(
                icon: _showCoverageLayer ? Icons.layers : Icons.layers_outlined,
                tooltip: 'Toggle risk coverage',
                onTap: () => setState(() => _showCoverageLayer = !_showCoverageLayer),
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
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        height: 38,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _TransportModes.all.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final mode = _TransportModes.all[index];
            return _TransportChip(
              icon: mode.icon,
              text: mode.shortLabel,
              selected: _selectedMode.id == mode.id,
              onTap: () => _selectTransportMode(mode),
            );
          },
        ),
      ),
      const SizedBox(height: 8),
      SizedBox(
        height: 34,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _RoutePreferences.all.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final pref = _RoutePreferences.all[index];
            return _PreferenceChip(
              icon: pref.icon,
              text: pref.shortLabel,
              selected: _selectedPreference.id == pref.id,
              onTap: () => _selectRoutePreference(pref),
            );
          },
        ),
      ),
      const SizedBox(height: 8),
      Row(children: [
        _ModeChip(
          icon: Icons.directions,
          text: '${_selectedPreference.shortLabel} • ${_selectedMode.tip}',
          selected: true,
          onTap: () => _showModeInfo(_selectedMode),
        ),
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
      ]),
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

  List<Polyline> _buildRoutePolylines() {
    if (_routeOptions.isEmpty) {
      return [Polyline(points: _routePoints, strokeWidth: 5, color: _routeColor())];
    }

    final lines = <Polyline>[];
    for (var i = 0; i < _routeOptions.length; i++) {
      if (i == _selectedRouteIndex) continue;
      final option = _routeOptions[i];
      final points = _pointsFromRouteOption(option);
      if (points.length < 2) continue;
      lines.add(Polyline(
        points: points,
        strokeWidth: 4,
        color: _routeOptionColor(option).withValues(alpha: 0.36),
      ));
    }

    final selected = _selectedRouteOption();
    final selectedPoints = selected == null ? _routePoints : _pointsFromRouteOption(selected);
    if (selectedPoints.length >= 2) {
      lines.add(Polyline(
        points: selectedPoints,
        strokeWidth: 7,
        color: _routeOptionColor(selected ?? {}),
      ));
    }
    return lines;
  }

  Color _routeOptionColor(Map<String, dynamic> option) {
    final score = ((option['safety_score'] ?? option['score'] ?? _safetyScore()) as num?)?.round() ?? _safetyScore();
    final id = option['id']?.toString() ?? option['preference_id']?.toString() ?? '';
    if (id.contains('main')) return const Color(0xFF2563EB);
    if (score >= 78) return AppColors.green;
    if (score >= 55) return AppColors.amber;
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
                        Text(_selectedRouteOption()?['label']?.toString() ?? 'Safety Score', style: GoogleFonts.inter(color: AppColors.ink3, fontSize: 11)),
                        const SizedBox(height: 2),
                        Text(
                          _endLabel.isEmpty ? 'Destination' : _endLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(color: AppColors.ink, fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_selectedMode.label} • ${_routeOptions.length > 1 ? 'Tap route line to choose • ' : ''}${_riskSource()}${_cellsEvaluated() > 0 ? ' • ${_cellsEvaluated()} cells checked' : ''}',
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
                  const SizedBox(height: 10),
                  _buildSafetyInsightCard(),
                  const SizedBox(height: 10),
                  _buildJourneySafetyCard(),
                  const SizedBox(height: 12),
                ],
                _buildSafePlacesPreview(),
              ]),
            ),
    );
  }

  Widget _buildJourneySafetyCard() {
    final active = _activeJourney;
    final isActive = active != null && active['status']?.toString() == 'active';
    final canStart = _routePoints.length >= 2 && !isActive;
    final eta = active?['eta_at']?.toString();
    final last = active?['last_checkin_at']?.toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive ? AppColors.green.withValues(alpha: 0.08) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isActive ? AppColors.green.withValues(alpha: 0.35) : AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(isActive ? Icons.shield : Icons.shield_outlined, size: 17, color: isActive ? AppColors.green : AppColors.ink2),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              isActive ? 'Journey Safety Mode active' : 'Start Journey Safety Mode',
              style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: AppColors.ink, fontSize: 12.5),
            ),
          ),
          if (_journeyBusy) const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.green)),
        ]),
        const SizedBox(height: 6),
        Text(
          isActive
              ? 'Keep checking in during this trip. If you feel unsafe, use SOS immediately.'
              : 'Share a timed safety session for this route. You can check in, mark reached safely, or trigger SOS.',
          style: GoogleFonts.hindSiliguri(color: AppColors.ink2, height: 1.35, fontSize: 12),
        ),
        if (isActive && (eta != null || last != null)) ...[
          const SizedBox(height: 7),
          Wrap(spacing: 8, runSpacing: 6, children: [
            if (eta != null) const _MiniInfoChip(icon: Icons.schedule, text: 'ETA tracked'),
            if (last != null) const _MiniInfoChip(icon: Icons.check_circle_outline, text: 'Last check-in saved'),
          ]),
        ],
        const SizedBox(height: 10),
        if (!isActive)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: canStart && !_journeyBusy ? _startJourneySafety : null,
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: Text('Start journey safety', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 11),
              ),
            ),
          )
        else
          Wrap(spacing: 8, runSpacing: 8, children: [
            _JourneyActionButton(
              icon: Icons.check_circle,
              label: 'I am safe',
              color: AppColors.green,
              onTap: _journeyBusy ? null : () => _journeyCheckIn('safe', note: 'User checked in as safe.'),
            ),
            _JourneyActionButton(
              icon: Icons.flag_circle,
              label: 'Reached',
              color: const Color(0xFF2563EB),
              onTap: _journeyBusy ? null : _completeJourneySafety,
            ),
            _JourneyActionButton(
              icon: Icons.warning_amber,
              label: 'Need help',
              color: AppColors.amber,
              onTap: _journeyBusy ? null : () => _journeyCheckIn('help_needed', note: 'User marked help needed during journey.'),
            ),
            _JourneyActionButton(
              icon: Icons.close,
              label: 'Cancel',
              color: AppColors.ink2,
              onTap: _journeyBusy ? null : _cancelJourneySafety,
            ),
          ]),
      ]),
    );
  }

  Widget _buildSafetyInsightCard() {
    final mainRoad = _breakdownScore('main_road_score');
    final safeStop = _breakdownScore('safe_stop_score');
    final warnings = _routeWarnings();
    final alternatives = _alternatives();
    final timePenalty = _timeAdjustment();
    final trafficLabel = _trafficLabel();
    final trafficDelay = _trafficDelay();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.route, size: 16, color: AppColors.green),
          const SizedBox(width: 6),
          Text('Safety route insight', style: GoogleFonts.inter(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 12.5)),
          const Spacer(),
          Text(_coverageText(), style: GoogleFonts.inter(color: AppColors.ink3, fontWeight: FontWeight.w700, fontSize: 10.5)),
        ]),
        const SizedBox(height: 9),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _BreakdownPill(label: 'Main roads', value: mainRoad == 0 ? '—' : '$mainRoad', icon: Icons.add_road),
          _BreakdownPill(label: 'Safe stops', value: safeStop == 0 ? '${_safePlaces.length}' : '$safeStop', icon: Icons.verified_user_outlined),
          _BreakdownPill(label: 'Coverage', value: _coveragePercent() > 0 ? '${_coveragePercent()}%' : _coverageConfidence(), icon: Icons.layers_outlined),
          _BreakdownPill(label: 'Mode', value: _selectedPreference.shortLabel, icon: _selectedPreference.icon),
          _BreakdownPill(
            label: 'Traffic',
            value: trafficDelay > 0 ? '$trafficLabel +${trafficDelay.round()}m' : trafficLabel,
            icon: Icons.traffic,
          ),
          if (timePenalty > 0) _BreakdownPill(label: 'Night risk', value: '+$timePenalty', icon: Icons.nightlight_round),
        ]),
        const SizedBox(height: 9),
        Text(
          _routeRecommendation(),
          style: GoogleFonts.hindSiliguri(color: AppColors.ink2, fontWeight: FontWeight.w700, fontSize: 11.8, height: 1.35),
        ),
        if (_coverageNote().trim().isNotEmpty) ...[
          const SizedBox(height: 7),
          _CoverageInfoLine(text: _coverageNote(), color: _coverageColor()),
        ],
        const SizedBox(height: 8),
        _TrafficInsightLine(
          provider: _trafficProvider(),
          text: _trafficRecommendation(),
          label: trafficLabel,
          delay: trafficDelay,
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _showReportIssueSheet,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: const Size(0, 32),
              foregroundColor: AppColors.red,
            ),
            icon: const Icon(Icons.report_gmailerrorred_outlined, size: 16),
            label: Text('Report jam / unsafe road', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 11.5)),
          ),
        ),
        if (warnings.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...warnings.map((w) => _WarningLine(text: w)),
        ],
        if (alternatives.isNotEmpty) ...[
          const SizedBox(height: 9),
          Text('Tap a route line or choose below', style: GoogleFonts.inter(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 11.5)),
          const SizedBox(height: 5),
          ...alternatives.asMap().entries.map((e) => _AlternativeRouteRow(
                data: e.value,
                selected: _routeOptions.isNotEmpty ? e.key == _selectedRouteIndex : (e.value['id']?.toString() == _selectedPreference.id),
                onTap: _routeOptions.isNotEmpty ? () => _selectRouteOption(e.key) : null,
              )),
        ],
      ]),
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



class _RoutePreference {
  final String id;
  final String label;
  final String shortLabel;
  final IconData icon;
  final String description;

  const _RoutePreference({
    required this.id,
    required this.label,
    required this.shortLabel,
    required this.icon,
    required this.description,
  });
}

class _RoutePreferences {
  static const safest = _RoutePreference(
    id: 'safest',
    label: 'Safest Route',
    shortLabel: 'Safest',
    icon: Icons.shield_outlined,
    description: 'Prioritizes risk score, nearby support points and safer-road guidance.',
  );

  static const mainRoads = _RoutePreference(
    id: 'main_roads',
    label: 'Main Roads',
    shortLabel: 'Main roads',
    icon: Icons.add_road,
    description: 'Prefers visible roads and public support points over shortcuts where possible.',
  );

  static const balanced = _RoutePreference(
    id: 'balanced',
    label: 'Balanced',
    shortLabel: 'Balanced',
    icon: Icons.tune,
    description: 'Balances estimated safety, distance and time.',
  );

  static const fastest = _RoutePreference(
    id: 'fastest',
    label: 'Fastest',
    shortLabel: 'Fastest',
    icon: Icons.flash_on,
    description: 'Prioritizes time. SafeHerBD still warns if the route seems weakly supported.',
  );

  static const all = <_RoutePreference>[safest, mainRoads, balanced, fastest];
}

class _TransportMode {
  final String id;
  final String label;
  final String shortLabel;
  final String backendMode;
  final String routeProfile;
  final String? vehicleType;
  final IconData icon;
  final String tip;
  final String description;
  final double fallbackSpeedKmh;

  const _TransportMode({
    required this.id,
    required this.label,
    required this.shortLabel,
    required this.backendMode,
    required this.routeProfile,
    required this.icon,
    required this.tip,
    required this.description,
    required this.fallbackSpeedKmh,
    this.vehicleType,
  });
}

class _TransportModes {
  static const walk = _TransportMode(
    id: 'walk',
    label: 'Walking',
    shortLabel: 'Walk',
    backendMode: 'foot-walking',
    routeProfile: 'foot-walking',
    icon: Icons.directions_walk,
    tip: 'Walking safety',
    description: 'Best for pedestrian movement. Safe stops, lighting, crowds, and emergency access are prioritized in the safety guidance.',
    fallbackSpeedKmh: 4.5,
  );

  static const bike = _TransportMode(
    id: 'bike',
    label: 'Bike/Cycle',
    shortLabel: 'Bike',
    backendMode: 'bike',
    routeProfile: 'cycling-regular',
    icon: Icons.directions_bike,
    tip: 'Bike route',
    description: 'Uses cycling-compatible routing when available. Prefer visible roads, safe stops, and avoid isolated shortcuts during unsafe hours.',
    fallbackSpeedKmh: 14,
  );

  static const car = _TransportMode(
    id: 'car',
    label: 'Car',
    shortLabel: 'Car',
    backendMode: 'car',
    routeProfile: 'driving-car',
    icon: Icons.directions_car,
    tip: 'Car route',
    description: 'Uses driving route profile. Useful for ride-share, private car, or safer pickup/drop-off planning.',
    fallbackSpeedKmh: 28,
  );

  static const cng = _TransportMode(
    id: 'cng',
    label: 'CNG/Rickshaw',
    shortLabel: 'CNG',
    backendMode: 'cng',
    routeProfile: 'driving-car',
    icon: Icons.local_taxi,
    tip: 'Local vehicle',
    description: 'Approximates CNG/rickshaw movement using road routing. Choose busy, known roads and share your live location with trusted contacts.',
    fallbackSpeedKmh: 18,
  );

  static const bus = _TransportMode(
    id: 'bus',
    label: 'Bus',
    shortLabel: 'Bus',
    backendMode: 'bus',
    routeProfile: 'driving-hgv',
    vehicleType: 'bus',
    icon: Icons.directions_bus,
    tip: 'Bus-style route',
    description: 'Approximates bus/heavy-vehicle road compatibility. This does not include live public transport schedules.',
    fallbackSpeedKmh: 22,
  );

  static const truck = _TransportMode(
    id: 'truck',
    label: 'Truck/Heavy',
    shortLabel: 'Truck',
    backendMode: 'truck',
    routeProfile: 'driving-hgv',
    vehicleType: 'hgv',
    icon: Icons.local_shipping,
    tip: 'Heavy vehicle',
    description: 'Uses heavy-vehicle road profile where available. Added for technical route support and transport-mode completeness.',
    fallbackSpeedKmh: 20,
  );

  static const wheelchair = _TransportMode(
    id: 'wheelchair',
    label: 'Wheelchair',
    shortLabel: 'Wheel',
    backendMode: 'wheelchair',
    routeProfile: 'wheelchair',
    icon: Icons.accessible,
    tip: 'Accessible route',
    description: 'Uses wheelchair-compatible routing where available. If the service cannot route it, SafeHerBD falls back to a basic safety route.',
    fallbackSpeedKmh: 3.5,
  );

  static const all = <_TransportMode>[walk, bike, car, cng, bus, truck, wheelchair];
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



class _PreferenceChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool selected;
  final VoidCallback? onTap;
  const _PreferenceChip({required this.icon, required this.text, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : AppColors.ink2;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? AppColors.ink : AppColors.border),
          boxShadow: selected ? const [BoxShadow(color: Colors.black12, blurRadius: 7)] : null,
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(text, style: GoogleFonts.inter(color: color, fontWeight: FontWeight.w900, fontSize: 11)),
        ]),
      ),
    );
  }
}

class _BreakdownPill extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _BreakdownPill({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: AppColors.green, size: 14),
          const SizedBox(width: 5),
          Text('$label: ', style: GoogleFonts.inter(color: AppColors.ink3, fontWeight: FontWeight.w700, fontSize: 10.5)),
          Text(value, style: GoogleFonts.inter(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 10.5)),
        ]),
      );
}

class _WarningLine extends StatelessWidget {
  final String text;
  const _WarningLine({required this.text});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.amber, size: 15),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: GoogleFonts.hindSiliguri(color: AppColors.ink2, fontSize: 11.3, height: 1.3))),
        ]),
      );
}

class _CoverageInfoLine extends StatelessWidget {
  final String text;
  final Color color;
  const _CoverageInfoLine({required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.layers_outlined, size: 15, color: color),
          const SizedBox(width: 7),
          Expanded(child: Text(text, style: GoogleFonts.hindSiliguri(color: AppColors.ink2, fontSize: 11.5, height: 1.35))),
        ]),
      );
}


class _AlternativeRouteRow extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool selected;
  final VoidCallback? onTap;
  const _AlternativeRouteRow({required this.data, required this.selected, this.onTap});

  @override
  Widget build(BuildContext context) {
    final score = (data['safety_score'] ?? data['score'])?.toString() ?? '—';
    final label = data['label']?.toString() ?? 'Route';
    final distance = data['distance_km'] is num ? '${(data['distance_km'] as num).toStringAsFixed(1)} km' : '';
    final duration = (data['duration_min'] ?? data['estimated_time_min']) is num
        ? '${((data['duration_min'] ?? data['estimated_time_min']) as num).round()} min'
        : '';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        margin: const EdgeInsets.only(bottom: 5),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.green.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: selected ? AppColors.green.withValues(alpha: 0.35) : AppColors.border),
        ),
        child: Row(children: [
          Icon(selected ? Icons.check_circle : Icons.alt_route, size: 14, color: selected ? AppColors.green : AppColors.ink3),
          const SizedBox(width: 7),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: GoogleFonts.inter(color: AppColors.ink, fontWeight: FontWeight.w800, fontSize: 11.5)),
              if (distance.isNotEmpty || duration.isNotEmpty)
                Text('$distance${distance.isNotEmpty && duration.isNotEmpty ? ' • ' : ''}$duration',
                    style: GoogleFonts.inter(color: AppColors.ink3, fontWeight: FontWeight.w600, fontSize: 10)),
            ]),
          ),
          Text('$score/100', style: GoogleFonts.inter(color: selected ? AppColors.green : AppColors.ink2, fontWeight: FontWeight.w900, fontSize: 11)),
        ]),
      ),
    );
  }
}

class _TransportChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool selected;
  final VoidCallback? onTap;
  const _TransportChip({required this.icon, required this.text, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : AppColors.green;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.green : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.green : AppColors.green.withValues(alpha: 0.35)),
          boxShadow: selected ? [BoxShadow(color: AppColors.green.withValues(alpha: 0.20), blurRadius: 8)] : null,
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(text, style: GoogleFonts.inter(color: color, fontWeight: FontWeight.w900, fontSize: 11.5)),
        ]),
      ),
    );
  }
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



class _MiniInfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MiniInfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: AppColors.green),
        const SizedBox(width: 4),
        Text(text, style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.ink2)),
      ]),
    );
  }
}

class _JourneyActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const _JourneyActionButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: onTap == null ? 0.07 : 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: onTap == null ? 0.18 : 0.35)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 5),
          Text(label, style: GoogleFonts.inter(color: color, fontWeight: FontWeight.w900, fontSize: 11)),
        ]),
      ),
    );
  }
}

class _RouteIssueOption {
  final String id;
  final String label;
  final IconData icon;
  final String severity;
  const _RouteIssueOption({
    required this.id,
    required this.label,
    required this.icon,
    required this.severity,
  });
}

class _TrafficInsightLine extends StatelessWidget {
  final String provider;
  final String text;
  final String label;
  final num delay;

  const _TrafficInsightLine({
    required this.provider,
    required this.text,
    required this.label,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final color = label.toLowerCase().contains('heavy') || label.toLowerCase().contains('severe')
        ? AppColors.red
        : label.toLowerCase().contains('moderate')
            ? AppColors.amber
            : AppColors.green;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.traffic, color: color, size: 17),
        const SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              delay > 0 ? '$label traffic • +${delay.round()} min • $provider' : '$label traffic • $provider',
              style: GoogleFonts.inter(color: color, fontWeight: FontWeight.w900, fontSize: 11.5),
            ),
            const SizedBox(height: 3),
            Text(
              text,
              style: GoogleFonts.hindSiliguri(color: AppColors.ink2, fontWeight: FontWeight.w600, fontSize: 11.5, height: 1.35),
            ),
          ]),
        ),
      ]),
    );
  }
}
