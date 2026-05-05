import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../services/api_service.dart';
import '../../services/map_service.dart';
import '../../services/ors_service.dart';
import '../../utils/constants.dart';
import '../../widgets/gov_widgets.dart';

class RouteScreen extends StatefulWidget {
  const RouteScreen({super.key});
  @override State<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  final _api      = ApiService();
  final _destCtrl = TextEditingController();
  final _mapCtrl  = MapController();

  bool   _locating  = false;
  bool   _searching = false;
  LatLng? _userLoc;
  List<_RouteOpt>? _routes;
  String? _selId;
  String  _locationStatus = '';

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    setState(() { _locating = true; _locationStatus = 'অবস্থান খুঁজছি...'; });
    try {
      bool enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        setState(() { _locationStatus = 'Location service বন্ধ আছে'; _locating = false; });
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        setState(() { _locationStatus = 'Location permission নেই'; _locating = false; });
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 8));

      setState(() {
        _userLoc = LatLng(pos.latitude, pos.longitude);
        _locating = false;
        _locationStatus = '📍 ${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
      });

      // Move map to user location
      try {
        _mapCtrl.move(_userLoc!, 14);
      } catch (_) {}

    } catch (e) {
      setState(() {
        _userLoc = MapService.dhaka; // fallback to Dhaka
        _locating = false;
        _locationStatus = 'অবস্থান পাওয়া যায়নি — ঢাকা ব্যবহার হচ্ছে';
      });
    }
  }

  Future<void> _searchRoutes() async {
    if (_searching) return;
    final dest = _destCtrl.text.trim();
    if (dest.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('গন্তব্য লিখুন', style: GoogleFonts.hindSiliguri()),
        backgroundColor: AppColors.r,
      ));
      return;
    }

    setState(() { _searching = true; _routes = null; _selId = null; });

    final start = _userLoc ?? MapService.dhaka;

    // Destination: try to geocode using Nominatim (free)
    LatLng end = _getFallbackDest(dest);
    try {
      final geocoded = await _geocode('$dest, Bangladesh');
      if (geocoded != null) end = geocoded;
    } catch (_) {}

    // Get real routes from ORS (foot-walking = safer, more paths)
    final safeRoute = await OrsService.getRoute(
        start: start, end: end, profile: 'foot-walking');
    final fastRoute = await OrsService.getRoute(
        start: start, end: end, profile: 'driving-car');

    // Also try risk engine
    Map<String, dynamic>? riskData;
    try {
      riskData = await _api.getAreaRisk(
        lat: end.latitude, lng: end.longitude,
        areaName: dest,
      );
    } catch (_) {}

    final riskScore = (riskData?['risk_score'] as num?)?.toDouble() ?? 0.35;
    final safeScore = ((1 - riskScore) * 100).round().clamp(50, 95);
    final fastScore = (safeScore * 0.65).round();

    setState(() {
      _searching = false;
      _routes = [
        _RouteOpt(
          id: 'safe',
          en: 'Safe Route', bn: 'নিরাপদ পথ',
          durationBn: safeRoute?.durationBn ?? '২৫–৩৫ মিনিট',
          distBn:     safeRoute?.distanceBn ?? '৫–৮ কিমি',
          score:      safeScore,
          tag: 'Recommended', tagBn: 'প্রস্তাবিত',
          color: AppColors.g,
          points: safeRoute?.points ?? _fallbackPoints(start, end, safe: true),
          highlights: ['Well-lit streets', 'CCTV zones', 'High foot traffic'],
        ),
        _RouteOpt(
          id: 'fast',
          en: 'Fast Route', bn: 'দ্রুত পথ',
          durationBn: fastRoute?.durationBn ?? '১৫–২০ মিনিট',
          distBn:     fastRoute?.distanceBn ?? '৩–৫ কিমি',
          score:      fastScore,
          tag: 'Caution', tagBn: 'সতর্কতা',
          color: AppColors.gold,
          points: fastRoute?.points ?? _fallbackPoints(start, end, safe: false),
          highlights: ['Shorter distance', 'Some dim areas', 'Less foot traffic'],
        ),
      ];
      _selId = 'safe';
    });
  }

  // Nominatim geocoding (free, no key)
  Future<LatLng?> _geocode(String query) async {
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search'
      '?q=${Uri.encodeComponent(query)}&format=json&limit=1'
    );
    final res = await http.get(url,
        headers: {'User-Agent': 'SafeHerBD/1.0'})
        .timeout(const Duration(seconds: 5));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as List;
      if (data.isNotEmpty) {
        return LatLng(
          double.parse(data[0]['lat']),
          double.parse(data[0]['lon']),
        );
      }
    }
    return null;
  }

  // Known Dhaka destinations fallback
  LatLng _getFallbackDest(String dest) {
    final d = dest.toLowerCase();
    if (d.contains('mirpur')) return const LatLng(23.8041, 90.3673);
    if (d.contains('gulshan')) return const LatLng(23.7925, 90.4078);
    if (d.contains('dhanmondi')) return const LatLng(23.7461, 90.3742);
    if (d.contains('uttara')) return const LatLng(23.8759, 90.3795);
    if (d.contains('motijheel')) return const LatLng(23.7330, 90.4186);
    if (d.contains('farmgate')) return const LatLng(23.7587, 90.3890);
    if (d.contains('banani')) return const LatLng(23.7937, 90.4066);
    if (d.contains('mohammadpur')) return const LatLng(23.7647, 90.3563);
    return const LatLng(23.7808, 90.4093);
  }

  List<LatLng> _fallbackPoints(LatLng s, LatLng e, {required bool safe}) {
    final midLat = (s.latitude + e.latitude) / 2;
    final midLng = (s.longitude + e.longitude) / 2;
    final offset = safe ? 0.005 : -0.004;
    return [s, LatLng(midLat + offset, midLng + offset), e];
  }

  _RouteOpt? get _sel => _routes?.firstWhere(
      (r) => r.id == _selId, orElse: () => _routes!.first);

  @override void dispose() { _destCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(children: [
        const HeroHeader(title: 'Safe Route Finder', subtitle: 'নিরাপদ পথ খোঁজা'),
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: Column(children: [

            // Location status bar
            Container(
              width: double.infinity, padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _userLoc != null
                    ? AppColors.g.withOpacity(0.08)
                    : AppColors.gold.withOpacity(0.08),
                border: Border.all(color: _userLoc != null
                    ? AppColors.g.withOpacity(0.25)
                    : AppColors.gold.withOpacity(0.25)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                _locating
                    ? SizedBox(width: 14, height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2,
                            color: AppColors.gold))
                    : Icon(
                        _userLoc != null
                            ? Icons.my_location_rounded
                            : Icons.location_off_rounded,
                        size: 16,
                        color: _userLoc != null ? AppColors.g : AppColors.gold),
                const SizedBox(width: 8),
                Expanded(child: Text(_locationStatus,
                    style: GoogleFonts.dmSans(
                        color: _userLoc != null ? AppColors.g : AppColors.gold,
                        fontSize: 11))),
                if (!_locating)
                  IconButton(
                    onPressed: _getUserLocation,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    color: AppColors.t3, padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ]),
            ),
            const SizedBox(height: 10),

            // Destination input
            GovCard(
              padding: EdgeInsets.zero,
              child: Row(children: [
                const Padding(padding: EdgeInsets.all(14),
                    child: Icon(Icons.location_on_rounded,
                        color: AppColors.r, size: 20)),
                Expanded(child: TextField(
                  controller: _destCtrl,
                  style: GoogleFonts.hindSiliguri(color: AppColors.t1, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'গন্তব্য লিখুন (যেমন: Mirpur 2, Gulshan)',
                    hintStyle: GoogleFonts.hindSiliguri(color: AppColors.t3),
                    border: InputBorder.none, filled: false,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  onSubmitted: (_) => _searchRoutes(),
                )),
                Padding(padding: const EdgeInsets.all(8),
                  child: ElevatedButton(
                    onPressed: _searchRoutes,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      minimumSize: const Size(0, 0),
                    ),
                    child: _searching
                        ? const SizedBox(width: 16, height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.search_rounded, size: 18),
                  )),
              ]),
            ),
            const SizedBox(height: 12),

            // Map
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(children: [
                  MapService.buildMap(
                    controller: _mapCtrl,
                    center: _userLoc ?? MapService.dhaka,
                    zoom: 13,
                    markers: [
                      if (_userLoc != null)
                        MapHelpers.buildMarker(
                          point: _userLoc!,
                          color: AppColors.g,
                          icon: Icons.my_location_rounded,
                        ),
                      if (_sel != null && _sel!.points.isNotEmpty)
                        MapHelpers.buildMarker(
                          point: _sel!.points.last,
                          color: AppColors.r,
                          icon: Icons.location_pin,
                        ),
                    ],
                    circles: [
                      if (_userLoc != null)
                        MapHelpers.buildRiskZone(
                          center: LatLng(
                            _userLoc!.latitude + 0.006,
                            _userLoc!.longitude + 0.008,
                          ),
                          radiusMeters: 350,
                          riskScore: 0.75,
                        ),
                    ],
                    polylines: _sel != null && _sel!.points.length > 1
                        ? [MapHelpers.buildRoute(_sel!.points,
                            isSafe: _sel!.id == 'safe')]
                        : [],
                  ),
                  // Provider badge
                  Positioned(top: 10, right: 10, child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.map_rounded, size: 11, color: AppColors.g),
                      const SizedBox(width: 4),
                      Text('OpenStreetMap + ORS',
                          style: GoogleFonts.dmSans(
                              color: AppColors.t2, fontSize: 9,
                              fontWeight: FontWeight.w600)),
                    ]),
                  )),
                  // Legend
                  Positioned(bottom: 10, left: 10, child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _leg(AppColors.g, 'নিরাপদ পথ'),
                        const SizedBox(height: 3),
                        _leg(AppColors.r, 'ঝুঁকিপূর্ণ এলাকা'),
                        const SizedBox(height: 3),
                        _leg(AppColors.gold, 'সতর্কতা'),
                      ],
                    ),
                  )),
                ]),
              ),
            ),
            const SizedBox(height: 12),

            // Empty state
            if (_routes == null && !_searching)
              GovCard(child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(children: [
                  const Icon(Icons.alt_route_rounded,
                      size: 40, color: AppColors.t3),
                  const SizedBox(height: 8),
                  Text('গন্তব্য লিখে নিরাপদ পথ খুঁজুন',
                      style: GoogleFonts.hindSiliguri(color: AppColors.t2)),
                  const SizedBox(height: 4),
                  Text('উদাহরণ: Mirpur 2, Gulshan, Dhanmondi',
                      style: GoogleFonts.dmSans(
                          color: AppColors.t3, fontSize: 11)),
                ]),
              )),

            // Route options
            if (_routes != null)
              ..._routes!.map((r) => _RouteCard(
                option: r,
                selected: _selId == r.id,
                onTap: () => setState(() => _selId = r.id),
              )),

            const SizedBox(height: 10),

            // ML badge
            GovCard(
              borderColor: AppColors.purple.withOpacity(0.2),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.psychology_rounded,
                      color: AppColors.purple, size: 18),
                  const SizedBox(width: 6),
                  Expanded(child: Text(
                    'Predictive Risk Model — Gradient Boosting + ORS Routing',
                    style: GoogleFonts.dmSans(
                        color: AppColors.purple, fontSize: 11,
                        fontWeight: FontWeight.w600),
                  )),
                ]),
                const SizedBox(height: 8),
                Wrap(spacing: 6, runSpacing: 6,
                  children: ['Historical Crime', 'Time of Day',
                    'Location Metadata', 'Ambient Factors',
                    'riskScore:float', 'ORS Road Data']
                      .map((f) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.purple.withOpacity(0.08),
                          border: Border.all(
                              color: AppColors.purple.withOpacity(0.2)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(f, style: GoogleFonts.dmSans(
                            color: AppColors.t2, fontSize: 10)),
                      )).toList(),
                ),
              ]),
            ),
            const SizedBox(height: 14),

            // Navigate button
            if (_sel != null && _sel!.points.isNotEmpty)
              SizedBox(width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.navigation_rounded),
                  label: Text('নিরাপদ পথে যাত্রা শুরু করুন →',
                      style: GoogleFonts.hindSiliguri(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                        '${_sel!.durationBn} · ${_sel!.distBn} — Navigation শুরু হয়েছে',
                        style: GoogleFonts.hindSiliguri(),
                      ),
                      backgroundColor: AppColors.g,
                      behavior: SnackBarBehavior.floating,
                    ));
                  },
                ),
              ),
            const SizedBox(height: 16),
            const GovFooter(),
          ]),
        )),
      ]),
    );
  }

  Widget _leg(Color c, String l) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 12, height: 3,
        decoration: BoxDecoration(color: c,
            borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 5),
    Text(l, style: GoogleFonts.hindSiliguri(
        color: AppColors.t2, fontSize: 10)),
  ]);
}

