import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/sos_service.dart';
import '../../services/api_service.dart';
import '../../widgets/gov_widgets.dart';
import '../../utils/constants.dart';

class SosScreen extends StatefulWidget {
  const SosScreen({super.key});
  @override State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> with TickerProviderStateMixin {
  final _sosService = SosService();
  final _api        = ApiService();

  String _phase = 'idle';   // idle | countdown | sending | sent
  int    _count = 5;
  Timer? _timer;
  String _resultMsg = '';
  double? _latencyMs;
  bool _lastWasOffline = false;
  bool _lastSuccess = true;
  List<dynamic> _contacts = [];

  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final c = await _api.getContacts();
    if (mounted) setState(() => _contacts = c);
  }

  void _startCountdown() {
    HapticFeedback.heavyImpact();
    setState(() { _phase = 'countdown'; _count = 5; });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_count > 1) {
        setState(() => _count--);
        HapticFeedback.mediumImpact();
      } else {
        t.cancel();
        _triggerSOS();
      }
    });
  }

  void _cancel() {
    _timer?.cancel();
    setState(() { _phase = 'idle'; _count = 5; });
  }

  Future<void> _triggerSOS() async {
    setState(() => _phase = 'sending');
    final result = await _sosService.trigger(method: 'button');
    if (mounted) {
      HapticFeedback.heavyImpact();
      setState(() {
        _phase = 'sent';
        _resultMsg = result.messageBn;
        _latencyMs = result.latencyMs;
        _lastWasOffline = result.wasOffline;
        _lastSuccess = result.success;
      });
      Future.delayed(const Duration(seconds: 8), () {
        if (mounted) setState(() => _phase = 'idle');
      });
    }
  }

  @override void dispose() {
    _timer?.cancel(); _pulseCtrl.dispose(); super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(children: [
        const HeroHeader(
          title: 'Emergency SOS',
          subtitle: 'জরুরি সতর্কতা',
        ),
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
          child: Column(children: [

            // SOS button
            _buildSOSButton(),
            const SizedBox(height: 14),

            // Status text
            if (_phase == 'idle')
              Text('চাপুন ও জরুরি সাহায্য পান',
                  style: GoogleFonts.hindSiliguri(
                      color: AppColors.t2, fontSize: 13)),
            if (_phase == 'countdown')
              Text('বাতিল করতে আবার চাপুন',
                  style: GoogleFonts.hindSiliguri(
                      color: AppColors.r, fontSize: 13, fontWeight: FontWeight.w600)),
            if (_phase == 'sending')
              Text('সংকেত পাঠানো হচ্ছে...',
                  style: GoogleFonts.hindSiliguri(
                      color: AppColors.t2, fontSize: 13)),
            if (_phase == 'sent') _buildSentCard(),

            const SizedBox(height: 18),

            // Offline badge
            Center(child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.08),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.wifi_off_rounded, size: 14, color: AppColors.gold),
                SizedBox(width: 6),
                Text('Store offline & retry — NFR-1 guaranteed',
                    style: TextStyle(color: AppColors.gold,
                        fontSize: 11, fontWeight: FontWeight.w500)),
              ]),
            )),
            const SizedBox(height: 18),

            // Contacts
            const SectionTitle(en: 'Emergency Contacts', bn: 'জরুরি যোগাযোগ'),
            const SizedBox(height: 8),
            if (_contacts.isEmpty)
              const _NoContactsCard()
            else
              ..._contacts.take(3).toList()
                  .map((c) => _ContactTile(contact: Map.from(c is Map ? c : {}))),
            const SizedBox(height: 18),

            // Trigger methods
            const SectionTitle(en: 'SOS Trigger Methods', bn: 'সক্রিয় করার পদ্ধতি'),
            const SizedBox(height: 8),
            const Row(children: [
              _MethodBox(Icons.touch_app_rounded, 'Button',    'এই বোতাম'),
              SizedBox(width: 8),
              _MethodBox(Icons.vibration_rounded, 'Shake 3x',  'ফোন ঝাঁকুন'),
              SizedBox(width: 8),
              _MethodBox(Icons.pin_outlined,      'Wrong PIN', 'ভুল পিন'),
            ]),
            const SizedBox(height: 16),
            const GovFooter(),
          ]),
        )),
      ]),
    );
  }

  Widget _buildSOSButton() {
    return SizedBox(width: 240, height: 240,
      child: Stack(alignment: Alignment.center, children: [
        // Pulse rings
        if (_phase == 'idle' || _phase == 'countdown')
          ...List.generate(3, (i) => AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) {
              final scale = 1.0 + (_pulseCtrl.value * 0.08 * (i + 1));
              final opacity = (0.18 - i * 0.05).clamp(0.0, 1.0);
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 150.0 + i * 22, height: 150.0 + i * 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.r.withValues(alpha: opacity * 2),
                      width: 1.5,
                    ),
                  ),
                ),
              );
            },
          )),

        GestureDetector(
          onTap: _phase == 'idle' ? _startCountdown :
                 _phase == 'countdown' ? _cancel : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 150, height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: _phase == 'sent'
                    ? (_lastWasOffline
                        ? [AppColors.gold, AppColors.orange]
                        : _lastSuccess
                            ? [AppColors.gl, AppColors.g]
                            : [AppColors.rl, AppColors.r])
                    : [AppColors.rl, AppColors.r],
              ),
              boxShadow: [BoxShadow(
                color: (_phase == 'sent'
                        ? (_lastWasOffline ? AppColors.gold : (_lastSuccess ? AppColors.g : AppColors.r))
                        : AppColors.r)
                    .withValues(alpha: 0.4),
                blurRadius: 40, spreadRadius: 4,
              )],
            ),
            child: _buildButtonContent(),
          ),
        ),
      ]),
    );
  }

  Widget _buildButtonContent() {
    if (_phase == 'countdown') {
      return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('$_count', style: GoogleFonts.dmSans(
            color: Colors.white, fontSize: 56,
            fontWeight: FontWeight.w800, height: 1)),
        Text('সেকেন্ড', style: GoogleFonts.hindSiliguri(
            color: Colors.white70, fontSize: 13)),
      ]);
    }
    if (_phase == 'sending') {
      return const CircularProgressIndicator(color: Colors.white, strokeWidth: 3);
    }
    if (_phase == 'sent') {
      final icon = _lastWasOffline
          ? Icons.cloud_done_rounded
          : _lastSuccess
              ? Icons.check_circle_rounded
              : Icons.error_rounded;
      final label = _lastWasOffline ? 'QUEUED' : (_lastSuccess ? 'SENT' : 'FAILED');
      return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: Colors.white, size: 50),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.dmSans(
            color: Colors.white, fontSize: 18,
            fontWeight: FontWeight.w800, letterSpacing: 2)),
      ]);
    }
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 46),
      const SizedBox(height: 2),
      Text('SOS', style: GoogleFonts.dmSans(
          color: Colors.white, fontSize: 28,
          fontWeight: FontWeight.w800, letterSpacing: 3)),
      Text('চাপুন', style: GoogleFonts.hindSiliguri(
          color: Colors.white70, fontSize: 13)),
    ]);
  }

  Widget _buildSentCard() {
    final c = _lastWasOffline ? AppColors.gold : (_lastSuccess ? AppColors.g : AppColors.r);
    final prefix = _lastWasOffline ? 'Queued offline' : (_lastSuccess ? 'Delivered to server' : 'Not sent');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.08),
          border: Border.all(color: c.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$prefix — $_resultMsg', style: GoogleFonts.hindSiliguri(
              color: c, fontSize: 13, fontWeight: FontWeight.w600)),
          if (_latencyMs != null) ...[
            const SizedBox(height: 6),
            Text('⚡ ${_latencyMs!.toStringAsFixed(0)}ms — NFR-1 ✓',
                style: TextStyle(color: c, fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ]),
      ),
    );
  }
}

