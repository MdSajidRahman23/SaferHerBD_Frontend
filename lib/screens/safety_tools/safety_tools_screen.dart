import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/api_service.dart';
import '../../utils/constants.dart';

class SafetyToolsScreen extends StatefulWidget {
  final void Function(String)? onNav;
  final VoidCallback? onBack;

  const SafetyToolsScreen({super.key, this.onNav, this.onBack});

  @override
  State<SafetyToolsScreen> createState() => _SafetyToolsScreenState();
}

class _SafetyToolsScreenState extends State<SafetyToolsScreen> {
  final _api = ApiService();
  bool _loading = true;
  bool _submitting = false;
  Map<String, dynamic> _stats = {};
  List<dynamic> _incidents = [];
  List<dynamic> _evidence = [];
  List<dynamic> _cases = [];

  final _incidentDescription = TextEditingController();
  String _reportType = 'harassment';
  String _severity = 'medium';
  bool _anonymous = true;

  final _evidenceTitle = TextEditingController();
  final _evidenceDescription = TextEditingController();
  String _evidenceType = 'note';

  final _caseTitle = TextEditingController();
  final _caseStation = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _incidentDescription.dispose();
    _evidenceTitle.dispose();
    _evidenceDescription.dispose();
    _caseTitle.dispose();
    _caseStation.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final dash = await _api.getSafetyToolsDashboard();
    if (!mounted) return;
    setState(() {
      _stats = _asMap(dash['stats']);
      _incidents = _asList(dash['recent_incidents']);
      _evidence = _asList(dash['recent_evidence']);
      _cases = _asList(dash['cases']);
      _loading = false;
    });
  }

  Map<String, dynamic> _asMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return {};
  }

  List<dynamic> _asList(dynamic v) => v is List ? v : [];

  Future<void> _submitIncident() async {
    if (_incidentDescription.text.trim().length < 10) {
      _toast('Please write at least 10 characters.');
      return;
    }
    setState(() => _submitting = true);
    final res = await _api.createSafetyIncidentReport({
      'report_type': _reportType,
      'severity': _severity,
      'description': _incidentDescription.text.trim(),
      'is_anonymous': _anonymous,
    });
    if (!mounted) return;
    setState(() => _submitting = false);
    _toast(res['success'] == true ? 'Incident report saved for review.' : (res['message']?.toString() ?? 'Failed'));
    if (res['success'] == true) {
      _incidentDescription.clear();
      await _load();
    }
  }

  Future<void> _saveEvidence() async {
    if (_evidenceTitle.text.trim().isEmpty) {
      _toast('Evidence title required.');
      return;
    }
    setState(() => _submitting = true);
    final res = await _api.createEvidenceVaultItem({
      'title': _evidenceTitle.text.trim(),
      'evidence_type': _evidenceType,
      'description': _evidenceDescription.text.trim(),
      'privacy_level': 'private',
    });
    if (!mounted) return;
    setState(() => _submitting = false);
    _toast(res['success'] == true ? 'Evidence saved in private vault.' : (res['message']?.toString() ?? 'Failed'));
    if (res['success'] == true) {
      _evidenceTitle.clear();
      _evidenceDescription.clear();
      await _load();
    }
  }

  Future<void> _createCase() async {
    if (_caseTitle.text.trim().isEmpty) {
      _toast('Case title required.');
      return;
    }
    setState(() => _submitting = true);
    final res = await _api.createCaseTracker({
      'case_title': _caseTitle.text.trim(),
      'case_type': 'general_diary',
      'police_station': _caseStation.text.trim(),
    });
    if (!mounted) return;
    setState(() => _submitting = false);
    _toast(res['success'] == true ? 'Case tracker created.' : (res['message']?.toString() ?? 'Failed'));
    if (res['success'] == true) {
      _caseTitle.clear();
      _caseStation.clear();
      await _load();
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.ink,
        title: Text('Evidence & Case Center', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack ?? () => Navigator.maybePop(context),
        ),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _summaryCards(),
                  const SizedBox(height: 14),
                  _incidentForm(),
                  const SizedBox(height: 14),
                  _evidenceForm(),
                  const SizedBox(height: 14),
                  _caseForm(),
                  const SizedBox(height: 14),
                  _recentSection('Recent reports', _incidents, Icons.report_outlined),
                  const SizedBox(height: 14),
                  _recentSection('Private evidence', _evidence, Icons.folder_copy_outlined),
                  const SizedBox(height: 14),
                  _recentSection('Case trackers', _cases, Icons.assignment_outlined),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _summaryCards() {
    final incidentCount = _stats['incident_reports'] ?? 0;
    final evidenceCount = _stats['evidence_items'] ?? 0;
    final caseCount = _stats['active_cases'] ?? 0;
    return Row(children: [
      _stat('Reports', '$incidentCount', Icons.report_gmailerrorred_outlined, AppColors.red),
      const SizedBox(width: 10),
      _stat('Evidence', '$evidenceCount', Icons.lock_outline, AppColors.blue),
      const SizedBox(width: 10),
      _stat('Cases', '$caseCount', Icons.gavel, AppColors.green),
    ]);
  }

  Widget _stat(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color),
          const SizedBox(height: 10),
          Text(value, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w900)),
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.ink2)),
        ]),
      ),
    );
  }

  Widget _incidentForm() {
    return _card('Guided Incident Report', Icons.edit_note, [
      Row(children: [
        Expanded(child: _dropdown('Type', _reportType, ['harassment', 'stalking', 'unsafe_area', 'transport', 'cyberbullying', 'domestic_violence', 'other'], (v) => setState(() => _reportType = v ?? _reportType))),
        const SizedBox(width: 10),
        Expanded(child: _dropdown('Severity', _severity, ['low', 'medium', 'high', 'critical'], (v) => setState(() => _severity = v ?? _severity))),
      ]),
      const SizedBox(height: 10),
      TextField(
        controller: _incidentDescription,
        minLines: 3,
        maxLines: 5,
        decoration: const InputDecoration(labelText: 'What happened?', border: OutlineInputBorder()),
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: _anonymous,
        onChanged: (v) => setState(() => _anonymous = v),
        title: Text('Submit anonymously', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      ),
      _button('Submit report', Icons.send, _submitIncident),
    ]);
  }

  Widget _evidenceForm() {
    return _card('Private Evidence Vault', Icons.folder_copy_outlined, [
      TextField(controller: _evidenceTitle, decoration: const InputDecoration(labelText: 'Evidence title', border: OutlineInputBorder())),
      const SizedBox(height: 10),
      _dropdown('Evidence type', _evidenceType, ['note', 'screenshot', 'photo', 'audio', 'video', 'document', 'other'], (v) => setState(() => _evidenceType = v ?? _evidenceType)),
      const SizedBox(height: 10),
      TextField(controller: _evidenceDescription, minLines: 2, maxLines: 4, decoration: const InputDecoration(labelText: 'Description / storage note', border: OutlineInputBorder())),
      const SizedBox(height: 10),
      _button('Save evidence metadata', Icons.lock, _saveEvidence),
      const SizedBox(height: 6),
      Text('Files are represented as private metadata in this build. Production storage should use encryption.', style: GoogleFonts.inter(fontSize: 11, color: AppColors.ink2)),
    ]);
  }

  Widget _caseForm() {
    return _card('Case Tracker', Icons.assignment_outlined, [
      TextField(controller: _caseTitle, decoration: const InputDecoration(labelText: 'Case title', border: OutlineInputBorder())),
      const SizedBox(height: 10),
      TextField(controller: _caseStation, decoration: const InputDecoration(labelText: 'Police station / help desk', border: OutlineInputBorder())),
      const SizedBox(height: 10),
      _button('Create case tracker', Icons.add_task, _createCase),
    ]);
  }

  Widget _dropdown(String label, String value, List<String> values, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      items: values.map((v) => DropdownMenuItem(value: v, child: Text(v.replaceAll('_', ' ')))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _button(String label, IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _submitting ? null : onTap,
        icon: Icon(icon),
        label: Text(_submitting ? 'Please wait...' : label),
      ),
    );
  }

  Widget _card(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(icon, color: AppColors.green), const SizedBox(width: 8), Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16))]),
        const SizedBox(height: 12),
        ...children,
      ]),
    );
  }

  Widget _recentSection(String title, List<dynamic> items, IconData icon) {
    return _card(title, icon, items.isEmpty
        ? [Text('No records yet.', style: GoogleFonts.inter(color: AppColors.ink2))]
        : items.take(4).map((item) {
            final m = _asMap(item);
            final main = (m['description'] ?? m['title'] ?? m['case_title'] ?? m['report_type'] ?? 'Record').toString();
            final status = (m['status'] ?? m['privacy_level'] ?? m['evidence_type'] ?? '').toString();
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(12)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(main, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                if (status.isNotEmpty) Text(status, style: GoogleFonts.inter(fontSize: 11, color: AppColors.ink2)),
              ]),
            );
          }).toList());
  }
}
