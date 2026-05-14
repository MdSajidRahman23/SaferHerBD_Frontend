import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/api_service.dart';
import '../../utils/constants.dart';

class LegalScreen extends StatefulWidget {
  final void Function(String) onNav;
  final VoidCallback onBack;
  const LegalScreen({super.key, required this.onNav, required this.onBack});

  @override
  State<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends State<LegalScreen> {
  final _api = ApiService();
  final _searchCtrl = TextEditingController();

  bool _loading = true;
  List<dynamic> _all = [];
  List<dynamic> _filtered = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _api.getLegalResources();
    if (!mounted) return;
    setState(() {
      _all = list;
      _filtered = list;
      _loading = false;
    });
  }

  void _onSearchChanged(String q) {
    final query = q.toLowerCase().trim();
    if (query.isEmpty) {
      setState(() => _filtered = _all);
      return;
    }
    setState(() {
      _filtered = _all.where((r) {
        final m = Map<String, dynamic>.from(r as Map);
        final t = (m['title'] ?? m['title_en'] ?? '').toString().toLowerCase();
        final c = (m['category'] ?? m['category_en'] ?? '').toString().toLowerCase();
        final b = (m['content_body'] ?? m['summary'] ?? '').toString().toLowerCase();
        final meta = (m['meta_data_json'] ?? '').toString().toLowerCase();
        return t.contains(query) || c.contains(query) || b.contains(query) || meta.contains(query);
      }).toList();
    });
  }

  Future<void> _callHelpline(String n) async {
    final uri = Uri.parse('tel:$n');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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
          onPressed: widget.onBack,
        ),
        title: Text(
          'Legal Aid',
          style: GoogleFonts.inter(color: AppColors.ink, fontWeight: FontWeight.w700, fontSize: 17),
        ),
      ),
      body: Column(children: [
        Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
          color: Colors.white,
          child: Column(children: [
            Container(
              decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(12)),
              child: TextField(
                controller: _searchCtrl,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search Bangladesh laws, helplines…',
                  hintStyle: GoogleFonts.inter(color: AppColors.ink3, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: AppColors.ink2, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _HelpChip(label: '109 মহিলা ও শিশু', color: AppColors.red, onTap: () => _callHelpline('109'))),
              const SizedBox(width: 8),
              Expanded(child: _HelpChip(label: '999 Police', color: AppColors.red, onTap: () => _callHelpline('999'))),
              const SizedBox(width: 8),
              Expanded(child: _HelpChip(label: 'Legal 16430', color: AppColors.green, onTap: () => _callHelpline('16430'))),
            ]),
            const SizedBox(height: 10),
          ]),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.green))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.green,
                  child: _filtered.isEmpty
                      ? ListView(children: [
                          const SizedBox(height: 80),
                          Center(child: Text('No results', style: GoogleFonts.inter(color: AppColors.ink3, fontSize: 13))),
                        ])
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) => _LegalCard(item: Map<String, dynamic>.from(_filtered[i] as Map)),
                        ),
                ),
        ),
      ]),
    );
  }
}

class _HelpChip extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _HelpChip({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.phone, color: color, size: 14),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.hindSiliguri(color: color, fontWeight: FontWeight.w700, fontSize: 11),
              ),
            ),
          ]),
        ),
      );
}

class _LegalCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const _LegalCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final title = (item['title'] ?? item['title_en'] ?? '').toString();
    final category = (item['category'] ?? item['category_en'] ?? 'Legal').toString();
    final summary = (item['summary'] ?? item['content_body'] ?? '').toString();

    return GestureDetector(
      onTap: () => _showDetail(context, item),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: AppColors.greenSoft, borderRadius: BorderRadius.circular(20)),
            child: Text(
              category.toUpperCase(),
              style: GoogleFonts.inter(color: AppColors.green, fontWeight: FontWeight.w700, fontSize: 9, letterSpacing: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(color: AppColors.ink, fontWeight: FontWeight.w700, fontSize: 13.5)),
          if (summary.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(summary, maxLines: 3, overflow: TextOverflow.ellipsis, style: GoogleFonts.hindSiliguri(color: AppColors.ink2, fontSize: 12, height: 1.45)),
          ],
        ]),
      ),
    );
  }

  void _showDetail(BuildContext context, Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.82,
        maxChildSize: 0.96,
        minChildSize: 0.45,
        expand: false,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          child: Column(children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(2))),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollCtrl,
                padding: const EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text((item['title'] ?? item['title_en'] ?? '').toString(), style: GoogleFonts.inter(color: AppColors.ink, fontWeight: FontWeight.w800, fontSize: 16, height: 1.4)),
                  const SizedBox(height: 14),
                  SelectableText(
                    _detailsText(item),
                    style: GoogleFonts.hindSiliguri(color: AppColors.ink2, fontSize: 13, height: 1.7),
                  ),
                  const SizedBox(height: 20),
                  const Wrap(spacing: 8, runSpacing: 8, children: [
                    _CallButton(label: 'Call 999', number: '999', color: AppColors.red),
                    _CallButton(label: 'Call 109', number: '109', color: AppColors.red),
                    _CallButton(label: 'Legal 16430', number: '16430', color: AppColors.green),
                  ]),
                  const SizedBox(height: 30),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  String _detailsText(Map<String, dynamic> item) {
    final lines = <String>[];
    final content = (item['content_body'] ?? item['summary'] ?? '').toString().trim();
    if (content.isNotEmpty) lines.add(content);

    final meta = item['meta_data_json'];
    if (meta is Map) {
      final helplines = meta['helplines'];
      if (helplines is List && helplines.isNotEmpty) {
        lines.add('\nHelplines:');
        for (final h in helplines) {
          if (h is Map) lines.add('• ${h['name'] ?? h['title'] ?? 'Helpline'}: ${h['number'] ?? h['phone'] ?? ''} — ${h['note'] ?? h['available'] ?? ''}');
        }
      }
      final contacts = meta['contacts'];
      if (contacts is List && contacts.isNotEmpty) {
        lines.add('\nContacts:');
        for (final c in contacts) {
          if (c is Map) lines.add('• ${c['title'] ?? c['name'] ?? 'Contact'}: ${c['phone'] ?? c['number'] ?? ''} (${c['available'] ?? ''})');
        }
      }
      final what = meta['what_to_do'];
      if (what is List && what.isNotEmpty) {
        lines.add('\nWhat to do now:');
        for (final step in what) {
          lines.add('• $step');
        }
      }
      final checklist = meta['checklist'];
      if (checklist is List && checklist.isNotEmpty) {
        lines.add('\nChecklist:');
        for (final step in checklist) {
          lines.add('• $step');
        }
      }
      final disclaimer = meta['disclaimer'];
      if (disclaimer != null) lines.add('\nNote: $disclaimer');
    }

    if (lines.isEmpty) return 'No details available yet. Please call 999 for emergency support or 109 for women and children support.';
    return lines.join('\n');
  }
}

class _CallButton extends StatelessWidget {
  final String label;
  final String number;
  final Color color;
  const _CallButton({required this.label, required this.number, required this.color});

  @override
  Widget build(BuildContext context) => ElevatedButton.icon(
        onPressed: () async {
          final uri = Uri.parse('tel:$number');
          if (await canLaunchUrl(uri)) await launchUrl(uri);
        },
        icon: const Icon(Icons.phone, size: 16),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
}
