import 'package:flutter/material.dart';
import '../advanced_prototype/advanced_prototype_screen.dart';

class LearningProfileScreen extends StatefulWidget {
  final void Function(String route)? onNav;
  final VoidCallback? onBack;

  const LearningProfileScreen({
    super.key,
    this.onNav,
    this.onBack,
  });

  @override
  State<LearningProfileScreen> createState() => _LearningProfileScreenState();
}

class _LearningProfileScreenState extends State<LearningProfileScreen> {
  String _verificationType = 'women_forum';
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }

    if (widget.onBack != null) {
      widget.onBack!();
      return;
    }

    widget.onNav?.call('dashboard');
  }

  void _submitVerificationRequest() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Verification request saved for review: $_verificationType',
        ),
      ),
    );
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
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: _goBack,
        ),
        title: const Text(
          'Learning & Rights',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _heroCard(primary),
            const SizedBox(height: 14),
            _sectionTitle('Trust Profile'),
            _trustProfileCard(),
            const SizedBox(height: 14),
            _sectionTitle('Know Your Rights'),
            _infoCard(
              icon: Icons.gavel_outlined,
              title: 'Emergency help',
              body: 'If you are in immediate danger, call 999 or trigger SafeHer SOS.',
            ),
            _infoCard(
              icon: Icons.support_agent_outlined,
              title: 'Women and child helpline',
              body: 'Call 109 for women and child protection support in Bangladesh.',
            ),
            _infoCard(
              icon: Icons.balance_outlined,
              title: 'Legal aid support',
              body: 'Use 16430 for national legal aid information and assistance.',
            ),
            _infoCard(
              icon: Icons.security_outlined,
              title: 'Digital harassment evidence',
              body: 'Save screenshots, sender identity, timestamp and links before reporting online abuse.',
            ),
            const SizedBox(height: 14),
            _sectionTitle('Self-defense basics'),
            _infoCard(
              icon: Icons.visibility_outlined,
              title: 'Stay aware',
              body: 'Avoid isolated paths, keep your phone ready and share your route when travelling at night.',
            ),
            _infoCard(
              icon: Icons.directions_run_outlined,
              title: 'Escape first',
              body: 'The goal is to leave the unsafe situation quickly, not to fight unless there is no alternative.',
            ),
            _infoCard(
              icon: Icons.record_voice_over_outlined,
              title: 'Use a strong voice',
              body: 'Say Stop or Help loudly to draw attention and create distance.',
            ),
            const SizedBox(height: 14),
            _sectionTitle('Safety tips'),
            _tipTile('Share your route before travelling through risky areas.'),
            _tipTile('Keep at least two trusted emergency contacts.'),
            _tipTile('Use Evidence Vault metadata to organize proof.'),
            _tipTile('Use quick exit or stealth tools if someone is watching your screen.'),
            const SizedBox(height: 14),
            _sectionTitle('Verification request'),
            _verificationCard(primary),
            const SizedBox(height: 14),
            _sectionTitle('Advanced prototype modules'),
            _infoCard(
              icon: Icons.auto_awesome_outlined,
              title: 'Advanced Safety Modules',
              body: 'Safe Ride, NID verification, officer dispatch, heatmap control, privacy center, audit log, and sensor triggers.',
            ),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AdvancedPrototypeScreen()),
                ),
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open Advanced Safety Modules'),
              ),
            ),            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _heroCard(Color primary) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primary,
            const Color(0xFF7C3AED),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: .20),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.school_outlined, color: Colors.white, size: 34),
          SizedBox(height: 12),
          Text(
            'Learn, prepare, and stay protected',
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Know your rights, practice safety habits, and manage trust profile verification for women-only community access.',
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

  Widget _trustProfileCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _roundIcon(Icons.verified_user_outlined, const Color(0xFF059669)),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Trust score: 35 / 100',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ),
              const Chip(
                label: Text('Unverified'),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Verification helps unlock women-only forum access and increases community trust level.',
            style: TextStyle(color: Color(0xFF5B6475), height: 1.35),
          ),
        ],
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _roundIcon(icon, const Color(0xFF2563EB)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 5),
                Text(
                  body,
                  style: const TextStyle(
                    color: Color(0xFF5B6475),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tipTile(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(13),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Color(0xFF059669)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _verificationCard(Color primary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _verificationType,
            decoration: const InputDecoration(
              labelText: 'Verification type',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: 'women_forum',
                child: Text('Women-only forum access'),
              ),
              DropdownMenuItem(
                value: 'student_id',
                child: Text('Student ID / institution verification'),
              ),
              DropdownMenuItem(
                value: 'community',
                child: Text('Community/sub-admin verification'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _verificationType = value);
              }
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Verification note',
              hintText: 'Example: Requesting verification for women-only community access.',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _submitVerificationRequest,
              icon: const Icon(Icons.send_outlined),
              label: const Text('Submit verification request'),
              style: FilledButton.styleFrom(
                backgroundColor: primary,
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _roundIcon(IconData icon, Color color) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
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
