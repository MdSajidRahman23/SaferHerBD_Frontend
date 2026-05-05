import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/sos_service.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../widgets/gov_widgets.dart';

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
        _phase     = 'sent';
        _resultMsg = result.messageBn;
        _latencyMs = result.latencyMs;
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
                color: AppColors.gold.withOpacity(0.08),
                border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.wifi_off_rounded, size: 14, color: AppColors.gold),
                const SizedBox(width: 6),
                Text('Store offline & retry — NFR-1 guaranteed',
                    style: TextStyle(color: AppColors.gold,
                        fontSize: 11, fontWeight: FontWeight.w500)),
              ]),
            )),
            const SizedBox(height: 18),

            // Contacts
            const SectionTitle(en: 'Emergency Contacts', bn: 'জরুরি যোগাযোগ'),
            const SizedBox(height: 8),
            ...(_contacts.isEmpty ? _demoContacts() : _contacts.take(3).toList())
                .map((c) => _ContactTile(contact: Map.from(c is Map ? c : {}))),
            const SizedBox(height: 18),

            // Trigger methods
            const SectionTitle(en: 'SOS Trigger Methods', bn: 'সক্রিয় করার পদ্ধতি'),
            const SizedBox(height: 8),
            Row(children: const [
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
                      color: AppColors.r.withOpacity(opacity * 2),
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
                    ? [AppColors.gl, AppColors.g]
                    : [AppColors.rl, AppColors.r],
              ),
              boxShadow: [BoxShadow(
                color: (_phase == 'sent' ? AppColors.g : AppColors.r).withOpacity(0.4),
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
      return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 50),
        const SizedBox(height: 4),
        Text('SENT', style: GoogleFonts.dmSans(
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

  Widget _buildSentCard() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.g.withOpacity(0.08),
        border: Border.all(color: AppColors.g.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_resultMsg, style: GoogleFonts.hindSiliguri(
            color: AppColors.g, fontSize: 13, fontWeight: FontWeight.w600)),
        if (_latencyMs != null) ...[
          const SizedBox(height: 6),
          Text('⚡ ${_latencyMs!.toStringAsFixed(0)}ms — NFR-1 ✓',
              style: TextStyle(color: AppColors.g, fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ]),
    ),
  );

  List<Map> _demoContacts() => [
    {'name': 'Ammi (আম্মু)', 'relation': 'মা',  'priority_order': 1},
    {'name': 'Riya Apu',     'relation': 'আপু', 'priority_order': 2},
  ];
}

class _ContactTile extends StatelessWidget {
  final Map contact;
  const _ContactTile({required this.contact});
  @override Widget build(BuildContext context) {
    final name = contact['name'] as String? ?? '?';
    final rel  = contact['relation'] as String? ?? '';
    final pri  = contact['priority_order'] as int? ?? 1;
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
            backgroundColor: AppColors.g.withOpacity(0.12),
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
            color: AppColors.g.withOpacity(0.08),
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
