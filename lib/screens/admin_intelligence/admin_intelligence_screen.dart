import 'package:flutter/material.dart';

class AdminIntelligenceScreen extends StatelessWidget {
  const AdminIntelligenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF172033),
        elevation: 0,
        title: const Text('Admin Intelligence', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _hero(),
            const SizedBox(height: 14),
            _section('Community Intelligence'),
            _metricGrid(),
            const SizedBox(height: 14),
            _section('Risk Zone Review'),
            _infoCard(
              Icons.map_outlined,
              'Risk zone control',
              'Review sub-admin and community incident reports, classify high-risk areas, and prepare safer route intelligence.',
              const Color(0xFFDC2626),
            ),
            _infoCard(
              Icons.trending_up_outlined,
              'Community trends',
              'See incident type frequency such as harassment, unsafe areas, stalking, and suspicious activity reports.',
              const Color(0xFF7C3AED),
            ),
            const SizedBox(height: 14),
            _section('Admin Audit & Export'),
            _infoCard(
              Icons.fact_check_outlined,
              'Audit log preview',
              'Track admin actions such as risk review, verification approval, evidence review, and CSV export.',
              const Color(0xFF059669),
            ),
            _infoCard(
              Icons.file_download_outlined,
              'CSV export ready',
              'Export risk zone and community incident summaries for final report, admin review, and project documentation.',
              const Color(0xFF2563EB),
            ),
            const SizedBox(height: 14),
            _section('Demo actions'),
            _actionCard(context),
          ],
        ),
      ),
    );
  }

  Widget _hero() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF111827), Color(0xFF7C3AED)]),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.analytics_outlined, color: Colors.white, size: 34),
          SizedBox(height: 12),
          Text('Admin / Community Intelligence', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900)),
          SizedBox(height: 8),
          Text('Audit logs, risk-zone review, incident trends, and CSV export workflow without paid APIs.', style: TextStyle(color: Colors.white, height: 1.35)),
        ],
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF172033))),
    );
  }

  Widget _metricGrid() {
    final items = [
      ('Pending incidents', 'Review'),
      ('Risk zones', 'Classify'),
      ('Audit log', 'Track'),
      ('CSV report', 'Export'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.55, crossAxisSpacing: 10, mainAxisSpacing: 10),
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: _box(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(item.$1, style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text(item.$2, style: const TextStyle(color: Color(0xFF64748B))),
            ],
          ),
        );
      },
    );
  }

  Widget _infoCard(IconData icon, String title, String body, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: _box(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: color.withValues(alpha: .10), shape: BoxShape.circle),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text(body, style: const TextStyle(color: Color(0xFF64748B), height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _box(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Suggested smoke test', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text('Backend route: /api/admin/intelligence/dashboard\nCSV route: /api/admin/intelligence/export.csv\nUI: risk-zone review, trend summary, audit preview, export ready.', style: TextStyle(color: Color(0xFF64748B), height: 1.4)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Admin intelligence workflow ready for demo.'))),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Mark demo checked'),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _box() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE7EAF1)),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .04), blurRadius: 12, offset: const Offset(0, 6))],
    );
  }
}