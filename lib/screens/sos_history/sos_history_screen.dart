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

  Future<void> _callNumber(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Call $number manually from your phone.')),
      );
    }
  }

  Future<void> _markSafeFromHistory(String id, BuildContext sheetContext) async {
    final res = await _api.resolveSos(sosId: id, note: 'Marked safe from SOS history.');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(res['message']?.toString() ?? 'Safety check saved')),
    );
    if (sheetContext.mounted) {
      Navigator.of(sheetContext).pop();
    }
    await _load();
  }

  Future<void> _escalateFromHistory(String id, BuildContext sheetContext) async {
    final res = await _api.escalateSos(sosId: id, reason: 'Still unsafe from SOS history.');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(res['message']?.toString() ?? 'Escalation saved')),
    );
    if (sheetContext.mounted) {
      Navigator.of(sheetContext).pop();
    }
    await _load();
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
    final escalationStatus = _clean(alert['escalation_status'], fallback: 'active');
    final escalationLevel = _clean(alert['escalation_level'], fallback: '1');
    final safetyCheckedAt = _clean(alert['safety_checked_at']);
    final lastEscalatedAt = _clean(alert['last_escalated_at']);
    final resolvedAt = _clean(alert['resolved_at']);
    final escalationNote = _clean(alert['escalation_note']);
    final events = _asList(alert['escalation_events']);
    final isResolved = status == 'resolved' || escalationStatus == 'resolved';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.78,
        minChildSize: 0.45,
        maxChildSize: 0.94,
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
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(color: AppColors.redSoft, shape: BoxShape.circle),
                    child: const Icon(Icons.shield_outlined, color: AppColors.red, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SOS Alert Details',
                          style: GoogleFonts.inter(color: AppColors.ink, fontWeight: FontWeight.w800, fontSize: 17),
                        ),
                        const SizedBox(height: 2),
                        Text(_formatDate(triggeredAt), style: GoogleFonts.inter(color: AppColors.ink3, fontSize: 12)),
                      ],
                    ),
                  ),
                  _StatusPill(status: status),
                ],
              ),
              const SizedBox(height: 18),
              _DetailCard(
                children: [
                  _DetailRow(icon: Icons.fingerprint, label: 'Alert ID', value: id.isEmpty ? '—' : id),
                  _DetailRow(icon: Icons.touch_app_outlined, label: 'Trigger Method', value: method.toUpperCase()),
                  _DetailRow(icon: Icons.schedule_outlined, label: 'Triggered At', value: _formatDate(triggeredAt)),
                  if (dispatchedAt.isNotEmpty)
                    _DetailRow(icon: Icons.send_outlined, label: 'Dispatched At', value: _formatDate(dispatchedAt)),
                  if (createdAt.isNotEmpty)
                    _DetailRow(icon: Icons.history_toggle_off, label: 'Saved At', value: _formatDate(createdAt)),
                  _DetailRow(icon: Icons.cloud_off_outlined, label: 'Offline Origin', value: offline ? 'Yes' : 'No'),
                ],
              ),
              const SizedBox(height: 12),
              _DetailCard(
                children: [
                  _DetailRow(
                    icon: Icons.location_on_outlined,
                    label: 'Coordinates',
                    value: lat == null || lng == null ? '—' : '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
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
                ],
              ),
              const SizedBox(height: 12),
              _DetailCard(
                children: [
                  _DetailRow(icon: Icons.people_alt_outlined, label: 'Contacts Notified', value: '$delivered / $total'),
                  const _DetailRow(
                    icon: Icons.sms_outlined,
                    label: 'SMS/Push Note',
                    value: 'Saved in app history. External SMS/push depends on Twilio/Firebase configuration.',
                  ),
                  if (battery.isNotEmpty) _DetailRow(icon: Icons.battery_full_outlined, label: 'Battery', value: '$battery%'),
                ],
              ),
              const SizedBox(height: 12),
              _DetailCard(
                children: [
                  _DetailRow(icon: Icons.emergency_share_outlined, label: 'Escalation', value: escalationStatus.toUpperCase()),
                  _DetailRow(icon: Icons.layers_outlined, label: 'Level', value: escalationLevel),
                  if (lastEscalatedAt.isNotEmpty)
                    _DetailRow(icon: Icons.warning_amber_outlined, label: 'Last Escalated', value: _formatDate(lastEscalatedAt)),
                  if (safetyCheckedAt.isNotEmpty)
                    _DetailRow(icon: Icons.verified_user_outlined, label: 'Safety Check', value: _formatDate(safetyCheckedAt)),
                  if (resolvedAt.isNotEmpty)
                    _DetailRow(icon: Icons.check_circle_outline, label: 'Resolved At', value: _formatDate(resolvedAt)),
                  if (escalationNote.isNotEmpty)
                    _DetailRow(icon: Icons.notes_outlined, label: 'Note', value: escalationNote),
                ],
              ),
              if (events.isNotEmpty) ...[
                const SizedBox(height: 12),
                _TimelineCard(events: events.map(_asMap).toList(), formatDate: _formatDate),
              ],
              if (!isResolved && id.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _markSafeFromHistory(id, ctx),
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('I am safe'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _escalateFromHistory(id, ctx),
                        icon: const Icon(Icons.report_gmailerrorred_outlined, size: 18),
                        label: const Text('Still unsafe'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.red,
                          side: const BorderSide(color: AppColors.red),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _HotlineButton(label: 'Call 999', onTap: () => _callNumber('999'))),
                    const SizedBox(width: 8),
                    Expanded(child: _HotlineButton(label: 'Call 109', onTap: () => _callNumber('109'))),
                  ],
                ),
              ],
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
          style: GoogleFonts.inter(color: AppColors.ink, fontWeight: FontWeight.w700, fontSize: 17),
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

  Widget _buildEmpty() => ListView(
        children: [
          const SizedBox(height: 120),
          Center(
            child: Column(
              children: [
                Icon(Icons.shield_outlined, size: 64, color: AppColors.ink3.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                Text(
                  'No SOS alerts yet',
                  style: GoogleFonts.inter(color: AppColors.ink2, fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'Stay safe! Your past alerts will appear here.',
                  style: GoogleFonts.inter(color: AppColors.ink3, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _buildItem(Map<String, dynamic> alert) {
    final lat = _toDouble(alert['latitude']) ?? 0;
    final lng = _toDouble(alert['longitude']) ?? 0;
    final triggeredAt = alert['triggered_at']?.toString() ?? '';
    final method = alert['trigger_method']?.toString() ?? 'button';
    final status = alert['status']?.toString() ?? 'unknown';
    final escalationStatus = alert['escalation_status']?.toString() ?? 'active';
    final isOffline = alert['is_offline_origin'] == true || alert['is_offline_origin'] == 1;
    final delivered = alert['contacts_delivered'] ?? 0;
    final total = alert['contacts_total'] ?? 0;
    final battery = alert['battery_level'];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showAlertDetails(alert),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(color: AppColors.redSoft, shape: BoxShape.circle),
                    child: const Icon(Icons.shield_outlined, color: AppColors.red, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatDate(triggeredAt),
                          style: GoogleFonts.inter(color: AppColors.ink, fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            _Tag(label: method, color: AppColors.blue),
                            if (isOffline) const _Tag(label: 'Offline', color: AppColors.amber),
                            _Tag(label: escalationStatus, color: escalationStatus == 'resolved' ? AppColors.green : AppColors.amber),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _StatusPill(status: status),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, color: AppColors.ink3, size: 18),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: AppColors.ink2),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
                      style: GoogleFonts.inter(color: AppColors.ink2, fontSize: 11.5),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _openOnMap(lat, lng),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.greenSoft,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'View',
                        style: GoogleFonts.inter(color: AppColors.green, fontWeight: FontWeight.w700, fontSize: 11),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.people_alt_outlined, size: 13, color: AppColors.ink3),
                  const SizedBox(width: 4),
                  Text('Notified $delivered / $total contacts', style: GoogleFonts.inter(color: AppColors.ink3, fontSize: 11)),
                  const Spacer(),
                  if (battery != null) ...[
                    const Icon(Icons.battery_full, size: 13, color: AppColors.ink3),
                    const SizedBox(width: 2),
                    Text('$battery%', style: GoogleFonts.inter(color: AppColors.ink3, fontSize: 11)),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Tap for full alert details',
                style: GoogleFonts.inter(color: AppColors.green, fontWeight: FontWeight.w700, fontSize: 10.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.map((key, val) => MapEntry(key.toString(), val));
    return <String, dynamic>{};
  }

  List<dynamic> _asList(dynamic value) {
    if (value is List) return value;
    return const [];
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

class _TimelineCard extends StatelessWidget {
  final List<Map<String, dynamic>> events;
  final String Function(String) formatDate;

  const _TimelineCard({required this.events, required this.formatDate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timeline_outlined, color: AppColors.green, size: 17),
              const SizedBox(width: 8),
              Text(
                'Escalation Timeline',
                style: GoogleFonts.inter(color: AppColors.ink, fontSize: 12.5, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...events.map((event) {
            final type = event['event_type']?.toString() ?? 'event';
            final note = event['note']?.toString() ?? '';
            final time = event['created_at']?.toString() ?? '';
            return Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 5),
                    decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(type.replaceAll('_', ' ').toUpperCase(),
                            style: GoogleFonts.inter(color: AppColors.ink, fontSize: 11.5, fontWeight: FontWeight.w800)),
                        if (note.isNotEmpty)
                          Text(note, style: GoogleFonts.inter(color: AppColors.ink2, fontSize: 11.2, height: 1.3)),
                        Text(formatDate(time), style: GoogleFonts.inter(color: AppColors.ink3, fontSize: 10.5)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _HotlineButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _HotlineButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.local_phone_outlined, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.blue,
        side: BorderSide(color: AppColors.blue.withValues(alpha: 0.4)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.green, size: 17),
            const SizedBox(width: 10),
            SizedBox(
              width: 112,
              child: Text(
                label,
                style: GoogleFonts.inter(color: AppColors.ink3, fontSize: 11.5, fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              child: SelectableText(
                value,
                style: GoogleFonts.inter(color: AppColors.ink, fontSize: 12.2, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
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
        child: Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(color: color, fontWeight: FontWeight.w700, fontSize: 9, letterSpacing: 0.4),
        ),
      );
}

class _StatusPill extends StatelessWidget {
  final String status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final ok = status == 'dispatched' || status == 'resolved' || status == 'sent';
    final color = status == 'escalated' ? AppColors.red : (ok ? AppColors.green : AppColors.amber);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.inter(color: color, fontWeight: FontWeight.w700, fontSize: 9.5, letterSpacing: 0.4),
      ),
    );
  }
}
