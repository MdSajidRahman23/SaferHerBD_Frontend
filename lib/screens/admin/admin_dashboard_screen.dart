import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/api_service.dart';
import '../../utils/constants.dart';

class AdminDashboardScreen extends StatefulWidget {
  final void Function(String) onNav;
  final VoidCallback onBack;
  const AdminDashboardScreen({super.key, required this.onNav, required this.onBack});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _api = ApiService();
  final _scrollController = ScrollController();
  final _sosKey = GlobalKey();
  final _moderationKey = GlobalKey();
  final _healthKey = GlobalKey();

  bool _loading = true;
  bool _busy = false;
  String? _error;
  Map<String, dynamic> _data = <String, dynamic>{};
  List<dynamic>? _activeSosOverride;
  List<dynamic>? _moderationOverride;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _activeSosOverride = null;
      _moderationOverride = null;
    });

    final res = await _api.getAdminOverview();
    if (!mounted) return;

    setState(() {
      _loading = false;
      if (res['success'] == true) {
        _data = Map<String, dynamic>.from(res);
      } else {
        _error = res['message']?.toString() ?? 'Admin dashboard could not be loaded.';
      }
    });
  }

  Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  List<dynamic> _list(dynamic value) => value is List ? value : const [];

  int _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  String _shortId(dynamic id) {
    final s = id?.toString() ?? '';
    if (s.length <= 8) return s;
    return s.substring(0, 8);
  }

  String _clean(dynamic value) {
    var s = value?.toString() ?? '';
    if (s.isEmpty) return s;
    s = s
        .replaceAll('â€¢', ' - ')
        .replaceAll('â€“', '-')
        .replaceAll('â€”', '-')
        .replaceAll('Â', '')
        .replaceAll('�', '');
    try {
      final repaired = utf8.decode(latin1.encode(s), allowMalformed: true);
      final repairedBangla = RegExp(r'[\u0980-\u09FF]').allMatches(repaired).length;
      final originalBangla = RegExp(r'[\u0980-\u09FF]').allMatches(s).length;
      if (repairedBangla > originalBangla) return repaired;
    } catch (_) {}
    return s;
  }

  String _fmtMs(dynamic value) {
    if (value == null) return 'Queue-based SOS dispatch is enabled.';
    final n = value is num ? value.toDouble() : double.tryParse(value.toString());
    if (n == null || n < 0 || n > 10000) return 'Queue-based SOS dispatch is enabled.';
    return 'Average SOS ACK latency: ${n.toStringAsFixed(n < 100 ? 1 : 0)} ms';
  }

  Future<void> _scrollTo(GlobalKey key) async {
    final context = key.currentContext;
    if (context == null) return;
    await Scrollable.ensureVisible(context, duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
  }

  Future<void> _loadActiveSos() async {
    setState(() => _busy = true);
    final alerts = await _api.getAdminActiveSos();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _activeSosOverride = alerts;
    });
    await _scrollTo(_sosKey);
    _toast('Active SOS queue refreshed.');
  }

  Future<void> _loadModerationQueue() async {
    setState(() => _busy = true);
    final posts = await _api.getAdminModerationQueue();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _moderationOverride = posts;
    });
    await _scrollTo(_moderationKey);
    _toast('Moderation queue refreshed.');
  }

  Future<void> _resolveSos(String id) async {
    setState(() => _busy = true);
    final res = await _api.resolveAdminSos(id);
    if (!mounted) return;
    setState(() => _busy = false);
    _toast(res['success'] == true ? 'SOS marked as resolved.' : (res['message']?.toString() ?? 'Could not resolve SOS.'));
    await _load();
  }

  Future<void> _approvePost(String id) async {
    setState(() => _busy = true);
    final res = await _api.approveAdminPost(id);
    if (!mounted) return;
    setState(() => _busy = false);
    _toast(res['success'] == true ? 'Post approved.' : (res['message']?.toString() ?? 'Could not approve post.'));
    await _loadModerationQueue();
  }

  Future<void> _removePost(String id) async {
    setState(() => _busy = true);
    final res = await _api.removeAdminPost(id);
    if (!mounted) return;
    setState(() => _busy = false);
    _toast(res['success'] == true ? 'Post removed.' : (res['message']?.toString() ?? 'Could not remove post.'));
    await _loadModerationQueue();
  }

  @override
  Widget build(BuildContext context) {
    final stats = _map(_data['stats']);
    final system = _map(_data['system']);
    final latency = _map(_data['latency']);
    final recentSos = _activeSosOverride ?? _list(_data['recent_sos']);
    final flaggedPosts = _moderationOverride ?? _list(_data['flagged_posts']);
    final trend = _list(_data['sos_trend']);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Stack(children: [
          RefreshIndicator(
            color: AppColors.green,
            onRefresh: _load,
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                _Header(onBack: widget.onBack, onRefresh: _load),
                const SizedBox(height: 16),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.only(top: 120),
                    child: Center(child: CircularProgressIndicator(color: AppColors.green)),
                  )
                else if (_error != null)
                  _AccessCard(message: _error!, onRetry: _load)
                else ...[
                  _SystemBanner(system: system, latencyText: _fmtMs(latency['average_sos_ack_ms'])),
                  const SizedBox(height: 14),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.55,
                    children: [
                      _StatCard('Users', _int(stats['total_users']), Icons.people_alt_outlined, AppColors.green, onTap: () => _toast('Total registered SafeHerBD users.')),
                      _StatCard('Active SOS', _int(stats['active_sos_alerts']), Icons.sos_outlined, AppColors.red, onTap: _loadActiveSos),
                      _StatCard('SOS Today', _int(stats['sos_today']), Icons.today_outlined, AppColors.amber, onTap: () => _scrollTo(_sosKey)),
                      _StatCard('Moderation', _int(stats['moderation_queue']), Icons.fact_check_outlined, AppColors.blue, onTap: _loadModerationQueue),
                      _StatCard('Forum Posts', _int(stats['forum_posts']), Icons.forum_outlined, AppColors.green, onTap: _loadModerationQueue),
                      _StatCard('Legal Items', _int(stats['legal_resources']), Icons.gavel_outlined, AppColors.ink2, onTap: () => widget.onNav('legal')),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _TrendCard(items: trend),
                  const SizedBox(height: 14),
                  Container(
                    key: _sosKey,
                    child: _SectionCard(
                      title: _activeSosOverride == null ? 'Recent SOS Alerts' : 'Active SOS Alerts',
                      subtitle: _activeSosOverride == null ? 'Live emergency monitoring queue' : 'Only unresolved emergency alerts',
                      icon: Icons.warning_amber_rounded,
                      trailing: TextButton.icon(onPressed: _loadActiveSos, icon: const Icon(Icons.refresh, size: 16), label: const Text('Active')),
                      child: recentSos.isEmpty
                          ? const _EmptyLine('No SOS alert found.')
                          : Column(
                              children: recentSos.take(8).map((item) {
                                final m = _map(item);
                                final id = m['id']?.toString() ?? '';
                                return _SosRow(
                                  id: _shortId(id),
                                  fullId: id,
                                  user: _clean(m['user_name'] ?? 'Unknown user'),
                                  phone: _clean(m['user_phone_masked'] ?? 'hidden'),
                                  status: _clean(m['status'] ?? 'pending'),
                                  time: _clean(m['triggered_at'] ?? m['created_at'] ?? ''),
                                  onResolve: id.isEmpty || _clean(m['status']).toLowerCase() == 'resolved' ? null : () => _resolveSos(id),
                                );
                              }).toList(),
                            ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    key: _moderationKey,
                    child: _SectionCard(
                      title: 'Moderation Queue',
                      subtitle: 'Pending and flagged community posts',
                      icon: Icons.shield_outlined,
                      trailing: TextButton.icon(onPressed: _loadModerationQueue, icon: const Icon(Icons.refresh, size: 16), label: const Text('Queue')),
                      child: flaggedPosts.isEmpty
                          ? const _EmptyLine('No pending moderation item.')
                          : Column(
                              children: flaggedPosts.take(8).map((item) {
                                final m = _map(item);
                                final id = m['id']?.toString() ?? '';
                                return _PostRow(
                                  id: _shortId(id),
                                  fullId: id,
                                  author: _clean(m['author_name'] ?? 'Anonymous'),
                                  text: _clean(m['content_body'] ?? ''),
                                  status: _clean(m['moderation_status'] ?? 'pending'),
                                  score: _clean(m['nlp_score'] ?? '0'),
                                  onApprove: id.isEmpty ? null : () => _approvePost(id),
                                  onRemove: id.isEmpty ? null : () => _removePost(id),
                                );
                              }).toList(),
                            ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    key: _healthKey,
                    child: _SectionCard(
                      title: 'Operational Health',
                      subtitle: 'Backend, ML API and queue readiness',
                      icon: Icons.monitor_heart_outlined,
                      child: Column(children: [
                        _HealthRow('Database', system['database_ok'] == true),
                        _HealthRow('ML API reachable', system['ml_api_ok'] == true),
                        _HealthRow('ML models ready', system['ml_ready'] == true),
                        _HealthRow('Notification table', system['notifications_table'] == true),
                        _HealthRow('SOS delivery table', system['sos_delivery_table'] == true),
                        const SizedBox(height: 8),
                        Row(children: [
                          Expanded(child: _TinyMetric('Pending jobs', '${system['queue_pending_jobs'] ?? 0}')),
                          const SizedBox(width: 10),
                          Expanded(child: _TinyMetric('Failed jobs', '${system['queue_failed_jobs'] ?? 0}')),
                        ]),
                      ]),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
          if (_busy)
            Positioned.fill(
              child: IgnorePointer(
                ignoring: false,
                child: Container(color: Colors.black.withValues(alpha: .05), child: const Center(child: CircularProgressIndicator(color: AppColors.green))),
              ),
            ),
        ]),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onRefresh;
  const _Header({required this.onBack, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      _SquareButton(icon: Icons.chevron_left, onTap: onBack),
      const SizedBox(width: 10),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Admin Dashboard', style: GoogleFonts.inter(fontSize: 19, fontWeight: FontWeight.w900, color: AppColors.ink)),
          const SizedBox(height: 2),
          Text('Safety operations and moderation center', style: GoogleFonts.inter(fontSize: 12, color: AppColors.ink2)),
        ]),
      ),
      _SquareButton(icon: Icons.refresh, onTap: onRefresh),
    ]);
  }
}

class _SystemBanner extends StatelessWidget {
  final Map<String, dynamic> system;
  final String latencyText;
  const _SystemBanner({required this.system, required this.latencyText});

  @override
  Widget build(BuildContext context) {
    final ok = system['database_ok'] == true && system['ml_api_ok'] == true;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ok ? AppColors.greenSoft : AppColors.redSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ok ? AppColors.green.withValues(alpha: .25) : AppColors.red.withValues(alpha: .25)),
      ),
      child: Row(children: [
        Icon(ok ? Icons.verified_outlined : Icons.error_outline, color: ok ? AppColors.green : AppColors.red, size: 28),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(ok ? 'System operational' : 'System needs attention', style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: AppColors.ink)),
          const SizedBox(height: 3),
          Text(latencyText, style: GoogleFonts.inter(fontSize: 12, color: AppColors.ink2)),
        ])),
      ]),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  const _StatCard(this.label, this.value, this.icon, this.color, {this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), border: Border.all(color: AppColors.line)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(11)),
                child: Icon(icon, color: color, size: 19),
              ),
              const Spacer(),
              Text('$value', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.ink)),
            ]),
            const Spacer(),
            Row(children: [
              Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink2))),
              if (onTap != null) const Icon(Icons.chevron_right, size: 15, color: AppColors.ink3),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  final List<dynamic> items;
  const _TrendCard({required this.items});

  @override
  Widget build(BuildContext context) {
    final values = items.map((e) {
      if (e is Map) return (e['total'] as num?)?.toDouble() ?? 0.0;
      return 0.0;
    }).toList();
    final maxValue = values.isEmpty ? 1.0 : values.reduce((a, b) => a > b ? a : b).clamp(1.0, double.infinity);

    return _SectionCard(
      title: '7-Day SOS Trend',
      subtitle: 'Daily emergency request volume',
      icon: Icons.insights_outlined,
      child: SizedBox(
        height: 122,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: values.isEmpty
              ? [const Expanded(child: _EmptyLine('No trend data available.'))]
              : values.asMap().entries.map((entry) {
                  final h = 16 + (entry.value / maxValue) * 50;
                  final day = items[entry.key] is Map ? (items[entry.key]['day']?.toString() ?? '') : '';
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(mainAxisAlignment: MainAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
                        Text('${entry.value.round()}', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.ink2)),
                        const SizedBox(height: 4),
                        Container(height: h, decoration: BoxDecoration(color: AppColors.red.withValues(alpha: .78), borderRadius: BorderRadius.circular(8))),
                        const SizedBox(height: 4),
                        Text(day.length >= 10 ? day.substring(5) : day, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 9, color: AppColors.ink3)),
                      ]),
                    ),
                  );
                }).toList(),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;
  final Widget? trailing;
  const _SectionCard({required this.title, required this.subtitle, required this.icon, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 19, color: AppColors.green),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink)),
            const SizedBox(height: 2),
            Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: AppColors.ink3)),
          ])),
          if (trailing != null) trailing!,
        ]),
        const SizedBox(height: 12),
        child,
      ]),
    );
  }
}

