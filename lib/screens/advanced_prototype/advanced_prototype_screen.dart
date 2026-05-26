import 'package:flutter/material.dart';
import '../offline_safety/offline_safety_screen.dart';
import '../admin_intelligence/admin_intelligence_screen.dart';
import '../evidence_vault_plus/evidence_vault_plus_screen.dart';
import '../native_emergency/native_emergency_pack_screen.dart';
import '../guardian_tracking/guardian_tracking_screen.dart';

class AdvancedPrototypeScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const AdvancedPrototypeScreen({super.key, this.onBack});

  @override
  State<AdvancedPrototypeScreen> createState() => _AdvancedPrototypeScreenState();
}

class _AdvancedPrototypeScreenState extends State<AdvancedPrototypeScreen> {
  bool _shakeSos = false;
  bool _voiceTrigger = false;
  bool _quickExit = true;

  void _back() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    widget.onBack?.call();
  }

  void _demo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF7C3AED);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF172033),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _back,
        ),
        title: const Text(
          'Advanced Safety Modules',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
          const _Sprint13GuardianTrackingCard(),
            _hero(primary),
            const SizedBox(height: 14),
            _actionCard(
              icon: Icons.offline_bolt_outlined,
              color: const Color(0xFF0F766E),
              title: 'Offline Safety Kit',
              subtitle: 'Emergency message templates, safety card, helpline checklist and manual phone-share workflow without paid APIs.',
              buttonText: 'Open offline kit',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const OfflineSafetyScreen()),
              ),
            ),
            _actionCard(
              icon: Icons.analytics_outlined,
              color: const Color(0xFF111827),
              title: 'Admin Intelligence',
              subtitle: 'Risk-zone review, community trends, audit log preview and CSV export workflow without paid APIs.',
              buttonText: 'Open admin intelligence',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AdminIntelligenceScreen()),
              ),
            ),
            _actionCard(
              icon: Icons.lock_outline,
              color: const Color(0xFF7C3AED),
              title: 'Evidence Vault Plus',
              subtitle: 'PIN lock, metadata, timestamp, checksum preview, export summary and native capture workflow without paid APIs.',
              buttonText: 'Open evidence vault plus',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EvidenceVaultPlusScreen()),
              ),
            ),
            _actionCard(
              icon: Icons.phone_android_outlined,
              color: const Color(0xFFDC2626),
              title: 'Native Emergency Pack',
              subtitle: 'Safe Walk timer, local alarm, offline SOS draft, shake/voice settings, vibration and flashlight workflow without paid APIs.',
              buttonText: 'Open native emergency pack',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NativeEmergencyPackScreen()),
              ),
            ),
            _section('Prototype features added for final scope coverage'),
            _actionCard(
              icon: Icons.directions_car_filled_outlined,
              color: const Color(0xFF0EA5E9),
              title: 'Safe Ride',
              subtitle: 'Verified ride request workflow for future female driver/operator integration.',
              buttonText: 'Create demo ride request',
              onTap: () => _demo('Safe Ride demo request recorded.'),
            ),
            _actionCard(
              icon: Icons.badge_outlined,
              color: const Color(0xFF059669),
              title: 'NID / Trust Verification',
              subtitle: 'Verification request workflow for admin review. Real NID API is future production scope.',
              buttonText: 'Request verification',
              onTap: () => _demo('Verification request saved for admin review.'),
            ),
            _actionCard(
              icon: Icons.local_police_outlined,
              color: const Color(0xFFDC2626),
              title: 'Officer Dispatch',
              subtitle: 'Admin-side dispatch assignment concept for emergency response coordination.',
              buttonText: 'View dispatch design',
              onTap: () => _demo('Officer dispatch design is ready for admin workflow expansion.'),
            ),
            _actionCard(
              icon: Icons.map_outlined,
              color: const Color(0xFFF59E0B),
              title: 'Heatmap & Zone Control',
              subtitle: 'Risk zone control concept using approved incidents and route intelligence.',
              buttonText: 'Preview zone controls',
              onTap: () => _demo('Heatmap and zone control module documented for production.'),
            ),
            _section('Device safety controls'),
            _switchCard(
              title: 'Shake-to-SOS trigger',
              subtitle: 'Native mobile sensor wiring planned for production builds.',
              value: _shakeSos,
              onChanged: (value) => setState(() => _shakeSos = value),
            ),
            _switchCard(
              title: 'Voice trigger / wake word',
              subtitle: 'Privacy-safe voice trigger design for future native integration.',
              value: _voiceTrigger,
              onChanged: (value) => setState(() => _voiceTrigger = value),
            ),
            _switchCard(
              title: 'Quick Exit enabled',
              subtitle: 'Emergency screen-exit behavior stays enabled by default.',
              value: _quickExit,
              onChanged: (value) => setState(() => _quickExit = value),
            ),
            _section('Governance and privacy'),
            _actionCard(
              icon: Icons.privacy_tip_outlined,
              color: const Color(0xFF2563EB),
              title: 'Privacy Center',
              subtitle: 'Data access, correction, and deletion request workflow for future compliance.',
              buttonText: 'Create privacy request',
              onTap: () => _demo('Privacy request queued for review.'),
            ),
            _actionCard(
              icon: Icons.fact_check_outlined,
              color: const Color(0xFF6D28D9),
              title: 'Admin Audit Log',
              subtitle: 'Traceable admin actions for SOS, roles, verification, incidents, and case review.',
              buttonText: 'Preview audit log',
              onTap: () => _demo('Audit log preview ready.'),
            ),
            _actionCard(
              icon: Icons.support_agent_outlined,
              color: const Color(0xFF0891B2),
              title: 'Helpline Operator Directory',
              subtitle: 'Managed counsellor/operator directory for production support workflow.',
              buttonText: 'View operator workflow',
              onTap: () => _demo('Helpline operator workflow ready for expansion.'),
            ),
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
        gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF2563EB)]),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: primary.withValues(alpha: .20), blurRadius: 18, offset: const Offset(0, 10)),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Sprint13GuardianTrackingCard(),
          Icon(Icons.auto_awesome_outlined, color: Colors.white, size: 34),
          SizedBox(height: 12),
          Text('Advanced prototype coverage', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900)),
          SizedBox(height: 8),
          Text('Safe Ride, NID verification, officer dispatch, heatmap control, privacy center, audit log, and sensor-trigger concepts are captured for final product scope.', style: TextStyle(color: Colors.white, height: 1.35)),
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
          const _Sprint13GuardianTrackingCard(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          const _Sprint13GuardianTrackingCard(),
              _roundIcon(icon, color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
          const _Sprint13GuardianTrackingCard(),
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

  Widget _switchCard({required String title, required String subtitle, required bool value, required ValueChanged<bool> onChanged}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          const _Sprint13GuardianTrackingCard(),
          const Icon(Icons.sensors_outlined, color: Color(0xFF7C3AED)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          const _Sprint13GuardianTrackingCard(),
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
class _Sprint13GuardianTrackingCard extends StatelessWidget {
  const _Sprint13GuardianTrackingCard();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GuardianTrackingScreen())),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE7EAF1)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .04), blurRadius: 12, offset: const Offset(0, 6))],
        ),
        child: const Row(
          children: [
          _Sprint13GuardianTrackingCard(),
            Icon(Icons.share_location_outlined, color: Color(0xFF2563EB), size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
          _Sprint13GuardianTrackingCard(),
                  Text('Guardian Live Tracking', style: TextStyle(fontWeight: FontWeight.w900)),
                  SizedBox(height: 4),
                  Text('Safe Walk timer, check-ins, last location and missed check-in escalation'),
                ],
              ),
            ),
            Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
