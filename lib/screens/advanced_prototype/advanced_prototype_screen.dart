import 'package:flutter/material.dart';

import '../offline_safety/offline_safety_screen.dart';
import '../guardian_tracking/guardian_tracking_screen.dart';
import '../evidence_vault_plus/evidence_vault_plus_screen.dart';
import '../admin_intelligence/admin_intelligence_screen.dart';

class AdvancedPrototypeScreen extends StatefulWidget {
  final void Function(String route)? onNav;
  final VoidCallback? onBack;

  const AdvancedPrototypeScreen({
    super.key,
    this.onNav,
    this.onBack,
  });

  @override
  State<AdvancedPrototypeScreen> createState() => _AdvancedPrototypeScreenState();
}

class _AdvancedPrototypeScreenState extends State<AdvancedPrototypeScreen> {
  void _goBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    if (widget.onBack != null) {
      widget.onBack!();
      return;
    }
    widget.onNav?.call('learning');
  }

  void _openPage(Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  void _showUnavailable(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$title screen is not available in this build.')),
    );
  }

  void _showConcept(String title) {
    final details = <String, String>{
      'Safe Ride': 'Demo workflow for verified ride booking, female-driver preference, route safety tracking and emergency contact sharing.',
      'NID / Trust Verification': 'Concept workflow for identity/trust verification, women-only access review and admin approval readiness.',
      'Privacy Center': 'Privacy workflow for consent, local-first data control, data review and future deletion/export requests.',
      'Shake-to-SOS': 'Android sensor-based emergency trigger concept. Full background trigger requires native mobile permission handling.',
      'Voice Trigger': 'Emergency wake-word concept for hands-free safety activation. Production mode needs careful privacy and battery handling.',
      'Admin Audit Preview': 'Admin accountability concept for action history, moderation tracking, export and future tamper-resistant audit logs.',
    };

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF172033),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  details[title] ?? 'This advanced safety workflow is available as a demo concept for future production integration.',
                  style: const TextStyle(
                    color: Color(0xFF5B6475),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Got it'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF172033),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: _goBack,
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
            _heroCard(),
            const SizedBox(height: 14),
            _sectionTitle('Phone-native and offline safety'),
            _moduleCard(
              icon: Icons.phone_android_outlined,
              color: const Color(0xFFEF4444),
              title: 'Native Emergency Pack',
              subtitle: 'Safe Walk timer, local alarm, vibration, flash alert, shake and voice trigger settings.',
              onTap: () => _showUnavailable('Native Emergency Pack'),
            ),
            _moduleCard(
              icon: Icons.wifi_off_outlined,
              color: const Color(0xFFF59E0B),
              title: 'Offline Safety Kit',
              subtitle: 'Copy-ready SOS messages, offline safety card, helpline checklist and manual share workflow.',
              onTap: () => _openPage(const OfflineSafetyScreen()),
            ),
            _moduleCard(
              icon: Icons.supervisor_account_outlined,
              color: const Color(0xFF059669),
              title: 'Guardian Live Tracking',
              subtitle: 'Consent-based Safe Walk journey, check-in, missed check-in and last known location flow.',
              onTap: () => _openPage(const GuardianTrackingScreen()),
            ),
            _moduleCard(
              icon: Icons.folder_copy_outlined,
              color: const Color(0xFF2563EB),
              title: 'Evidence Vault Plus',
              subtitle: 'PIN policy, metadata, timestamp, location label, checksum and export summary workflow.',
              onTap: () => _openPage(const EvidenceVaultPlusScreen()),
            ),
            _moduleCard(
              icon: Icons.admin_panel_settings_outlined,
              color: const Color(0xFF7C3AED),
              title: 'Admin Intelligence',
              subtitle: 'Risk-zone review, community trends, audit preview and CSV export readiness.',
              onTap: () => _openPage(const AdminIntelligenceScreen()),
            ),
            const SizedBox(height: 16),
            _sectionTitle('Prototype coverage concepts'),
            _conceptCard(
              icon: Icons.local_taxi_outlined,
              color: const Color(0xFF0EA5E9),
              title: 'Safe Ride',
              subtitle: 'Verified ride booking concept with female-driver workflow and safety tracking readiness.',
            ),
            _conceptCard(
              icon: Icons.badge_outlined,
              color: const Color(0xFF10B981),
              title: 'NID / Trust Verification',
              subtitle: 'Trust verification request concept for women-only access and safer community participation.',
            ),
            _conceptCard(
              icon: Icons.privacy_tip_outlined,
              color: const Color(0xFF6366F1),
              title: 'Privacy Center',
              subtitle: 'Privacy request, data review, local-first safety and consent-based control concept.',
            ),
            _conceptCard(
              icon: Icons.vibration_outlined,
              color: const Color(0xFFEF4444),
              title: 'Shake-to-SOS',
              subtitle: 'Phone sensor trigger setting concept for emergency activation on Android devices.',
            ),
            _conceptCard(
              icon: Icons.record_voice_over_outlined,
              color: const Color(0xFFF97316),
              title: 'Voice Trigger',
              subtitle: 'Emergency wake-word setting concept for hands-free safety activation.',
            ),
            _conceptCard(
              icon: Icons.receipt_long_outlined,
              color: const Color(0xFF7C3AED),
              title: 'Admin Audit Preview',
              subtitle: 'Admin action history and accountability preview for safety operations.',
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _heroCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF172033), Color(0xFF2563EB)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .12),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.dashboard_customize_outlined, color: Colors.white, size: 34),
          SizedBox(height: 12),
          Text(
            'Advanced prototype modules',
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'SafeHerBD extended safety workflows: native emergency tools, offline safety kit, guardian tracking, evidence vault and admin intelligence.',
            style: TextStyle(color: Colors.white, height: 1.35),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w900,
          color: Color(0xFF172033),
        ),
      ),
    );
  }

  Widget _moduleCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: _cardDecoration(),
          child: Row(
            children: [
              _roundIcon(icon, color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Color(0xFF5B6475), height: 1.35),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF64748B)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _conceptCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => _showConcept(title),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: _cardDecoration(),
          child: Row(
            children: [
              _roundIcon(icon, color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Color(0xFF5B6475), height: 1.35),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.info_outline, color: Color(0xFF64748B)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roundIcon(IconData icon, Color color) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE7EAF1)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .04),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
}
