import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NativeEmergencyPackScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const NativeEmergencyPackScreen({super.key, this.onBack});

  @override
  State<NativeEmergencyPackScreen> createState() => _NativeEmergencyPackScreenState();
}

class _NativeEmergencyPackScreenState extends State<NativeEmergencyPackScreen> {
  bool _shakeSos = false;
  bool _voiceTrigger = false;
  bool _flashAlert = true;
  bool _localSiren = true;
  bool _autoEscalation = true;

  Timer? _timer;
  int _remainingSeconds = 0;
  bool _safeWalkActive = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _back() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    widget.onBack?.call();
  }

  void _show(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _haptic() async {
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 120));
    await HapticFeedback.mediumImpact();
  }

  Future<void> _localAlarm() async {
    await _haptic();
    await SystemSound.play(SystemSoundType.alert);
    _show('Local alarm test triggered. On phone builds this can be paired with siren, vibration, and flashlight.');
  }

  void _startSafeWalk() {
    _timer?.cancel();
    setState(() {
      _safeWalkActive = true;
      _remainingSeconds = 5 * 60;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() {
          _remainingSeconds = 0;
          _safeWalkActive = false;
        });
        if (_autoEscalation) {
          _show('Safe Walk timer expired. Demo escalation would notify guardian / prepare SOS.');
          _haptic();
        } else {
          _show('Safe Walk timer expired.');
        }
        return;
      }
      setState(() => _remainingSeconds--);
    });

    _show('Safe Walk started for 5 minutes. Use Check In when safe.');
  }

  void _checkInSafe() {
    _timer?.cancel();
    setState(() {
      _safeWalkActive = false;
      _remainingSeconds = 0;
    });
    _show('Safe check-in recorded. Guardian escalation cancelled.');
  }

  void _createOfflineDraft() {
    _show('Offline SOS draft saved locally for demo. Sync when internet returns.');
  }

  String get _timerLabel {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFDC2626);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF172033),
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: _back),
        title: const Text('Native Emergency Pack', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _hero(primary),
            const SizedBox(height: 14),
            _section('Safe Walk check-in'),
            _safeWalkCard(),
            const SizedBox(height: 14),
            _section('Phone emergency actions'),
            _actionCard(
              icon: Icons.campaign_outlined,
              color: const Color(0xFFDC2626),
              title: 'Local siren / vibration test',
              subtitle: 'Free phone-based alarm feedback using haptics and local alert sound.',
              buttonText: 'Test local alarm',
              onTap: _localAlarm,
            ),
            _actionCard(
              icon: Icons.offline_bolt_outlined,
              color: const Color(0xFFEA580C),
              title: 'Offline SOS draft',
              subtitle: 'Save emergency details when internet is weak, then sync later.',
              buttonText: 'Create draft',
              onTap: _createOfflineDraft,
            ),
            _actionCard(
              icon: Icons.flash_on_outlined,
              color: const Color(0xFFF59E0B),
              title: 'Flashlight / strobe signal',
              subtitle: 'No paid API required, but production mobile build needs native flashlight permission/plugin.',
              buttonText: 'Preview strobe workflow',
              onTap: () => _show('Flashlight strobe workflow ready for native mobile implementation.'),
            ),
            _section('Native trigger settings'),
            _switchCard(
              icon: Icons.sensors_outlined,
              title: 'Shake-to-SOS',
              subtitle: 'Enable accelerometer-based trigger design for Android/iOS builds.',
              value: _shakeSos,
              onChanged: (value) => setState(() => _shakeSos = value),
            ),
            _switchCard(
              icon: Icons.keyboard_voice_outlined,
              title: 'Voice trigger / wake word',
              subtitle: 'Privacy-safe emergency voice trigger concept for mobile builds.',
              value: _voiceTrigger,
              onChanged: (value) => setState(() => _voiceTrigger = value),
            ),
            _switchCard(
              icon: Icons.flashlight_on_outlined,
              title: 'Flash alert',
              subtitle: 'Use phone flashlight as an attention signal in emergency mode.',
              value: _flashAlert,
              onChanged: (value) => setState(() => _flashAlert = value),
            ),
            _switchCard(
              icon: Icons.notifications_active_outlined,
              title: 'Local siren enabled',
              subtitle: 'Allow local audible/haptic alarm feedback during emergency mode.',
              value: _localSiren,
              onChanged: (value) => setState(() => _localSiren = value),
            ),
            _switchCard(
              icon: Icons.warning_amber_outlined,
              title: 'Missed check-in auto escalation',
              subtitle: 'Prepare guardian/SOS escalation when Safe Walk timer expires.',
              value: _autoEscalation,
              onChanged: (value) => setState(() => _autoEscalation = value),
            ),
            const SizedBox(height: 14),
            _section('Production notes'),
            _note('Power-button shortcuts cannot be reliably captured by normal third-party apps.'),
            _note('Shake, flashlight, background location, and wake word detection need native mobile wiring.'),
            _note('No paid services are required for the demo workflows in this screen.'),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _hero(Color primary) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFDC2626), Color(0xFF7C2D12)]),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: primary.withValues(alpha: .20), blurRadius: 18, offset: const Offset(0, 10))],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.phone_android_outlined, color: Colors.white, size: 34),
          SizedBox(height: 12),
          Text('Phone-native safety without paid APIs', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900)),
          SizedBox(height: 8),
          Text('Safe Walk timer, local alarm, offline SOS draft, shake trigger settings, voice trigger settings, and flashlight workflow for mobile builds.', style: TextStyle(color: Colors.white, height: 1.35)),
        ],
      ),
    );
  }

  Widget _safeWalkCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.directions_walk_outlined, color: Color(0xFFDC2626)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _safeWalkActive ? 'Safe Walk active: $_timerLabel' : 'No active Safe Walk timer',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Start a check-in timer before travelling. If the timer expires, the app can prepare guardian/SOS escalation.',
            style: TextStyle(color: Color(0xFF5B6475), height: 1.35),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _startSafeWalk,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start 5 min'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _safeWalkActive ? _checkInSafe : null,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Check in'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF172033))),
    );
  }

  Widget _actionCard({required IconData icon, required Color color, required String title, required String subtitle, required String buttonText, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _roundIcon(icon, color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 5),
                    Text(subtitle, style: const TextStyle(color: Color(0xFF5B6475), height: 1.35)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(onPressed: onTap, icon: const Icon(Icons.arrow_forward), label: Text(buttonText)),
          ),
        ],
      ),
    );
  }

  Widget _switchCard({required IconData icon, required String title, required String subtitle, required bool value, required ValueChanged<bool> onChanged}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          _roundIcon(icon, const Color(0xFFDC2626)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Color(0xFF5B6475), height: 1.35)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _note(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF2563EB)),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(height: 1.35))),
        ],
      ),
    );
  }

  Widget _roundIcon(IconData icon, Color color) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(color: color.withValues(alpha: .10), shape: BoxShape.circle),
      child: Icon(icon, color: color),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE7EAF1)),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .04), blurRadius: 12, offset: const Offset(0, 6))],
    );
  }
}