import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';

class DashboardScreen extends StatefulWidget {
  final void Function(String) onNav;
  const DashboardScreen({super.key, required this.onNav});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _api = ApiService();
  final _auth = AuthService();

  String _userName = '...';
  String _firstName = '';

  Map<String, dynamic>? _city;
  bool _safetyLoading = true;

  List<dynamic> _alerts = [];
  bool _alertsLoading = true;

  int _unread = 0;

  Position? _pos;
  String _areaName = 'Bangladesh';

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _loadUser();
    await _resolveLocation();
    await Future.wait([
      _loadSafetyIndex(),
      _loadRecentAlerts(),
      _loadUnreadCount(),
    ]);
  }

  Future<void> _loadUser() async {
    final u = await _auth.getUser();
    if (!mounted) return;
    setState(() {
      _userName = u?['name']?.toString() ?? 'Sister';
      _firstName = _userName.split(' ').first;
    });
  }

  Future<void> _resolveLocation() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      _pos = await Geolocator.getCurrentPosition().timeout(const Duration(seconds: 6));
      final addr = await _api.reverseGeocode(_pos!.latitude, _pos!.longitude);
      if (addr != null) {
        final m = _asMap(addr['address']);
        _areaName = (m['city'] ?? m['town'] ?? m['suburb'] ?? m['state_district'] ?? 'Dhaka').toString();
      }
      if (mounted) setState(() {});
    } catch (_) {
      _areaName = 'Dhaka';
    }
  }

  Future<void> _loadSafetyIndex() async {
    final all = await _api.getSafetyIndex();
    if (!mounted) return;
    Map<String, dynamic>? match;
    for (final c in all) {
      final m = _asMap(c);
      final cityName = (m['city']?.toString().toLowerCase() ?? '');
      final area = _areaName.toLowerCase();
      if (cityName.contains(area) || area.contains(cityName) && cityName.isNotEmpty) {
        match = m;
        break;
      }
    }
    setState(() {
      _city = match ?? (all.isNotEmpty ? _asMap(all.first) : null);
      _safetyLoading = false;
    });
  }

  Future<void> _loadRecentAlerts() async {
    final list = await _api.getRecentAlerts(
      lat: _pos?.latitude,
      lng: _pos?.longitude,
      limit: 5,
    );
    if (!mounted) return;
    setState(() {
      _alerts = list;
      _alertsLoading = false;
    });
  }

  Future<void> _loadUnreadCount() async {
    final n = await _api.getUnreadNotificationCount();
    if (!mounted) return;
    setState(() => _unread = n);
  }



  int _asInt(dynamic value, {int fallback = 0}) {
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _bootstrap,
          color: AppColors.green,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildTopBar(),
              const SizedBox(height: 18),
              _buildHeroCard(),
              const SizedBox(height: 18),
              _buildSosBigButton(),
              const SizedBox(height: 18),
              _buildQuickActions(),
              const SizedBox(height: 12),
              _buildEvidenceCaseBanner(),
              const SizedBox(height: 12),
              _buildEmergencyToolsBanner(),
              const SizedBox(height: 12),
              _buildQuickActionCard(
                  icon: Icons.school_outlined,
                  title: 'Learning & Rights',
                  subtitle: 'Rights, self-defense and trust profile',
                  color: const Color(0xFF2563EB),
                  onTap: () => Navigator.pushNamed(context, '/learning-profile'),
                ),
              const SizedBox(height: 18),
              _buildSafetyMetrics(),
              const SizedBox(height: 18),
              _buildAlertsCard(),
              const SizedBox(height: 18),
              _buildBottomNav(),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Hello, ${_firstName.isEmpty ? "Sister" : _firstName}',
              style: GoogleFonts.hindSiliguri(
                  color: AppColors.ink, fontWeight: FontWeight.w800, fontSize: 19)),
          const SizedBox(height: 2),
          Text('Stay safe, stay connected.',
              style: GoogleFonts.inter(color: AppColors.ink2, fontSize: 12)),
        ]),
      ),
      _IconBtn(
        icon: Icons.notifications_outlined,
        badgeCount: _unread,
        onTap: () => Navigator.pushNamed(context, '/notifications').then((_) => _loadUnreadCount()),
      ),
      const SizedBox(width: 8),
      _IconBtn(
        icon: Icons.person_outline,
        onTap: () => widget.onNav('profile'),
      ),
    ]);
  }

  Widget _buildHeroCard() {
    if (_safetyLoading) return const _Skeleton(height: 130);
    final score = _asInt(_city?['score']);
    final level = (_city?['risk_level'] ?? 'caution').toString();
    final cityName = (_city?['city'] ?? _areaName).toString();
    final color = _scoreColor(score);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.95), color.withValues(alpha: 0.75)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(children: [
        Container(
          width: 70, height: 70,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
          ),
          alignment: Alignment.center,
          child: Text('$score',
              style: GoogleFonts.inter(color: color, fontWeight: FontWeight.w900, fontSize: 26)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Safety Index', style: GoogleFonts.inter(color: Colors.white70, fontSize: 11)),
            const SizedBox(height: 2),
            Text(cityName,
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 19)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
              child: Text(level.toUpperCase(),
                  style: GoogleFonts.inter(
                      color: Colors.white, fontWeight: FontWeight.w700, fontSize: 10, letterSpacing: 0.6)),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildSosBigButton() {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/sos'),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.red, Color(0xFFC41E32)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: AppColors.red.withValues(alpha: 0.4), blurRadius: 18, offset: const Offset(0, 6))],
        ),
        child: Column(children: [
          const Icon(Icons.shield, color: Colors.white, size: 36),
          const SizedBox(height: 8),
          Text('EMERGENCY SOS',
              style: GoogleFonts.inter(
                  color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.5)),
          const SizedBox(height: 4),
          Text('Tap to alert your contacts',
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 11)),
        ]),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(children: [
      Row(children: [
        _Quick(icon: Icons.alt_route, label: 'Safe Route', onTap: () => widget.onNav('route')),
        const SizedBox(width: 10),
        _Quick(icon: Icons.chat_bubble_outline, label: 'Mitra', onTap: () => widget.onNav('mitra')),
        const SizedBox(width: 10),
        _Quick(icon: Icons.groups_2_outlined, label: 'Community', onTap: () => widget.onNav('community')),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        _Quick(icon: Icons.gavel, label: 'Legal Aid', onTap: () => widget.onNav('legal')),
        const SizedBox(width: 10),
        _Quick(icon: Icons.admin_panel_settings_outlined, label: 'Admin', onTap: () => widget.onNav('admin')),
        const SizedBox(width: 10),
        _Quick(icon: Icons.shield_outlined, label: 'Safety Hub', onTap: () => widget.onNav('communitySafety')),
        const SizedBox(width: 10),
        _Quick(icon: Icons.settings_outlined, label: 'Settings', onTap: () => widget.onNav('settings')),
      ]),
    ]);
  }


  Widget _buildEvidenceCaseBanner() {
    return InkWell(
      onTap: () => widget.onNav('safety-tools'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: AppColors.blue.withValues(alpha: .10), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.folder_copy_outlined, color: AppColors.blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Evidence & Case Center', style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: AppColors.ink)),
              const SizedBox(height: 2),
              Text('Incident report, private evidence vault, and GD/FIR tracker', style: GoogleFonts.inter(fontSize: 11, color: AppColors.ink2)),
            ]),
          ),
          const Icon(Icons.chevron_right, color: AppColors.ink3),
        ]),
      ),
    );
  }

  Widget _buildEmergencyToolsBanner() {
    return InkWell(
      onTap: () => widget.onNav('emergency-tools'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: AppColors.redSoft, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.phone_in_talk_outlined, color: AppColors.red),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Stealth & Emergency Tools', style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: AppColors.ink)),
              const SizedBox(height: 2),
              Text('Decoy call, quick exit, witness mode, and allies nearby', style: GoogleFonts.inter(fontSize: 11, color: AppColors.ink2)),
            ]),
          ),
          const Icon(Icons.chevron_right, color: AppColors.ink3),
        ]),
      ),
    );
  }
  Widget _buildSafetyMetrics() {
    if (_safetyLoading) return const _Skeleton(height: 120);

    final sub = _asMap(_city?['sub_metrics']);
    final street = _asInt(sub['street_safety']);
    final digital = _asInt(sub['digital_safety']);
    final pub = _asInt(sub['public_safety']);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Risk Breakdown',
              style: GoogleFonts.inter(color: AppColors.ink, fontWeight: FontWeight.w700, fontSize: 13.5)),
          const Spacer(),
          Text('Live risk',
              style: GoogleFonts.inter(color: AppColors.green, fontWeight: FontWeight.w700, fontSize: 10)),
        ]),
        const SizedBox(height: 12),
        _Metric(label: 'Street risk', value: street),
        const SizedBox(height: 8),
        _Metric(label: 'Digital risk', value: digital),
        const SizedBox(height: 8),
        _Metric(label: 'Public-space risk', value: pub),
      ]),
    );
  }

  Widget _buildAlertsCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Recent Alerts',
              style: GoogleFonts.inter(color: AppColors.ink, fontWeight: FontWeight.w700, fontSize: 13.5)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('${_alerts.length} active',
                style: GoogleFonts.inter(color: AppColors.amber, fontWeight: FontWeight.w700, fontSize: 10)),
          ),
        ]),
        const SizedBox(height: 10),
        if (_alertsLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator(color: AppColors.green, strokeWidth: 2)),
          )
        else if (_alerts.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('No nearby alerts. Stay aware.',
                style: GoogleFonts.inter(color: AppColors.ink3, fontSize: 12)),
          )
        else
          ..._alerts.take(3).whereType<Map>().map((a) => _AlertRow(alert: Map<String, dynamic>.from(a))),
      ]),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _NavBtn(icon: Icons.home_outlined, label: 'Home', selected: true, onTap: () {}),
        _NavBtn(icon: Icons.alt_route, label: 'Route', selected: false, onTap: () => widget.onNav('route')),
        _NavBtn(icon: Icons.chat_bubble_outline, label: 'Mitra', selected: false, onTap: () => widget.onNav('mitra')),
        _NavBtn(icon: Icons.groups_2_outlined, label: 'Forum', selected: false, onTap: () => widget.onNav('community')),
        _NavBtn(icon: Icons.settings_outlined, label: 'Settings', selected: false, onTap: () => widget.onNav('settings')),
      ]),
    );
  }

  Color _scoreColor(int s) {
    if (s >= 75) return AppColors.green;
    if (s >= 50) return AppColors.amber;
    return AppColors.red;
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final int badgeCount;
  const _IconBtn({required this.icon, required this.onTap, this.badgeCount = 0});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(clipBehavior: Clip.none, children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.line),
          ),
          child: Icon(icon, color: AppColors.ink, size: 20),
        ),
        if (badgeCount > 0)
          Positioned(
            top: -4, right: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              decoration: BoxDecoration(
                color: AppColors.red,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Center(
                child: Text(
                  badgeCount > 99 ? '99+' : '$badgeCount',
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}

class _Quick extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _Quick({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(children: [
              Icon(icon, color: AppColors.green, size: 22),
              const SizedBox(height: 6),
              Text(label,
                  style: GoogleFonts.inter(
                      color: AppColors.ink, fontWeight: FontWeight.w600, fontSize: 11)),
            ]),
          ),
        ),
      );
}

class _Metric extends StatelessWidget {
  final String label;
  final int value;
  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final color = value >= 75 ? AppColors.red : (value >= 50 ? AppColors.amber : AppColors.green);
    return Row(children: [
      SizedBox(
        width: 110,
        child: Text(label, style: GoogleFonts.inter(color: AppColors.ink2, fontSize: 12)),
      ),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: value / 100,
            minHeight: 8,
            backgroundColor: AppColors.line,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ),
      const SizedBox(width: 8),
      SizedBox(
        width: 32,
        child: Text('$value',
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(color: color, fontWeight: FontWeight.w800, fontSize: 12)),
      ),
    ]);
  }
}