class _SosRow extends StatelessWidget {
  final String id;
  final String fullId;
  final String user;
  final String phone;
  final String status;
  final String time;
  final VoidCallback? onResolve;
  const _SosRow({required this.id, required this.fullId, required this.user, required this.phone, required this.status, required this.time, this.onResolve});

  @override
  Widget build(BuildContext context) {
    return _ListLine(
      icon: Icons.sos_outlined,
      color: AppColors.red,
      title: '$user - $status',
      subtitle: '#$id - $phone - $time',
      actions: [
        if (onResolve != null)
          _MiniAction(label: 'Resolve', icon: Icons.check_circle_outline, color: AppColors.green, onTap: onResolve!),
      ],
    );
  }
}

class _PostRow extends StatelessWidget {
  final String id;
  final String fullId;
  final String author;
  final String text;
  final String status;
  final String score;
  final VoidCallback? onApprove;
  final VoidCallback? onRemove;
  const _PostRow({required this.id, required this.fullId, required this.author, required this.text, required this.status, required this.score, this.onApprove, this.onRemove});

  @override
  Widget build(BuildContext context) {
    return _ListLine(
      icon: Icons.report_gmailerrorred_outlined,
      color: AppColors.amber,
      title: '$author - $status - NLP $score',
      subtitle: '#$id - $text',
      actions: [
        if (onApprove != null) _MiniAction(label: 'Approve', icon: Icons.done, color: AppColors.green, onTap: onApprove!),
        if (onRemove != null) _MiniAction(label: 'Remove', icon: Icons.delete_outline, color: AppColors.red, onTap: onRemove!),
      ],
    );
  }
}

