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
        final m = r as Map<String, dynamic>;
        final t = (m['title'] ?? m['title_en'] ?? '').toString().toLowerCase();
        final c = (m['category'] ?? m['category_en'] ?? '').toString().toLowerCase();
        final b = (m['content_body'] ?? m['summary'] ?? '').toString().toLowerCase();
        return t.contains(query) || c.contains(query) || b.contains(query);
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
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.ink), onPressed: widget.onBack),
        title: Text('Legal Aid',
            style: GoogleFonts.inter(color: AppColors.ink, fontWeight: FontWeight.w700, fontSize: 17)),
      ),
      body: Column(children: [
        Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
          color: Colors.white,
          child: Column(children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search Bangladesh laws…',
                  hintStyle: GoogleFonts.inter(color: AppColors.ink3, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: AppColors.ink2, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Quick helpline strip
            Row(children: [
              Expanded(child: _HelpChip(
                label: '109 মহিলা ও শিশু', color: AppColors.red,
                onTap: () => _callHelpline('109'),
              )),
              const SizedBox(width: 8),
              Expanded(child: _HelpChip(
                label: '999 Police', color: AppColors.red,
                onTap: () => _callHelpline('999'),
              )),
              const SizedBox(width: 8),
              Expanded(child: _HelpChip(
                label: 'Lawyer help', color: AppColors.green,
                onTap: () => _callHelpline('16430'),
              )),
            ]),
            const SizedBox(height: 10),
          ]),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.green))
              : RefreshIndicator(
                  onRefresh: _load, color: AppColors.green,
                  child: _filtered.isEmpty
                      ? ListView(children: [
                          const SizedBox(height: 80),
                          Center(child: Text('No results',
                              style: GoogleFonts.inter(color: AppColors.ink3, fontSize: 13))),
                        ])
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) => _LegalCard(item: _filtered[i] as Map<String, dynamic>),
                        ),
                ),
        ),
      ]),
    );
  }
}

class _HelpChip extends StatelessWidget {
  final String label; final Color color; final VoidCallback onTap;
  const _HelpChip({required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.phone, color: color, size: 14),
        const SizedBox(width: 5),
        Flexible(child: Text(label,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.hindSiliguri(color: color, fontWeight: FontWeight.w700, fontSize: 11))),
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
            decoration: BoxDecoration(
              color: AppColors.greenSoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(category.toUpperCase(),
                style: GoogleFonts.inter(
                    color: AppColors.green, fontWeight: FontWeight.w700, fontSize: 9, letterSpacing: 0.5)),
          ),
          const SizedBox(height: 8),
          Text(title,
              maxLines: 2, overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(color: AppColors.ink, fontWeight: FontWeight.w700, fontSize: 13.5)),
          if (summary.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(summary,
                maxLines: 2, overflow: TextOverflow.ellipsis,
                style: GoogleFonts.hindSiliguri(color: AppColors.ink2, fontSize: 12, height: 1.45)),
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
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(2))),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollCtrl,
                padding: const EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text((item['title'] ?? item['title_en'] ?? '').toString(),
                      style: GoogleFonts.inter(
                          color: AppColors.ink, fontWeight: FontWeight.w800, fontSize: 16, height: 1.4)),
                  const SizedBox(height: 14),
                  Text((item['content_body'] ?? item['summary'] ?? 'No details available.').toString(),
                      style: GoogleFonts.hindSiliguri(color: AppColors.ink2, fontSize: 13, height: 1.7)),
                  const SizedBox(height: 20),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
