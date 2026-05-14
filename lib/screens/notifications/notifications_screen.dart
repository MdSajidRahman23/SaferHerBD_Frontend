import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../services/api_service.dart';
import '../../utils/constants.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _api = ApiService();

  bool _loading = true;
  List<dynamic> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _api.getNotifications();
    if (!mounted) return;
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  Future<void> _markAllRead() async {
    final ok = await _api.markAllNotificationsRead();
    if (ok && mounted) await _load();
  }

  Future<void> _delete(String id) async {
    final ok = await _api.deleteNotification(id);
    if (ok && mounted) {
      setState(() => _items.removeWhere((n) => n['id'] == id));
    }
  }

  Future<void> _onTap(Map<String, dynamic> n) async {
    if (n['read_at'] == null) {
      await _api.markNotificationRead(n['id'].toString());
      if (mounted) setState(() => n['read_at'] = DateTime.now().toIso8601String());
    }

    // Optionally navigate to associated screen based on type
    final type = (n['type'] ?? '').toString();
    if (type == 'sos_dispatched') {
      if (mounted) Navigator.pushNamed(context, '/sos-history');
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
          'Notifications',
          style: GoogleFonts.inter(
            color: AppColors.ink,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        actions: [
          if (_items.any((n) => n['read_at'] == null))
            TextButton(
              onPressed: _markAllRead,
              child: Text(
                'Mark all read',
                style: GoogleFonts.inter(
                  color: AppColors.green,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.green,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.green))
            : _items.isEmpty
                ? _buildEmpty()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: _items.length,
                    itemBuilder: (_, i) => _buildItem(_items[i] as Map<String, dynamic>),
                  ),
      ),
    );
  }

  Widget _buildEmpty() => ListView(
        children: [
          const SizedBox(height: 120),
          Center(
            child: Column(children: [
              Icon(Icons.notifications_off_outlined, size: 64, color: AppColors.ink3.withValues(alpha: 0.5)),
              const SizedBox(height: 12),
              Text('No notifications yet',
                  style: GoogleFonts.inter(
                      color: AppColors.ink2, fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 4),
              Text("You'll see safety alerts and updates here.",
                  style: GoogleFonts.inter(color: AppColors.ink3, fontSize: 12)),
            ]),
          ),
        ],
      );

  Widget _buildItem(Map<String, dynamic> n) {
    final isUnread = n['read_at'] == null;
    final type     = (n['type'] ?? '').toString();
    final title    = (n['title_bn']?.toString().isNotEmpty == true ? n['title_bn'] : n['title_en']) ?? 'Notification';
    final body     = (n['body_bn']?.toString().isNotEmpty == true ? n['body_bn'] : n['body_en']) ?? '';
    final created  = n['created_at']?.toString() ?? '';

    final iconData = _iconFor(type);
    final iconColor = _colorFor(type);

    return Dismissible(
      key: ValueKey(n['id']),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.red,
          borderRadius: BorderRadius.circular(14),
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => _delete(n['id'].toString()),
      child: GestureDetector(
        onTap: () => _onTap(n),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isUnread ? AppColors.greenSoft.withValues(alpha: 0.4) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isUnread ? AppColors.green.withValues(alpha: 0.25) : AppColors.line,
            ),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: Text(
                      title.toString(),
                      style: GoogleFonts.hindSiliguri(
                        color: AppColors.ink,
                        fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                  if (isUnread)
                    Container(
                      width: 7, height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                ]),
                const SizedBox(height: 3),
                Text(
                  body.toString(),
                  style: GoogleFonts.hindSiliguri(
                    color: AppColors.ink2,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _relTime(created),
                  style: GoogleFonts.inter(color: AppColors.ink3, fontSize: 10.5),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'sos_dispatched': return Icons.shield_outlined;
      case 'forum_reply':    return Icons.forum_outlined;
      case 'safety_alert':   return Icons.warning_amber_rounded;
      case 'system':         return Icons.info_outline;
      default:               return Icons.notifications_outlined;
    }
  }

  Color _colorFor(String type) {
    switch (type) {
      case 'sos_dispatched': return AppColors.red;
      case 'forum_reply':    return AppColors.blue;
      case 'safety_alert':   return AppColors.amber;
      default:               return AppColors.green;
    }
  }

  String _relTime(String iso) {
    if (iso.isEmpty) return '';
    try {
      final dt   = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1)  return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours   < 24) return '${diff.inHours}h ago';
      if (diff.inDays    < 7)  return '${diff.inDays}d ago';
      return DateFormat('d MMM, y').format(dt);
    } catch (_) {
      return iso;
    }
  }
}
