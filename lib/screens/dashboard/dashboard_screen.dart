import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/sos_service.dart';
import '../../utils/constants.dart';
import '../../widgets/design_widgets.dart';

class DashboardScreen extends StatefulWidget {
  final void Function(String) onNav;
  const DashboardScreen({super.key, required this.onNav});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  final _api = ApiService();
  final _auth = AuthService();
  final _sos = SosService();

  String _userName = 'User';
  bool _holding = false;
  Timer? _holdTimer;
  double _holdProgress = 0;
  bool _sosSending = false;
  String? _sosResult;
  bool _sosOk = true;

  int _safetyScore = 85;
  int _contactsCount = 0;
  String _location = 'Dhaka';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final u = await _auth.getUser();
    final c = await _api.getContacts();
    if (mounted) {
      setState(() {
        _userName = (u?['name'] ?? 'User').toString();
        _contactsCount = c.length;
      });
    }

    // Try to load real safety index
    try {
      final cities = await _api.getSafetyIndex();
      if (cities.isNotEmpty && mounted) {
        // Pick Dhaka or first city
        final dhaka = cities.firstWhere(
          (c) => (c['city'] ?? '').toString().contains('Dhaka'),
          orElse: () => cities.first,
        );
        setState(() {
          _safetyScore = (dhaka['score'] as num?)?.toInt() ?? 85;
          _location = (dhaka['city'] ?? 'Dhaka').toString();
        });
      }
    } catch (_) {}
  }

  void _startHold() {
    if (_sosSending) return;
    setState(() {
      _holding = true;
      _holdProgress = 0;
    });
    HapticFeedback.lightImpact();
    _holdTimer?.cancel();
    _holdTimer = Timer.periodic(const Duration(milliseconds: 60), (t) {
      if (!mounted || !_holding) {
        t.cancel();
        return;
      }
      setState(() => _holdProgress += 6);
      if (_holdProgress >= 100) {
        t.cancel();
        _triggerSOS();
      }
    });
  }

  void _cancelHold() {
    _holdTimer?.cancel();
    if (mounted && _holdProgress < 100) {
      setState(() {
        _holding = false;
        _holdProgress = 0;
      });
    }
  }

  Future<void> _triggerSOS() async {
    HapticFeedback.heavyImpact();
    if (!mounted) return;
    setState(() {
      _sosSending = true;
      _holding = false;
      _holdProgress = 0;
    });

    final res = await _sos.trigger(method: 'hold_button');

    if (!mounted) return;
    setState(() {
      _sosSending = false;
      _sosResult = res.messageBn;
      _sosOk = res.success;
    });

    Future.delayed(const Duration(seconds: 6), () {
      if (mounted) setState(() => _sosResult = null);
    });
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          _buildHeader(),
          _buildStatusChips(),
          _buildSafetyCard(),
          Expanded(child: Center(child: _buildSOSButton())),
          if (_sosResult != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _sosOk
                      ? AppColors.greenSoft
                      : AppColors.redSoft,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: (_sosOk ? AppColors.green : AppColors.red)
                        .withOpacity(0.3),
                  ),
                ),
                child: Row(children: [
                  Icon(
                    _sosOk ? Icons.check_circle : Icons.warning_amber_rounded,
                    color: _sosOk ? AppColors.green : AppColors.red,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: BnText(_sosResult!,
                        size: 11.5,
                        weight: FontWeight.w600,
                        color: _sosOk ? AppColors.green : AppColors.red),
                  ),
                ]),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(children: [
              Expanded(child: _buildContactsCard()),
              const SizedBox(width: 10),
              Expanded(child: _buildAlertsCard()),
            ]),
          ),
          BottomNavBar(active: 'home', onNav: widget.onNav),
        ]),
      ),
    );
  }

  Widget _buildHeader() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.line),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFCD7DD), Colors.white],
              ),
            ),
            child: const Icon(Icons.person_outline,
                size: 18, color: AppColors.ink2),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const EnText('Good evening,',
                      size: 11,
                      color: AppColors.ink3,
                      weight: FontWeight.w500),
                  EnText(_userName,
                      size: 14, weight: FontWeight.w700),
                ]),
          ),
          IconBtn(
            icon: Icons.notifications_outlined,
            badge: Container(
              width: 7, height: 7,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: AppColors.red),
            ),
            onTap: () {},
          ),
          const SizedBox(width: 8),
          IconBtn(
              icon: Icons.settings_outlined,
              onTap: () => widget.onNav('settings')),
        ]),
      );

  Widget _buildStatusChips() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        child: Row(children: [
          const StatusChip(
              icon: Icons.gps_fixed,
              label: 'GPS Active',
              sub: '±4m',
              ok: true),
          const SizedBox(width: 8),
          const StatusChip(
              icon: Icons.wifi,
              label: 'Synced',
              sub: '0 queued',
              ok: true),
          const SizedBox(width: 8),
          StatusChip(
              icon: Icons.shield_outlined,
              label: 'Guardian',
              sub: '$_contactsCount active',
              tone: AppColors.green),
        ]),
      );

  Widget _buildSafetyCard() {
    final scoreLabel = _safetyScore >= 75
        ? 'SAFE'
        : _safetyScore >= 50
            ? 'CAUTION'
            : 'RISK';
    final scoreColor = _safetyScore >= 75
        ? AppColors.green
        : _safetyScore >= 50
            ? AppColors.amber
            : AppColors.red;
    final scoreBg = _safetyScore >= 75
        ? AppColors.greenSoft
        : _safetyScore >= 50
            ? const Color(0xFFFEF3C7)
            : AppColors.redSoft;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const EnText('AREA SAFETY INDEX',
                        size: 11,
                        weight: FontWeight.w600,
                        color: AppColors.ink3,
                        letterSpacing: 0.4),
                    const SizedBox(height: 4),
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          EnText('$_safetyScore',
                              size: 28,
                              weight: FontWeight.w800,
                              letterSpacing: -0.8,
                              color: scoreColor),
                          const SizedBox(width: 4),
                          const EnText('/100',
                              size: 13,
                              weight: FontWeight.w600,
                              color: AppColors.ink2),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: scoreBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: EnText(scoreLabel,
                                size: 11,
                                weight: FontWeight.w700,
                                color: scoreColor),
                          ),
                        ]),
                    const SizedBox(height: 6),
                    Row(children: [
                      const Icon(Icons.location_on_outlined,
                          size: 11, color: AppColors.ink2),
                      const SizedBox(width: 3),
                      EnText(_location,
                          size: 11, color: AppColors.ink2),
                    ]),
                  ])),
          GaugeMeter(value: _safetyScore.toDouble()),
        ]),
        const SizedBox(height: 12),
        Row(children: const [
          _MetricBox(k: 'Lighting', v: 92),
          SizedBox(width: 6),
          _MetricBox(k: 'Patrol', v: 78),
          SizedBox(width: 6),
          _MetricBox(k: 'Crowd', v: 86),
        ]),
      ]),
    );
  }

  Widget _buildSOSButton() {
    return Stack(alignment: Alignment.center, children: [
      if (!_holding && !_sosSending)
        const PulseRing(color: AppColors.red, size: 220),
      if (!_holding && !_sosSending)
        const PulseRing(
            color: AppColors.red,
            size: 220,
            delay: Duration(milliseconds: 600)),
      Container(
        width: 196, height: 196,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
              color: AppColors.green.withOpacity(0.35), width: 1),
        ),
      ),
      GestureDetector(
        onTapDown: (_) => _startHold(),
        onTapUp: (_) => _cancelHold(),
        onTapCancel: _cancelHold,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 168, height: 168,
          transform: Matrix4.identity()..scale(_holding ? 0.96 : 1.0),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              center: Alignment(-0.4, -0.4),
              colors: [Color(0xFFFF5A6F), AppColors.red],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.red.withOpacity(0.65),
                offset: const Offset(0, 28),
                blurRadius: 60,
                spreadRadius: -18,
              ),
            ],
          ),
          child: Stack(alignment: Alignment.center, children: [
            // Conic progress overlay
            if (_holding)
              SizedBox(
                width: 168, height: 168,
                child: CustomPaint(
                  painter: _SosProgressPainter(_holdProgress),
                ),
              ),
            Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_sosSending) ...[
                    const SizedBox(
                        width: 32, height: 32,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 3)),
                    const SizedBox(height: 6),
                    const EnText('SENDING',
                        size: 12,
                        weight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 2),
                  ] else ...[
                    const EnText('SOS',
                        size: 44,
                        weight: FontWeight.w800,
                        letterSpacing: 2,
                        color: Colors.white,
                        height: 1),
                    const SizedBox(height: 4),
                    const BnText('জরুরি সহায়তা',
                        size: 12,
                        weight: FontWeight.w600,
                        color: Colors.white,
                        height: 1),
                    const SizedBox(height: 4),
                    EnText('HOLD 1.5s',
                        size: 9.5,
                        weight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.85),
                        letterSpacing: 1),
                  ],
                ]),
          ]),
        ),
      ),
    ]);
  }

  Widget _buildContactsCard() {
    return GlassCard(
        onTap: () => widget.onNav('settings'),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: const [
                EnText('QUICK CONTACTS',
                    size: 11,
                    weight: FontWeight.w700,
                    letterSpacing: 0.4),
                Spacer(),
                Icon(Icons.add, size: 14, color: AppColors.ink3),
              ]),
              const SizedBox(height: 8),
              SizedBox(
                height: 28,
                child: _contactsCount == 0
                    ? const EnText('No contacts yet',
                        size: 11, color: AppColors.ink3)
                    : Stack(children: [
                        for (int i = 0;
                            i < (_contactsCount > 3 ? 3 : _contactsCount);
                            i++)
                          Positioned(
                            left: i * 20.0,
                            child: Container(
                              width: 28, height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: [
                                  AppColors.green,
                                  AppColors.red,
                                  const Color(0xFF1F2937)
                                ][i % 3],
                                border: Border.all(
                                    color: Colors.white, width: 2),
                              ),
                              child: const Center(
                                child: Icon(Icons.person,
                                    size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        if (_contactsCount > 3)
                          Positioned(
                            left: 60,
                            child: Container(
                              width: 28, height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                border: Border.all(
                                    color: AppColors.ink3, width: 1),
                              ),
                              child: Center(
                                child: EnText(
                                    '+${_contactsCount - 3}',
                                    size: 10,
                                    weight: FontWeight.w700,
                                    color: AppColors.ink3),
                              ),
                            ),
                          ),
                      ]),
              ),
              const SizedBox(height: 8),
              const EnText('Auto-call on SOS',
                  size: 10, color: AppColors.ink3),
            ]));
  }

  Widget _buildAlertsCard() => GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: const [
          EnText('RECENT ALERTS',
              size: 11, weight: FontWeight.w700, letterSpacing: 0.4),
          Spacer(),
          Icon(Icons.chevron_right, size: 14, color: AppColors.ink3),
        ]),
        const SizedBox(height: 6),
        const _AlertRow(
            tone: AppColors.amber, t: 'Catcalling', sub: 'Mirpur · 2h'),
        const _AlertRow(tone: AppColors.red, t: 'Snatching', sub: 'Karwan · 5h'),
      ]));
}

class _MetricBox extends StatelessWidget {
  final String k;
  final int v;
  const _MetricBox({required this.k, required this.v});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EnText(k.toUpperCase(),
                  size: 9.5,
                  weight: FontWeight.w600,
                  color: AppColors.ink3),
              const SizedBox(height: 4),
              Row(children: [
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.line,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: v / 100,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.green,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                EnText('$v', size: 11, weight: FontWeight.w700),
              ]),
            ]),
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  final Color tone;
  final String t, sub;
  const _AlertRow({required this.tone, required this.t, required this.sub});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(
                color: tone, borderRadius: BorderRadius.circular(3)),
          ),
          const SizedBox(width: 6),
          EnText(t, size: 11.5, weight: FontWeight.w600),
          const Spacer(),
          EnText(sub, size: 10, color: AppColors.ink3),
        ]),
      );
}

// ── Custom progress arc painter ────────────────────────────────────
class _SosProgressPainter extends CustomPainter {
  final double progress; // 0–100
  _SosProgressPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 1;
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final sweep = (progress / 100.0) * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _SosProgressPainter old) =>
      old.progress != progress;
}