class _ListLine extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final List<Widget> actions;
  const _ListLine({required this.icon, required this.color, required this.title, required this.subtitle, this.actions = const []});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.ink)),
            const SizedBox(height: 2),
            Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 10.5, color: AppColors.ink2)),
          ])),
        ]),
        if (actions.isNotEmpty) ...[
          const SizedBox(height: 9),
          Wrap(spacing: 8, runSpacing: 6, children: actions),
        ],
      ]),
    );
  }
}

class _MiniAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _MiniAction({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(color: color.withValues(alpha: .10), borderRadius: BorderRadius.circular(99), border: Border.all(color: color.withValues(alpha: .22))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
        ]),
      ),
    );
  }
}

class _HealthRow extends StatelessWidget {
  final String label;
  final bool ok;
  const _HealthRow(this.label, this.ok);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Icon(ok ? Icons.check_circle : Icons.warning_amber_rounded, size: 18, color: ok ? AppColors.green : AppColors.amber),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.ink))),
        Text(ok ? 'OK' : 'Check', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: ok ? AppColors.green : AppColors.amber)),
      ]),
    );
  }
}

class _TinyMetric extends StatelessWidget {
  final String label;
  final String value;
  const _TinyMetric(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: AppColors.ink3)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.ink)),
      ]),
    );
  }
}

class _AccessCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _AccessCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.line)),
      child: Column(children: [
        const Icon(Icons.admin_panel_settings_outlined, size: 42, color: AppColors.amber),
        const SizedBox(height: 12),
        Text('Admin access required', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.ink)),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 12, color: AppColors.ink2, height: 1.4)),
        const SizedBox(height: 14),
        ElevatedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Retry')),
      ]),
    );
  }
}

class _EmptyLine extends StatelessWidget {
  final String text;
  const _EmptyLine(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(text, style: GoogleFonts.inter(fontSize: 12, color: AppColors.ink3)),
      );
}

class _SquareButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SquareButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line)),
        child: Icon(icon, color: AppColors.ink, size: 18),
      ),
    );
  }
}
