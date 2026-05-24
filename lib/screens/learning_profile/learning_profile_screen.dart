import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/api_service.dart';
import '../../utils/constants.dart';

class LearningProfileScreen extends StatefulWidget {
  final void Function(String)? onNav;
  final VoidCallback? onBack;

  const LearningProfileScreen({super.key, this.onNav, this.onBack});

  @override
  State<LearningProfileScreen> createState() => _LearningProfileScreenState();
}

class _LearningProfileScreenState extends State<LearningProfileScreen> {
  final _api = ApiService();
  bool _loading = true;
  bool _submitting = false;
  Map<String, dynamic> _trust = {};
  Map<String, dynamic> _progress = {};
  List<dynamic> _rights = [];
  List<dynamic> _defense = [];
  List<dynamic> _tips = [];

  String _gender = 'female';
  final _institution = TextEditingController();
  final _reason = TextEditingController(text: 'I want women-only forum verification and community trust access.');

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _institution.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _api.getLearningProfileDashboard();
    if (!mounted) return;
    setState(() {
      _trust = _asMap(data['trust_profile']);
      _progress = _asMap(data['learning_progress']);
      _rights = _asList(data['rights_modules']);
      _defense = _asList(data['self_defense_modules']);
      _tips = _asList(data['safety_tips']);
      _loading = false;
    });
  }

  Map<String, dynamic> _asMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return {};
  }

  List<dynamic> _asList(dynamic v) => v is List ? v : [];

  Future<void> _requestVerification() async {
    setState(() => _submitting = true);
    final res = await _api.requestProfileVerification({
      'verification_type': 'women_forum',
      'gender': _gender,
      'institution_or_area': _institution.text.trim().isEmpty ? 'Not specified' : _institution.text.trim(),
      'reason': _reason.text.trim().isEmpty ? 'Women-only forum verification request.' : _reason.text.trim(),
    });
    if (!mounted) return;
    setState(() => _submitting = false);
    _toast(res['message']?.toString() ?? (res['success'] == true ? 'Verification request submitted.' : 'Could not submit request.'));
    await _load();
  }

  Future<void> _markDone(Map<String, dynamic> item, String type) async {
    final key = item['key']?.toString();
    if (key == null || key.isEmpty) return;
    final res = await _api.markLearningProgress({
      'module_key': key,
      'module_type': type,
      'completed': true,
    });
    _toast(res['message']?.toString() ?? 'Progress updated.');
    await _load();
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.ink),
          onPressed: widget.onBack,
        ),
        title: Text('Learning & Rights Center', style: GoogleFonts.inter(color: AppColors.ink, fontWeight: FontWeight.w800)),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded, color: AppColors.ink))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _trustCard(),
                  const SizedBox(height: 14),
                  _verificationCard(),
                  const SizedBox(height: 14),
                  _sectionTitle('Know Your Rights'),
                  ..._rights.map((e) => _learningCard(_asMap(e), 'rights', Icons.gavel_outlined)),
                  const SizedBox(height: 14),
                  _sectionTitle('Self-defense Learning Hub'),
                  ..._defense.map((e) => _learningCard(_asMap(e), 'self_defense', Icons.self_improvement_outlined)),
                  const SizedBox(height: 14),
                  _sectionTitle('Quick Safety Tips'),
                  ..._tips.map((e) => _tipCard(_asMap(e))),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _trustCard() {
    final score = int.tryParse('${_trust['trust_score'] ?? 0}') ?? 0;
    final verified = _trust['women_forum_verified'] == true;
    final status = _trust['verification_status']?.toString() ?? 'unverified';
    final role = _trust['role']?.toString() ?? 'user';
    final badges = _asList(_trust['badges']);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _box(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: AppColors.greenSoft, borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.verified_user_outlined, color: AppColors.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Trust Profile', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.ink)),
              Text('Role: $role Ãƒâ€šÃ‚Â· Status: $status', style: GoogleFonts.inter(fontSize: 12, color: AppColors.ink2)),
            ]),
          ),
          Text('$score%', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.green)),
        ]),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(value: (score.clamp(0, 100)) / 100, minHeight: 9, backgroundColor: AppColors.line, color: verified ? AppColors.green : AppColors.orange),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: badges.isEmpty
              ? [_chip('Verification pending or not requested', AppColors.orange)]
              : badges.map((b) => _chip(_asMap(b)['label']?.toString() ?? 'Badge', AppColors.green)).toList(),
        ),
        const SizedBox(height: 8),
        Text(
          'Learning progress: ${_progress['completed_total'] ?? 0} completed modules',
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.ink2),
        ),
      ]),
    );
  }

  Widget _verificationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _box(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.how_to_reg_outlined, color: AppColors.purple),
          const SizedBox(width: 8),
          Expanded(child: Text('Women-only forum verification request', style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: AppColors.ink))),
        ]),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: _gender,
          decoration: _input('Gender/self-identification'),
          items: const [
            DropdownMenuItem(value: 'female', child: Text('Female / Woman')),
            DropdownMenuItem(value: 'prefer_not_to_say', child: Text('Prefer not to say')),
          ],
          onChanged: (v) => setState(() => _gender = v ?? _gender),
        ),
        const SizedBox(height: 10),
        TextField(controller: _institution, decoration: _input('Institution / area / community reference')),
        const SizedBox(height: 10),
        TextField(controller: _reason, minLines: 2, maxLines: 3, decoration: _input('Reason')),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _submitting ? null : _requestVerification,
            icon: _submitting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send_rounded),
            label: Text(_submitting ? 'Submitting...' : 'Submit verification request'),
          ),
        ),
      ]),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.ink)),
    );
  }

  Widget _learningCard(Map<String, dynamic> item, String type, IconData icon) {
    final title = item['title']?.toString() ?? 'Learning module';
    final summary = item['summary']?.toString() ?? '';
    final actions = _asList(item['actions'] ?? item['steps']);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: _box(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: AppColors.red),
          const SizedBox(width: 10),
          Expanded(child: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: AppColors.ink))),
        ]),
        const SizedBox(height: 8),
        Text(summary, style: GoogleFonts.inter(fontSize: 12, height: 1.4, color: AppColors.ink2)),
        if (actions.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...actions.take(3).map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text('ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢ ${a.toString()}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.ink)),
              )),
        ],
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton.icon(
            onPressed: () => _markDone(item, type),
            icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
            label: const Text('Mark done'),
          ),
        ),
      ]),
    );
  }

  Widget _tipCard(Map<String, dynamic> tip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: _box(),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.lightbulb_outline_rounded, color: AppColors.orange),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tip['title']?.toString() ?? 'Safety tip', style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: AppColors.ink)),
            const SizedBox(height: 4),
            Text(tip['description']?.toString() ?? '', style: GoogleFonts.inter(fontSize: 12, color: AppColors.ink2, height: 1.4)),
          ]),
        ),
      ]),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: GoogleFonts.inter(fontSize: 11, color: color, fontWeight: FontWeight.w700)),
    );
  }

  BoxDecoration _box() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .03), blurRadius: 12, offset: const Offset(0, 6))],
      );

  InputDecoration _input(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
      );
}
