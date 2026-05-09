import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/api_service.dart';
import '../../utils/constants.dart';

class SosHistoryScreen extends StatefulWidget {
  const SosHistoryScreen({super.key});
  @override
  State<SosHistoryScreen> createState() => _SosHistoryScreenState();
}

class _SosHistoryScreenState extends State<SosHistoryScreen> {
  final _api = ApiService();
  bool _loading = true;
  List<dynamic> _alerts = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _api.getSosHistory();
    if (!mounted) return;
    setState(() {
      _alerts = list;
      _loading = false;
    });
  }

  Future<void> _openOnMap(double lat, double lng) async {
    final uri = Uri.parse('https://www.google.com/maps?q=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'SOS History',
          style: GoogleFonts.inter(
            color: AppColors.ink,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.green,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.green))
            : _alerts.isEmpty
                ? _buildEmpty()
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _alerts.length,
                    itemBuilder: (_, i) => _buildItem(_alerts[i] as Map<String, dynamic>),
                  ),
      ),
    );
  }

  Widget _buildEmpty() => ListView(children: [
        const SizedBox(height: 120),
        Center(
            child: Column(children: [
          Icon(Icons.shield_outlined, size: 64, color: AppColors.ink3.withOpacity(0.5)),
          const SizedBox(height: 12),
          Text('No SOS alerts yet',
              style: GoogleFonts.inter(color: AppColors.ink2, fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 4),
          Text("Stay safe! Your past alerts will appear here.",
              style: GoogleFonts.inter(color: AppColors.ink3, fontSize: 12)),
        ])),
      ]);

  Widget _buildItem(Map<String, dynamic> a) {
    final lat = (a['latitude'] as num?)?.toDouble() ?? 0;
    final lng = (a['longitude'] as num?)?.toDouble() ?? 0;
    final triggeredAt = a['triggered_at']?.toString() ?? '';
    final method = a['trigger_method']?.toString() ?? 'button';
    final status = a['status']?.toString() ?? 'unknown';
    final isOffline = a['is_offline_origin'] == true;
    final delivered = a['contacts_delivered'] ?? 0;
    final total = a['contacts_total'] ?? 0;
    final battery = a['battery_level'];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppColors.redSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield_outlined, color: AppColors.red, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_formatDate(triggeredAt),
                  style: GoogleFonts.inter(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
              const SizedBox(height: 2),
              Row(children: [
                _Tag(label: method, color: AppColors.blue),
                const SizedBox(width: 4),
                if (isOffline) _Tag(label: 'Offline', color: AppColors.amber),
              ]),
            ]),
          ),
          _StatusPill(status: status),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Icon(Icons.location_on_outlined, size: 14, color: AppColors.ink2),
          const SizedBox(width: 4),
          Expanded(
              child: Text(
            '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
            style: GoogleFonts.inter(color: AppColors.ink2, fontSize: 11.5),
          )),
          GestureDetector(
            onTap: () => _openOnMap(lat, lng),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.greenSoft,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('View',
                  style: GoogleFonts.inter(
                      color: AppColors.green,
                      fontWeight: FontWeight.w700,
                      fontSize: 11)),
            ),
          ),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Icon(Icons.people_alt_outlined, size: 13, color: AppColors.ink3),
          const SizedBox(width: 4),
          Text('Notified $delivered / $total contacts',
              style: GoogleFonts.inter(color: AppColors.ink3, fontSize: 11)),
          const Spacer(),
          if (battery != null) ...[
            Icon(Icons.battery_full, size: 13, color: AppColors.ink3),
            const SizedBox(width: 2),
            Text('$battery%',
                style: GoogleFonts.inter(color: AppColors.ink3, fontSize: 11)),
          ],
        ]),
      ]),
    );
  }

  String _formatDate(String iso) {
    if (iso.isEmpty) return '—';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat('d MMM y, h:mm a').format(dt);
    } catch (_) {
      return iso;
    }
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(label.toUpperCase(),
            style: GoogleFonts.inter(
                color: color, fontWeight: FontWeight.w700, fontSize: 9, letterSpacing: 0.4)),
      );
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});
  @override
  Widget build(BuildContext context) {
    final ok = status == 'dispatched' || status == 'resolved';
    final color = ok ? AppColors.green : AppColors.amber;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.inter(
            color: color, fontWeight: FontWeight.w700, fontSize: 9.5, letterSpacing: 0.4),
      ),
    );
  }
}
