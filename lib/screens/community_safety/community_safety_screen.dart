import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/api_service.dart';
import '../../utils/constants.dart';

class CommunitySafetyScreen extends StatefulWidget {
  final void Function(String)? onNav;
  final VoidCallback? onBack;
  const CommunitySafetyScreen({super.key, this.onNav, this.onBack});

  @override
  State<CommunitySafetyScreen> createState() => _CommunitySafetyScreenState();
}

class _CommunitySafetyScreenState extends State<CommunitySafetyScreen> {
  final _api = ApiService();
  bool _loading = true;
  Map<String, dynamic> _profile = {};
  List<dynamic> _guardians = [];
  List<dynamic> _wards = [];
  List<dynamic> _incidents = [];

  final _guardianName = TextEditingController();
  final _guardianPhone = TextEditingController();
  final _incidentArea = TextEditingController();
  final _incidentDistrict = TextEditingController();
  final _incidentDescription = TextEditingController();
  String _incidentType = 'harassment';
  String _severity = 'medium';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _guardianName.dispose();
    _guardianPhone.dispose();
    _incidentArea.dispose();
    _incidentDistrict.dispose();
    _incidentDescription.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final profile = await _api.getCommunitySafetyProfile();
    final guardians = await _api.getGuardianLinks();
    final wards = await _api.getGuardianWards();
    final incidents = await _api.getSubAdminIncidents();
    if (!mounted) return;
    setState(() {
      _profile = profile['profile'] is Map ? Map<String, dynamic>.from(profile['profile']) : {};
      _guardians = guardians;
      _wards = wards;
      _incidents = incidents;
      _loading = false;
    });
  }

  Future<void> _requestWomenVerification() async {
    final res = await _api.requestWomenForumVerification('female');
    _toast(res['message']?.toString() ?? 'Verification request submitted.');
    await _load();
  }

  Future<void> _addGuardian() async {
    if (_guardianPhone.text.trim().isEmpty) {
      _toast('Guardian phone is required.', error: true);
      return;
    }
    final res = await _api.createGuardianLink({
      'guardian_name': _guardianName.text.trim(),
      'guardian_phone': _guardianPhone.text.trim(),
      'relationship': 'parent',
      'permission_level': 'emergency_and_journey',
    });
    _toast(res['message']?.toString() ?? 'Guardian saved.', error: res['success'] != true);
    _guardianName.clear();
    _guardianPhone.clear();
    await _load();
  }

  Future<void> _submitIncident() async {
    if (_incidentDescription.text.trim().length < 10) {
      _toast('Please write at least 10 characters.', error: true);
      return;
    }
    final res = await _api.submitSubAdminIncident({
      'incident_type': _incidentType,
      'severity': _severity,
      'district': _incidentDistrict.text.trim(),
      'area_name': _incidentArea.text.trim(),
      'description': _incidentDescription.text.trim(),
      'source_type': 'area_volunteer',
    });
    _toast(res['message']?.toString() ?? 'Incident submitted.', error: res['success'] != true);
    _incidentDescription.clear();
    await _load();
  }

  void _toast(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.red : AppColors.green,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _topBar(),
                    const SizedBox(height: 16),
                    _womenForumCard(),
                    const SizedBox(height: 16),
                    _guardianCard(),
                    const SizedBox(height: 16),
                    _guardianWardsCard(),
                    const SizedBox(height: 16),
                    _subAdminIncidentCard(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _topBar() {
    return Row(children: [
      IconButton(
        onPressed: widget.onBack ?? () => widget.onNav?.call('home'),
        icon: const Icon(Icons.arrow_back),
      ),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Safety Hub', style: GoogleFonts.inter(fontSize: 21, fontWeight: FontWeight.w800)),
          Text('Women-only forum, guardians, and area reporting', style: GoogleFonts.inter(color: AppColors.ink2, fontSize: 12)),
        ]),
      ),
      IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
    ]);
  }

  Widget _womenForumCard() {
    final verified = _profile['women_forum_verified'] == true;
    final status = _profile['women_forum_verification_status']?.toString() ?? 'unverified';
    return _card(
      title: 'Women-only Forum Access',
      icon: Icons.verified_user_outlined,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _statusChip(verified ? 'Verified woman user' : 'Status: $status', verified ? AppColors.green : AppColors.amber),
        const SizedBox(height: 10),
        Text('Sister Circle is restricted to verified women users. Male or unverified accounts cannot enter the women forum.', style: GoogleFonts.inter(color: AppColors.ink2, fontSize: 13)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: ElevatedButton.icon(
            onPressed: verified ? () => widget.onNav?.call('community') : _requestWomenVerification,
            icon: Icon(verified ? Icons.groups_2_outlined : Icons.how_to_reg),
            label: Text(verified ? 'Open Sister Circle' : 'Request Verification'),
          )),
        ]),
      ]),
    );
  }

  Widget _guardianCard() {
    return _card(
      title: 'Parental / Guardian Control',
      icon: Icons.family_restroom,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Add your parent or guardian voluntarily. They can monitor SOS/journey safety based on your consent.', style: GoogleFonts.inter(color: AppColors.ink2, fontSize: 13)),
        const SizedBox(height: 12),
        TextField(controller: _guardianName, decoration: const InputDecoration(labelText: 'Guardian name', border: OutlineInputBorder())),
        const SizedBox(height: 10),
        TextField(controller: _guardianPhone, decoration: const InputDecoration(labelText: 'Guardian phone', border: OutlineInputBorder())),
        const SizedBox(height: 10),
        ElevatedButton.icon(onPressed: _addGuardian, icon: const Icon(Icons.add_call), label: const Text('Enable Guardian Access')),
        const SizedBox(height: 12),
        ..._guardians.take(3).map((g) => _miniRow(Icons.person_outline, '${g['guardian_name'] ?? 'Guardian'}', '${g['guardian_phone'] ?? ''} â€¢ ${g['permission_level'] ?? ''}')),
      ]),
    );
  }

  Widget _guardianWardsCard() {
    return _card(
      title: 'Guardian View',
      icon: Icons.visibility_outlined,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('If your phone is listed as a parent/guardian, wards will appear here.', style: GoogleFonts.inter(color: AppColors.ink2, fontSize: 13)),
        const SizedBox(height: 8),
        if (_wards.isEmpty) Text('No ward linked yet.', style: GoogleFonts.inter(color: AppColors.ink3)),
        ..._wards.take(5).map((w) => _miniRow(Icons.child_care, '${w['ward_name'] ?? 'Ward'}', 'Permission: ${w['permission_level'] ?? '-'}')),
      ]),
    );
  }

  Widget _subAdminIncidentCard() {
    final canSubmit = _profile['can_submit_area_incidents'] == true;
    return _card(
      title: 'Area Incident Reporting',
      icon: Icons.report_problem_outlined,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(canSubmit
            ? 'You are allowed to submit verified local incidents for admin review and risk dataset contribution.'
            : 'Only approved sub-admins or area volunteers can submit incidents. Admin can assign this role.',
            style: GoogleFonts.inter(color: AppColors.ink2, fontSize: 13)),
        if (canSubmit) ...[
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: DropdownButtonFormField<String>(
              initialValue: _incidentType,
              decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
              items: const ['harassment', 'stalking', 'unsafe_area', 'theft', 'transport_issue']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _incidentType = v ?? _incidentType),
            )),
            const SizedBox(width: 8),
            Expanded(child: DropdownButtonFormField<String>(
              initialValue: _severity,
              decoration: const InputDecoration(labelText: 'Severity', border: OutlineInputBorder()),
              items: const ['low', 'medium', 'high', 'critical']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _severity = v ?? _severity),
            )),
          ]),
          const SizedBox(height: 10),
          TextField(controller: _incidentDistrict, decoration: const InputDecoration(labelText: 'District', border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextField(controller: _incidentArea, decoration: const InputDecoration(labelText: 'Area name', border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextField(controller: _incidentDescription, minLines: 3, maxLines: 5, decoration: const InputDecoration(labelText: 'Incident details', border: OutlineInputBorder())),
          const SizedBox(height: 10),
          ElevatedButton.icon(onPressed: _submitIncident, icon: const Icon(Icons.cloud_upload_outlined), label: const Text('Submit for Review')),
          const SizedBox(height: 12),
          ..._incidents.take(4).map((i) => _miniRow(Icons.place_outlined, '${i['incident_type']} â€¢ ${i['severity']}', '${i['area_name'] ?? '-'} â€¢ ${i['verification_status'] ?? '-'}')),
        ],
      ]),
    );
  }

  Widget _card({required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(icon, color: AppColors.green), const SizedBox(width: 8), Expanded(child: Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800)))]),
        const SizedBox(height: 12),
        child,
      ]),
    );
  }

  Widget _statusChip(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(99)),
    child: Text(text, style: GoogleFonts.inter(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
  );

  Widget _miniRow(IconData icon, String title, String subtitle) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Row(children: [
      Icon(icon, size: 18, color: AppColors.ink2),
      const SizedBox(width: 8),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13)),
        Text(subtitle, style: GoogleFonts.inter(color: AppColors.ink2, fontSize: 12)),
      ])),
    ]),
  );
}
