import 'package:flutter/material.dart';

class GuardianTrackingScreen extends StatefulWidget {
  const GuardianTrackingScreen({super.key});

  @override
  State<GuardianTrackingScreen> createState() => _GuardianTrackingScreenState();
}

class _GuardianTrackingScreenState extends State<GuardianTrackingScreen> {
  bool _journeyActive = false;
  int _checkInMinutes = 15;
  String _status = 'Ready';

  void _startJourney() {
    setState(() {
      _journeyActive = true;
      _status = 'Safe Walk started. Next check-in in $_checkInMinutes minutes.';
    });
    _toast(_status);
  }

  void _checkIn() {
    setState(() => _status = 'Safe check-in recorded. Guardian remains updated.');
    _toast(_status);
  }

  void _missedCheckIn() {
    setState(() => _status = 'Missed check-in escalation ready for guardian alert.');
    _toast(_status);
  }

  void _endJourney() {
    setState(() {
      _journeyActive = false;
      _status = 'Journey ended safely.';
    });
    _toast(_status);
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF2563EB);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF172033),
        elevation: 0,
        title: const Text('Guardian Live Tracking', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _hero(primary),
          const SizedBox(height: 14),
          _statusCard(),
          const SizedBox(height: 14),
          _timerCard(primary),
          const SizedBox(height: 14),
          _actionGrid(primary),
          const SizedBox(height: 14),
          _infoCard(
            icon: Icons.privacy_tip_outlined,
            title: 'Consent-based tracking',
            body: 'Location sharing is journey-based and time-limited. The user can end tracking anytime.',
          ),
          _infoCard(
            icon: Icons.map_outlined,
            title: 'Guardian map view ready',
            body: 'Backend stores latest safe-walk location, check-ins, and missed check-in escalation state.',
          ),
          _infoCard(
            icon: Icons.warning_amber_outlined,
            title: 'Missed check-in escalation',
            body: 'If the user misses a check-in, the journey can be marked for guardian alert or SOS follow-up.',
          ),
        ],
      ),
    );
  }

  Widget _hero(Color primary) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF7C3AED)]),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: primary.withValues(alpha: .18), blurRadius: 18, offset: const Offset(0, 10))],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.share_location_outlined, color: Colors.white, size: 34),
          SizedBox(height: 12),
          Text('Share your journey safely', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900)),
          SizedBox(height: 8),
          Text('Start a Safe Walk session, check in on time, and keep guardians updated with consent-based tracking.', style: TextStyle(color: Colors.white, height: 1.35)),
        ],
      ),
    );
  }

  Widget _statusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Icon(_journeyActive ? Icons.directions_walk : Icons.shield_outlined, color: _journeyActive ? Colors.green : Colors.blue),
          const SizedBox(width: 12),
          Expanded(child: Text(_status, style: const TextStyle(fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }

  Widget _timerCard(Color primary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Check-in timer', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 8),
          Slider(
            value: _checkInMinutes.toDouble(),
            min: 5,
            max: 60,
            divisions: 11,
            label: '$_checkInMinutes min',
            onChanged: (value) => setState(() => _checkInMinutes = value.round()),
          ),
          Text('Next check-in every $_checkInMinutes minutes', style: const TextStyle(color: Color(0xFF5B6475))),
        ],
      ),
    );
  }

  Widget _actionGrid(Color primary) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _button(primary, Icons.play_arrow_outlined, 'Start Safe Walk', _startJourney),
        _button(const Color(0xFF059669), Icons.check_circle_outline, 'I am safe', _checkIn),
        _button(const Color(0xFFF97316), Icons.notification_important_outlined, 'Missed check-in', _missedCheckIn),
        _button(const Color(0xFFDC2626), Icons.stop_circle_outlined, 'End journey', _endJourney),
      ],
    );
  }

  Widget _button(Color color, IconData icon, String label, VoidCallback onTap) {
    return SizedBox(
      width: 165,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label, textAlign: TextAlign.center),
        style: FilledButton.styleFrom(backgroundColor: color, padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10)),
      ),
    );
  }

  Widget _infoCard({required IconData icon, required String title, required String body}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF2563EB)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 5),
                Text(body, style: const TextStyle(color: Color(0xFF5B6475), height: 1.35)),
              ],
            ),
          ),
        ],
      ),
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