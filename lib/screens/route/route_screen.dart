import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/api_service.dart';
import '../../services/ors_service.dart';
import '../../utils/constants.dart';
import '../../widgets/design_widgets.dart';

class RouteScreen extends StatefulWidget {
  final void Function(String) onNav;
  final VoidCallback onBack;
  const RouteScreen({super.key, required this.onNav, required this.onBack});
  @override
  State<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  final _api = ApiService();
  final _searchCtrl = TextEditingController(text: 'Bashundhara City Mall');
  final _mapCtrl = MapController();

  bool _riskAware = true;
  bool _showSheet = true;
  bool _searching = false;
  LatLng? _userLoc;
  List<LatLng> _routePoints = [];
  String _distance = '4.2 km';
  String _duration = '24 min';
  int _safetyScore = 88;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    try {
      bool enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition()
          .timeout(const Duration(seconds: 6));
      if (mounted) {
        setState(() => _userLoc = LatLng(pos.latitude, pos.longitude));
        try {
          _mapCtrl.move(_userLoc!, 14);
        } catch (_) {}
      }
    } catch (_) {}
  }

  Future<void> _search() async {
    setState(() => _searching = true);
    final start = _userLoc ?? const LatLng(23.7461, 90.3742); // Dhanmondi
    // Demo destination near Bashundhara
    const end = LatLng(23.8159, 90.4252);

    // Try backend safest-route first (it returns ML risk + ORS polyline)
    final backend = await _api.getSafestRoute(
      startLat: start.latitude,
      startLng: start.longitude,
      endLat: end.latitude,
      endLng: end.longitude,
      travelMode: 'foot-walking',
    );

    List<LatLng>? points;
    String distanceStr = '';
    String durationStr = '';
    int? safetyScore;

    if (backend != null && backend['success'] == true) {
      // Use backend's coords
      final coords = backend['route_coordinates'] ?? backend['coordinates'];
      if (coords is List && coords.isNotEmpty) {
        points = coords.map((c) {
          if (c is List && c.length >= 2) {
            return LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble());
          }
          return start;
        }).toList();
      }
      final distKm = (backend['distance_km'] as num?)?.toDouble() ?? 0.0;
      final durMin = (backend['duration_min'] as num?)?.toDouble() ??
          (backend['estimated_time_min'] as num?)?.toDouble() ?? 0.0;
      distanceStr = distKm < 1
          ? '${(distKm * 1000).round()} মিটার'
          : '${distKm.toStringAsFixed(1)} কিমি';
      durationStr = durMin < 60
          ? '${durMin.round()} মিনিট'
          : '${(durMin / 60).floor()} ঘণ্টা ${(durMin % 60).round()} মিনিট';
      safetyScore = (backend['safety_score'] as num?)?.toInt();
    }

    // Fallback to direct ORS call if backend unreachable
    if (points == null || points.isEmpty) {
      final route = await OrsService.getRoute(
          start: start, end: end, profile: 'foot-walking');
      if (route != null) {
        points = route.points;
        distanceStr = route.distanceBn;
        durationStr = route.durationBn;
      } else {
        points = [start, end];
        distanceStr = 'ছবি না';
        durationStr = 'অজানা';
      }
    }

    if (mounted) {
      setState(() {
        _searching = false;
        _routePoints = points!;
        _distance = distanceStr;
        _duration = durationStr;
        if (safetyScore != null) _safetyScore = safetyScore;
      });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      body: Stack(children: [
        // Real OSM dark map
        Positioned.fill(
          child: FlutterMap(
            mapController: _mapCtrl,
            options: MapOptions(
              initialCenter: _userLoc ?? const LatLng(23.7461, 90.3742),
              initialZoom: 14,
              minZoom: 4,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'bd.gov.safeher',
              ),
              // Dark overlay
              Positioned.fill(
                  child: Container(color: Colors.black.withOpacity(0.45))),
              // H3 risk hex overlay
              if (_riskAware) _RiskHexOverlay(),
              // Route polyline
              if (_routePoints.length > 1)
                PolylineLayer(polylines: [
                  Polyline(
                    points: _routePoints,
                    color: AppColors.green,
                    strokeWidth: 4,
                  ),
                ]),
              // Markers
              MarkerLayer(markers: [
                if (_userLoc != null)
                  Marker(
                    point: _userLoc!,
                    width: 22,
                    height: 22,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(
                            color: AppColors.green, width: 4),
                      ),
                    ),
                  ),
                if (_routePoints.isNotEmpty)
                  Marker(
                    point: _routePoints.last,
                    width: 24,
                    height: 24,
                    child: const Icon(Icons.location_on,
                        color: AppColors.red, size: 24),
                  ),
              ]),
            ],
          ),
        ),

        // Top header (glass-dark)
        Positioned(
          top: 44,
          left: 16,
          right: 16,
          child: Column(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Row(children: [
                IconBtn(
                    icon: Icons.chevron_left,
                    dark: true,
                    onTap: widget.onBack),
                const SizedBox(width: 8),
                const Icon(Icons.search,
                    size: 14, color: Color(0x99FFFFFF)),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Where to?',
                      hintStyle: TextStyle(color: Color(0x99FFFFFF)),
                      border: InputBorder.none,
                      isCollapsed: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                IconBtn(
                    icon: Icons.mic_none, dark: true, onTap: () {}),
              ]),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _riskAware = !_riskAware),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Row(children: [
                      // Toggle indicator
                      Container(
                        width: 28,
                        height: 16,
                        decoration: BoxDecoration(
                          color: _riskAware
                              ? AppColors.green
                              : Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: AnimatedAlign(
                          duration: const Duration(milliseconds: 150),
                          alignment: _riskAware
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            width: 12,
                            height: 12,
                            margin: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            EnText('Risk-Aware Routing',
                                size: 11,
                                weight: FontWeight.w700,
                                color: Colors.white),
                            EnText('H3 grid · live data',
                                size: 9, color: Color(0x99FFFFFF)),
                          ]),
                    ]),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconBtn(icon: Icons.layers, dark: true),
            ]),
          ]),
        ),

        // Right legend
        Positioned(
          right: 16,
          top: 200,
          child: Container(
            width: 100,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.55),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const EnText('RISK DENSITY',
                      size: 9,
                      weight: FontWeight.w700,
                      color: Color(0x99FFFFFF),
                      letterSpacing: 0.4),
                  const SizedBox(height: 8),
                  _legendRow(AppColors.red.withOpacity(0.9), 'High'),
                  const SizedBox(height: 6),
                  _legendRow(AppColors.amber.withOpacity(0.9), 'Med'),
                  const SizedBox(height: 6),
                  _legendRow(AppColors.green.withOpacity(0.9), 'Safe'),
                ]),
          ),
        ),

        // My location button
        Positioned(
          right: 16,
          bottom: _showSheet ? 280 : 100,
          child: GestureDetector(
            onTap: _getLocation,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 8)),
                ],
              ),
              child: const Icon(Icons.gps_fixed,
                  size: 18, color: AppColors.green),
            ),
          ),
        ),

        // Bottom sheet
        if (_showSheet)
          Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildBottomSheet()),

        // Bottom nav (dark variant)
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: BottomNavBar(
              active: 'route', onNav: widget.onNav, dark: true),
        ),
      ]),
    );
  }

  Widget _legendRow(Color color, String label) =>
      Row(children: [
        Hexagon(fill: color, size: 14),
        const SizedBox(width: 6),
        EnText(label,
            size: 10.5,
            weight: FontWeight.w500,
            color: Colors.white),
      ]);

  Widget _buildBottomSheet() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 30,
              offset: const Offset(0, -8)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Drag handle
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.line,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Recommended route card
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.greenSoft,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.green.withOpacity(0.2)),
          ),
          child: Row(children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: AppColors.green,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.alt_route,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(children: [
                    const EnText('Safe Route',
                        size: 13, weight: FontWeight.w700),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.green,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const EnText('RECOMMENDED',
                          size: 8.5,
                          weight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.4),
                    ),
                  ]),
                  const SizedBox(height: 2),
                  Row(children: [
                    EnText(_duration,
                        size: 11, color: AppColors.ink2),
                    const Text(' · ',
                        style: TextStyle(color: AppColors.ink3)),
                    EnText(_distance,
                        size: 11, color: AppColors.ink2),
                    const Text(' · ',
                        style: TextStyle(color: AppColors.ink3)),
                    EnText("Score $_safetyScore",
                        size: 11,
                        weight: FontWeight.w600,
                        color: AppColors.green),
                  ]),
                ])),
          ]),
        ),
        const SizedBox(height: 8),

        // Alternative
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.flash_on,
                  color: AppColors.amber, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                  Row(children: [
                    EnText('Fast Route',
                        size: 13, weight: FontWeight.w700),
                    SizedBox(width: 6),
                    EnText('CAUTION',
                        size: 8.5,
                        weight: FontWeight.w700,
                        color: AppColors.amber,
                        letterSpacing: 0.4),
                  ]),
                  SizedBox(height: 2),
                  Row(children: [
                    EnText('19 min · 3.8 km · Score 52',
                        size: 11, color: AppColors.ink2),
                  ]),
                ])),
          ]),
        ),

        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _searching ? null : _search,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: _searching
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Row(mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.navigation, size: 18, color: Colors.white),
                      SizedBox(width: 6),
                      EnText('Start Navigation',
                          size: 14,
                          weight: FontWeight.w700,
                          color: Colors.white),
                    ]),
          ),
        ),
      ]),
    );
  }
}

// ── Hex risk overlay (random pattern over Dhaka coords) ──────────
class _RiskHexOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(painter: _HexRiskPainter()),
      ),
    );
  }
}

class _HexRiskPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    const cols = 8, rows = 14;
    final w = size.width / cols;
    final h = w * 0.866;
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final cx = c * w + (r.isOdd ? w / 2 : 0);
        final cy = r * h * 0.75;
        if (rng.nextDouble() < 0.35) {
          final risk = rng.nextDouble();
          final color = risk > 0.7
              ? AppColors.red
              : risk > 0.4
                  ? AppColors.amber
                  : AppColors.green;
          final path = ui.Path();
          final size_ = w * 0.4;
          for (int i = 0; i < 6; i++) {
            final a = -math.pi / 6 + i * math.pi / 3;
            final x = cx + math.cos(a) * size_;
            final y = cy + math.sin(a) * size_;
            if (i == 0) {
              path.moveTo(x, y);
            } else {
              path.lineTo(x, y);
            }
          }
          path.close();
          canvas.drawPath(
              path, Paint()..color = color.withOpacity(0.18));
          canvas.drawPath(
              path,
              Paint()
                ..color = color.withOpacity(0.5)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 0.8);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _) => false;
}