class _AlertRow extends StatelessWidget {
  final Map<String, dynamic> alert;
  const _AlertRow({required this.alert});

  @override
  Widget build(BuildContext context) {
    final cat = (alert['category_bn']?.toString().isNotEmpty == true ? alert['category_bn'] : alert['category_en']) ?? '';
    final loc = (alert['location_bn']?.toString().isNotEmpty == true ? alert['location_bn'] : alert['location_en']) ?? '';
    final risk = alert['risk_level']?.toString() ?? 'medium';
    final dateStr = alert['incident_date']?.toString() ?? '';
    final color = _riskColor(risk);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(cat.toString(),
                style: GoogleFonts.hindSiliguri(
                    color: AppColors.ink, fontWeight: FontWeight.w600, fontSize: 12.5)),
            Text('$loc ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¾ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â· ${_relTime(dateStr)}',
                style: GoogleFonts.hindSiliguri(color: AppColors.ink3, fontSize: 11)),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
          child: Text(risk.toUpperCase(),
              style: GoogleFonts.inter(
                  color: color, fontWeight: FontWeight.w700, fontSize: 9, letterSpacing: 0.4)),
        ),
      ]),
    );
  }

  Color _riskColor(String r) {
    switch (r.toLowerCase()) {
      case 'extreme':
      case 'high':
        return AppColors.red;
      case 'medium':
        return AppColors.amber;
      default:
        return AppColors.green;
    }
  }

  String _relTime(String iso) {
    if (iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso);
      final diff = DateTime.now().difference(dt);
      if (diff.inHours < 1) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}h';
      if (diff.inDays < 30) return '${diff.inDays}d';
      return DateFormat('d MMM').format(dt);
    } catch (_) {
      return '';
    }
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _NavBtn({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.green : AppColors.ink3;
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 3),
          Text(label,
              style: GoogleFonts.inter(
                  color: color,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 10.5)),
        ]),
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  final double height;
  const _Skeleton({required this.height});
  @override
  Widget build(BuildContext context) => Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.line.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(14),
        ),
      );
}

Widget _buildQuickActionCard({
  required IconData icon,
  required String title,
  required String subtitle,
  required Color color,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(18),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: .18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(subtitle),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    ),
  );
}
