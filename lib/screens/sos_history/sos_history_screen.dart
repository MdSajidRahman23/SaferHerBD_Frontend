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

  void _showAlertDetails(Map<String, dynamic> alert) {
    final lat = _toDouble(alert['latitude']);
    final lng = _toDouble(alert['longitude']);
    final address = _clean(alert['address']);
    final id = _clean(alert['id']);
    final status = _clean(alert['status'], fallback: 'unknown');
    final method = _clean(alert['trigger_method'], fallback: 'button');
    final triggeredAt = _clean(alert['triggered_at']);
    final dispatchedAt = _clean(alert['dispatched_at']);
    final createdAt = _clean(alert['created_at']);
    final total = _clean(alert['contacts_total'], fallback: '0');
    final delivered = _clean(alert['contacts_delivered'], fallback: '0');
    final battery = _clean(alert['battery_level']);
    final offline = alert['is_offline_origin'] == true || alert['is_offline_origin'] == 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.72,
        minChildSize: 0.45,
        maxChildSize: 0.92,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(color: AppColors.redSoft, shape: BoxShape.circle),
                  child: const Icon(Icons.shield_outlined, color: AppColors.red, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('SOS Alert Details',
                        style: GoogleFonts.inter(
                            color: AppColors.ink, fontWeight: FontWeight.w800, fontSize: 17)),
                    const SizedBox(height: 2),
                    Text(_formatDate(triggeredAt),
                        style: GoogleFonts.inter(color: AppColors.ink3, fontSize: 12)),
                  ]),
                ),
                _StatusPill(status: status),
              ]),
              const SizedBox(height: 18),
              _DetailCard(children: [
                _DetailRow(icon: Icons.fingerprint, label: 'Alert ID', value: id.isEmpty ? '—' : id),
                _DetailRow(icon: Icons.touch_app_outlined, label: 'Trigger Method', value: method.toUpperCase()),
                _DetailRow(icon: Icons.schedule_outlined, label: 'Triggered At', value: _formatDate(triggeredAt)),
                if (dispatchedAt.isNotEmpty)
                  _DetailRow(icon: Icons.send_outlined, label: 'Dispatched At', value: _formatDate(dispatchedAt)),
                if (createdAt.isNotEmpty)
                  _DetailRow(icon: Icons.history_toggle_off, label: 'Saved At', value: _formatDate(createdAt)),
                _DetailRow(icon: Icons.cloud_off_outlined, label: 'Offline Origin', value: offline ? 'Yes' : 'No'),
              ]),
              const SizedBox(height: 12),
              _DetailCard(children: [
                _DetailRow(
                  icon: Icons.location_on_outlined,
                  label: 'Coordinates',
                  value: lat == null || lng == null
                      ? '—'
                      : '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
                ),
                _DetailRow(icon: Icons.place_outlined, label: 'Address', value: address.isEmpty ? 'Not provided' : address),
                if (lat != null && lng != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _openOnMap(lat, lng),
                        icon: const Icon(Icons.map_outlined, size: 18),
                        label: const Text('Open location in map'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.green,
                          side: const BorderSide(color: AppColors.green),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ),
              ]),
              const SizedBox(height: 12),
              _DetailCard(children: [
                _DetailRow(icon: Icons.people_alt_outlined, label: 'Contacts Notified', value: '$delivered / $total'),
                const _DetailRow(icon: Icons.sms_outlined, label: 'SMS/Push Note', value: 'Saved in app history. External SMS/push depends on Twilio/Firebase configuration.'),
                if (battery.isNotEmpty)
                  _DetailRow(icon: Icons.battery_full_outlined, label: 'Battery', value: '$battery%'),
              ]),
              const SizedBox(height: 16),
              SizedBox(
                height: 46,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Close', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
                    itemBuilder: (_, i) => _buildItem(_asMap(_alerts[i])),
                  ),
      ),
    );
  }

  Widget _buildEmpty() => ListView(children: [
        const SizedBox(height: 120),
        Center(
            child: Column(children: [
          Icon(Icons.shield_outlined, size: 64, color: AppColors.ink3.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text('No SOS alerts yet',
              style: GoogleFonts.inter(color: AppColors.ink2, fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 4),
          Text("Stay safe! Your past alerts will appear here.",
              style: GoogleFonts.inter(color: AppColors.ink3, fontSize: 12)),
        ])),
      ]);

  Widget _buildItem(Map<String, dynamic> a) {
    final lat = _toDouble(a['latitude']) ?? 0;
    final lng = _toDouble(a['longitude']) ?? 0;
    final triggeredAt = a['triggered_at']?.toString() ?? '';
    final method = a['trigger_method']?.toString() ?? 'button';
    final status = a['status']?.toString() ?? 'unknown';
    final isOffline = a['is_offline_origin'] == true || a['is_offline_origin'] == 1;
    final delivered = a['contacts_delivered'] ?? 0;
    final total = a['contacts_total'] ?? 0;
    final battery = a['battery_level'];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showAlertDetails(a),
        child: Container(
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
                decoration: const BoxDecoration(
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
                    if (isOffline) const _Tag(label: 'Offline', color: AppColors.amber),
                  ]),
                ]),
              ),
              _StatusPill(status: status),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: AppColors.ink3, size: 18),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              const Icon(Icons.location_on_outlined, size: 14, color: AppColors.ink2),
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
              const Icon(Icons.people_alt_outlined, size: 13, color: AppColors.ink3),
              const SizedBox(width: 4),
              Text('Notified $delivered / $total contacts',
                  style: GoogleFonts.inter(color: AppColors.ink3, fontSize: 11)),
              const Spacer(),
              if (battery != null) ...[
                const Icon(Icons.battery_full, size: 13, color: AppColors.ink3),
                const SizedBox(width: 2),
                Text('$battery%',
                    style: GoogleFonts.inter(color: AppColors.ink3, fontSize: 11)),
              ],
            ]),
            const SizedBox(height: 6),
            Text('Tap for full alert details',
                style: GoogleFonts.inter(color: AppColors.green, fontWeight: FontWeight.w700, fontSize: 10.5)),
          ]),
        ),
      ),
    );
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.map((key, val) => MapEntry(key.toString(), val));
    return <String, dynamic>{};
  }

  double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  String _clean(dynamic value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty || text.toLowerCase() == 'null') return fallback;
    return text;
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

class _DetailCard extends StatelessWidget {
  final List<Widget> children;
  const _DetailCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(children: children),
      );
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: AppColors.green, size: 17),
          const SizedBox(width: 10),
          SizedBox(
            width: 112,
            child: Text(label,
                style: GoogleFonts.inter(color: AppColors.ink3, fontSize: 11.5, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: SelectableText(value,
                style: GoogleFonts.inter(color: AppColors.ink, fontSize: 12.2, fontWeight: FontWeight.w600)),
          ),
        ]),
      );
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
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
    final ok = status == 'dispatched' || status == 'resolved' || status == 'sent';
    final color = ok ? AppColors.green : AppColors.amber;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
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