class _NoContactsCard extends StatelessWidget {
  const _NoContactsCard();
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.gold.withValues(alpha: 0.08),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          const Icon(Icons.person_add_alt_1_rounded, color: AppColors.gold, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(
            'কোনো জরুরি যোগাযোগ যোগ করা নেই। Settings থেকে trusted contacts যোগ করুন।',
            style: GoogleFonts.hindSiliguri(
              color: AppColors.t2,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          )),
        ]),
      );
}

class _ContactTile extends StatelessWidget {
  final Map contact;
  const _ContactTile({required this.contact});
  @override Widget build(BuildContext context) {
    final name = contact['name'] as String? ?? '?';
    final rel  = contact['relation'] as String? ?? '';
    final pri  = (contact['priority_order'] as num?)?.toInt() ?? 1;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        CircleAvatar(radius: 18,
            backgroundColor: AppColors.g.withValues(alpha: 0.12),
            child: Text(name.isEmpty ? '?' : name[0].toUpperCase(),
                style: const TextStyle(color: AppColors.g,
                    fontWeight: FontWeight.w700))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: GoogleFonts.dmSans(
              color: AppColors.t1, fontWeight: FontWeight.w600, fontSize: 13)),
          Text(rel, style: GoogleFonts.hindSiliguri(
              color: AppColors.t3, fontSize: 11)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.g.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('P$pri',
              style: const TextStyle(color: AppColors.g,
                  fontSize: 11, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }
}

class _MethodBox extends StatelessWidget {
  final IconData icon; final String label, labelBn;
  const _MethodBox(this.icon, this.label, this.labelBn);
  @override Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(children: [
      Icon(icon, color: AppColors.r, size: 22),
      const SizedBox(height: 4),
      Text(label, style: GoogleFonts.dmSans(
          color: AppColors.t1, fontSize: 11, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center),
      Text(labelBn, style: GoogleFonts.hindSiliguri(
          color: AppColors.t3, fontSize: 10),
          textAlign: TextAlign.center),
    ]),
  ));
}