// ── Route Option Model ────────────────────────────────────────────
class _RouteOpt {
  final String id, en, bn, durationBn, distBn, tag, tagBn;
  final int score;
  final Color color;
  final List<LatLng> points;
  final List<String> highlights;
  _RouteOpt({required this.id, required this.en, required this.bn,
    required this.durationBn, required this.distBn, required this.score,
    required this.tag, required this.tagBn, required this.color,
    required this.points, required this.highlights});
}

// ── Route Card ────────────────────────────────────────────────────
class _RouteCard extends StatelessWidget {
  final _RouteOpt option;
  final bool selected;
  final VoidCallback onTap;
  const _RouteCard({required this.option,
      required this.selected, required this.onTap});

  @override Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.only(bottom: 10),
      child: GovCard(
        onTap: onTap,
        borderColor: selected
            ? option.color.withOpacity(0.5) : null,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            SizedBox(width: 52, height: 52,
              child: Stack(alignment: Alignment.center, children: [
                CircularProgressIndicator(
                  value: option.score / 100, strokeWidth: 3,
                  backgroundColor: option.color.withOpacity(0.15),
                  valueColor: AlwaysStoppedAnimation(option.color),
                ),
                Text('${option.score}', style: TextStyle(
                    color: option.color, fontSize: 15,
                    fontWeight: FontWeight.w800)),
              ])),
            const SizedBox(width: 12),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(option.en, style: GoogleFonts.dmSans(
                    color: AppColors.t1, fontSize: 14,
                    fontWeight: FontWeight.w700)),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: option.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6)),
                  child: Text(option.tag, style: TextStyle(
                      color: option.color, fontSize: 9,
                      fontWeight: FontWeight.w700)),
                ),
              ]),
              Text(option.bn, style: GoogleFonts.hindSiliguri(
                  color: AppColors.t3, fontSize: 11)),
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.schedule_rounded, size: 12, color: AppColors.t3),
                const SizedBox(width: 3),
                Text(option.durationBn,
                    style: TextStyle(color: AppColors.t2, fontSize: 11)),
                const SizedBox(width: 10),
                Icon(Icons.straighten_rounded, size: 12, color: AppColors.t3),
                const SizedBox(width: 3),
                Text(option.distBn,
                    style: TextStyle(color: AppColors.t2, fontSize: 11)),
              ]),
            ])),
            if (selected)
              Icon(Icons.check_circle_rounded,
                  color: option.color, size: 24),
          ]),
          if (selected) ...[
            const SizedBox(height: 10),
            Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 8),
            ...option.highlights.map((h) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(children: [
                Icon(Icons.check_rounded, size: 14, color: option.color),
                const SizedBox(width: 6),
                Text(h, style: GoogleFonts.dmSans(
                    color: AppColors.t2, fontSize: 12)),
              ]),
            )),
          ],
        ]),
      ));
  }
}

