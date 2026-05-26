import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class AdminManagementScreen extends StatefulWidget {
  final void Function(String route) onNav;
  final VoidCallback onBack;

  const AdminManagementScreen({super.key, required this.onNav, required this.onBack});

  @override
  State<AdminManagementScreen> createState() => _AdminManagementScreenState();
}

class _AdminManagementScreenState extends State<AdminManagementScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _userSearch = TextEditingController();
  final TextEditingController _rolePhone = TextEditingController();
  String _selectedRole = 'sub_admin';
  bool _loading = true;
  Map<String, dynamic> _overview = <String, dynamic>{};
  List<dynamic> _communityIncidents = <dynamic>[];
  List<dynamic> _safetyIncidents = <dynamic>[];
  List<dynamic> _womenQueue = <dynamic>[];
  List<dynamic> _users = <dynamic>[];
  List<dynamic> _cases = <dynamic>[];
  List<dynamic> _evidence = <dynamic>[];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _userSearch.dispose();
    _rolePhone.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    final overview = await _api.getAdminManagementOverview();
    final incidents = await _api.getAdminManagementCommunityIncidents();
    final women = await _api.getAdminManagementWomenVerification();
    final users = await _api.searchAdminManagementUsers(_userSearch.text.trim());
    final cases = await _api.getAdminManagementSafetyCases();
    final evidence = await _api.getAdminManagementEvidence();
    if (!mounted) return;
    setState(() {
      _overview = overview;
      _communityIncidents = _list(incidents['community_incidents']);
      _safetyIncidents = _list(incidents['safety_incidents']);
      _womenQueue = _list(women['users']);
      _users = _list(users['users']);
      _cases = _list(cases['cases']);
      _evidence = _list(evidence['items']);
      _loading = false;
    });
  }

  List<dynamic> _list(dynamic value) => value is List ? value : const [];
  Map<String, dynamic> _map(dynamic value) => value is Map<String, dynamic> ? value : (value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{});
  String _s(dynamic value, [String fallback = '—']) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  Future<void> _action(Future<Map<String, dynamic>> Function() call, String success) async {
    final res = await call();
    if (!mounted) return;
    final ok = res['success'] == true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? success : (res['message']?.toString() ?? 'Action failed.'))),
    );
    if (ok) await _loadAll();
  }

  Future<void> _assignRole() async {
    final phone = _rolePhone.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a phone number first.')));
      return;
    }
    await _action(
      () => _api.assignAdminManagementRole(phone: phone, role: _selectedRole),
      'Role assigned successfully.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = _map(_overview['stats']);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: const Text('Admin Management', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF172033),
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onBack),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAll)],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadAll,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _overviewCard(stats),
                    const SizedBox(height: 14),
                    _sectionTitle('Sub-admin incident review'),
                    ..._communityIncidents.take(6).map((e) => _incidentCard(_map(e), isCommunity: true)),
                    ..._safetyIncidents.take(6).map((e) => _incidentCard(_map(e), isCommunity: false)),
                    if (_communityIncidents.isEmpty && _safetyIncidents.isEmpty) _emptyCard('No incident review item found.'),
                    const SizedBox(height: 14),
                    _sectionTitle('Women forum verification'),
                    ..._womenQueue.take(8).map((e) => _womenCard(_map(e))),
                    if (_womenQueue.isEmpty) _emptyCard('No women verification request found.'),
                    const SizedBox(height: 14),
                    _sectionTitle('User role assignment'),
                    _roleCard(),
                    const SizedBox(height: 14),
                    _sectionTitle('Case review'),
                    ..._cases.take(6).map((e) => _caseCard(_map(e))),
                    if (_cases.isEmpty) _emptyCard('No case tracker item found.'),
                    const SizedBox(height: 14),
                    _sectionTitle('Evidence review'),
                    ..._evidence.take(6).map((e) => _evidenceCard(_map(e))),
                    if (_evidence.isEmpty) _emptyCard('No evidence item found.'),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _overviewCard(Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _box(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Management Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        Wrap(spacing: 10, runSpacing: 10, children: [
          _pill('Incidents', _s(stats['community_incidents_pending'])),
          _pill('Women verification', _s(stats['women_verification_pending'])),
          _pill('Sub-admins', _s(stats['sub_admins'])),
          _pill('Open cases', _s(stats['open_cases'])),
          _pill('Evidence', _s(stats['evidence_items'])),
        ]),
      ]),
    );
  }

  Widget _incidentCard(Map<String, dynamic> m, {required bool isCommunity}) {
    final id = _s(m['id'], '');
    final title = isCommunity ? _s(m['incident_type'], 'Community incident') : _s(m['report_type'], 'Safety report');
    final status = isCommunity ? _s(m['verification_status'], 'pending_review') : _s(m['status'], 'pending_review');
    return _card(
      icon: Icons.report_problem_outlined,
      title: title,
      subtitle: '${_s(m['severity'], 'medium')} • ${_s(m['area_name'], _s(m['district'], 'Unknown area'))} • $status',
      body: _s(m['description'], 'No details.'),
      actions: [
        TextButton(onPressed: id.isEmpty ? null : () => _action(() => _api.approveAdminManagementIncident(id), 'Incident approved.'), child: const Text('Approve')),
        TextButton(onPressed: id.isEmpty ? null : () => _action(() => _api.rejectAdminManagementIncident(id), 'Incident rejected.'), child: const Text('Reject')),
      ],
    );
  }

  Widget _womenCard(Map<String, dynamic> m) {
    final id = _s(m['id'], '');
    return _card(
      icon: Icons.verified_user_outlined,
      title: _s(m['name'], 'Unknown user'),
      subtitle: '${_s(m['phone'], 'hidden')} • ${_s(m['gender'], 'unknown')} • ${_s(m['women_forum_verification_status'], 'unverified')}',
      body: 'Approve to unlock women-only forum access. Reject if identity/community verification is not sufficient.',
      actions: [
        TextButton(onPressed: id.isEmpty ? null : () => _action(() => _api.approveAdminManagementWomenVerification(id), 'Verification approved.'), child: const Text('Approve')),
        TextButton(onPressed: id.isEmpty ? null : () => _action(() => _api.rejectAdminManagementWomenVerification(id), 'Verification rejected.'), child: const Text('Reject')),
      ],
    );
  }

  Widget _roleCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _box(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: TextField(
              controller: _rolePhone,
              decoration: const InputDecoration(labelText: 'User phone', border: OutlineInputBorder()),
            ),
          ),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: _selectedRole,
            items: const [
              DropdownMenuItem(value: 'user', child: Text('User')),
              DropdownMenuItem(value: 'sub_admin', child: Text('Sub-admin')),
              DropdownMenuItem(value: 'area_volunteer', child: Text('Area volunteer')),
              DropdownMenuItem(value: 'moderator', child: Text('Moderator')),
              DropdownMenuItem(value: 'admin', child: Text('Admin')),
            ],
            onChanged: (v) => setState(() => _selectedRole = v ?? _selectedRole),
          ),
        ]),
        const SizedBox(height: 10),
        SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _assignRole, icon: const Icon(Icons.manage_accounts_outlined), label: const Text('Assign role'))),
        const SizedBox(height: 10),
        TextField(
          controller: _userSearch,
          decoration: InputDecoration(
            labelText: 'Search users',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: _loadAll),
          ),
        ),
        const SizedBox(height: 8),
        ..._users.take(5).map((e) {
          final m = _map(e);
          return ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(_s(m['name'], 'Unknown')),
            subtitle: Text('${_s(m['phone'], 'hidden')} • ${_s(m['role'], 'user')}'),
            trailing: TextButton(
              onPressed: () => setState(() => _rolePhone.text = _s(m['phone'], '')),
              child: const Text('Use'),
            ),
          );
        }),
      ]),
    );
  }

  Widget _caseCard(Map<String, dynamic> m) {
    final id = _s(m['id'], '');
    return _card(
      icon: Icons.folder_copy_outlined,
      title: _s(m['case_title'], 'Case tracker'),
      subtitle: '${_s(m['case_type'], 'case')} • ${_s(m['status'], 'draft')} • ${_s(m['police_station'], 'No station')}',
      body: _s(m['notes'], 'No notes.'),
      actions: [
        TextButton(onPressed: id.isEmpty ? null : () => _action(() => _api.updateAdminManagementCaseStatus(id, 'in_review'), 'Case marked in review.'), child: const Text('In review')),
        TextButton(onPressed: id.isEmpty ? null : () => _action(() => _api.updateAdminManagementCaseStatus(id, 'closed'), 'Case closed.'), child: const Text('Close')),
      ],
    );
  }

  Widget _evidenceCard(Map<String, dynamic> m) {
    final id = _s(m['id'], '');
    return _card(
      icon: Icons.lock_outline,
      title: _s(m['title'], 'Evidence item'),
      subtitle: '${_s(m['evidence_type'], 'note')} • ${_s(m['privacy_level'], 'private')}',
      body: _s(m['description'], 'No description.'),
      actions: [
        TextButton(onPressed: id.isEmpty ? null : () => _action(() => _api.updateAdminManagementEvidenceStatus(id, 'reviewed'), 'Evidence reviewed.'), child: const Text('Mark reviewed')),
      ],
    );
  }

  Widget _card({required IconData icon, required String title, required String subtitle, required String body, required List<Widget> actions}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: _box(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: const Color(0xFF2563EB)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
          ])),
        ]),
        const SizedBox(height: 8),
        Text(body, maxLines: 3, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: actions),
      ]),
    );
  }

  Widget _emptyCard(String text) => Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: _box(),
        child: Text(text, style: const TextStyle(color: Color(0xFF64748B))),
      );

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
      );

  Widget _pill(String label, String value) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(14)),
        child: Text('$label: $value', style: const TextStyle(fontWeight: FontWeight.w700)),
      );

  BoxDecoration _box() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7EAF1)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .04), blurRadius: 12, offset: const Offset(0, 6))],
      );
}
