import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/api_service.dart';
import '../../utils/constants.dart';

class EmergencyToolsScreen extends StatefulWidget {
  final void Function(String) onNav;
  final VoidCallback onBack;

  const EmergencyToolsScreen({super.key, required this.onNav, required this.onBack});

  @override
  State<EmergencyToolsScreen> createState() => _EmergencyToolsScreenState();
}

class _EmergencyToolsScreenState extends State<EmergencyToolsScreen> {
  final _api = ApiService();
  bool _loading = true;
  bool _submitting = false;
  Map<String, dynamic> _dashboard = {};
  List<dynamic> _helplines = [];

  final _witnessType = TextEditingController(text: 'harassment');
  final _witnessArea = TextEditingController(text: 'Mirpur 10');
  final _witnessDescription = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _witnessType.dispose();
    _witnessArea.dispose();
    _witnessDescription.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final dashboard = await _api.getEmergencyToolsDashboard();
    final helplines = await _api.getEmergencyHelplines();
    if (!mounted) return;
    setState(() {
      _dashboard = dashboard;
      _helplines = helplines;
      _loading = false;
    });
  }

  Future<void> _triggerDecoyCall() async {
    setState(() => _submitting = true);
    final res = await _api.createDecoyCall({
      'caller_name': 'Mom',
      'caller_phone': '+8801XXXXXXXXX',
      'delay_seconds': 2,
      'reason': 'User requested a safe exit from an uncomfortable situation.',
    });
    if (!mounted) return;
    setState(() => _submitting = false);

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Decoy call will appear in 2 seconds.')));
      Timer(const Duration(seconds: 2), _showFakeIncomingCall);
      await _load();
    } else {
      _toast(res['message']?.toString() ?? 'Could not prepare decoy call.');
    }
  }

  void _showFakeIncomingCall() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: AppColors.dark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const CircleAvatar(radius: 42, backgroundColor: AppColors.green, child: Icon(Icons.person, color: Colors.white, size: 42)),
            const SizedBox(height: 14),
            Text('Mom', style: GoogleFonts.inter(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('Incoming call...', style: GoogleFonts.inter(color: Colors.white70)),
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              FloatingActionButton(
                heroTag: 'decline_decoy',
                backgroundColor: AppColors.red,
                onPressed: () => Navigator.pop(context),
                child: const Icon(Icons.call_end, color: Colors.white),
              ),
              FloatingActionButton(
                heroTag: 'accept_decoy',
                backgroundColor: AppColors.green,
                onPressed: () => Navigator.pop(context),
                child: const Icon(Icons.call, color: Colors.white),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  Future<void> _logStealth(String action) async {
    setState(() => _submitting = true);
    final res = await _api.logStealthEvent({
      'action': action,
      'note': action == 'quick_exit' ? 'User used quick exit from SafeHerBD.' : 'User enabled stealth safety mode.',
    });
    if (!mounted) return;
    setState(() => _submitting = false);
    _toast(res['message']?.toString() ?? 'Stealth event saved.');
    if (action == 'quick_exit') widget.onBack();
    await _load();
  }

  Future<void> _submitWitnessReport() async {
    if (_witnessDescription.text.trim().length < 10) {
      _toast('Please add a short witness description.');
      return;
    }
    setState(() => _submitting = true);
    final res = await _api.createWitnessReport({
      'incident_type': _witnessType.text.trim(),
      'area_name': _witnessArea.text.trim(),
      'description': _witnessDescription.text.trim(),
      'anonymous': true,
    });
    if (!mounted) return;
    setState(() => _submitting = false);
    if (res['success'] == true) {
      _witnessDescription.clear();
      _toast('Witness report submitted for review.');
      await _load();
    } else {
      _toast(res['message']?.toString() ?? 'Could not submit witness report.');
    }
  }

  Future<void> _sendAllyAlert() async {
    setState(() => _submitting = true);
    final res = await _api.createAllyAlert({
      'message': 'I may need nearby support. Please check on me if possible.',
    });
    if (!mounted) return;
    setState(() => _submitting = false);
    final count = res['notified_allies_count'] ?? 0;
    _toast(res['success'] == true ? 'Ally alert queued. Allies: $count' : 'Could not queue ally alert.');
    await _load();
  }

  Future<void> _callNumber(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _toast('Dial $number from your phone.');
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  int _stat(String key) {
    final stats = _dashboard['stats'];
    if (stats is Map && stats[key] is num) return (stats[key] as num).round();
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          color: AppColors.green,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _header(),
              const SizedBox(height: 14),
              if (_loading) const LinearProgressIndicator(minHeight: 3),
              _statsGrid(),
              const SizedBox(height: 14),
              _decoyCard(),
              const SizedBox(height: 14),
              _stealthCard(),
              const SizedBox(height: 14),
              _witnessCard(),
              const SizedBox(height: 14),
              _alliesCard(),
              const SizedBox(height: 14),
              _helplineCard(),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Row(children: [
      IconButton(onPressed: widget.onBack, icon: const Icon(Icons.arrow_back)),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Stealth & Emergency Tools', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.ink)),
          Text('Decoy call, quick exit, witness mode, and allies nearby', style: GoogleFonts.inter(fontSize: 12, color: AppColors.ink2)),
        ]),
      ),
      IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
    ]);
  }

  Widget _statsGrid() {
    final items = [
      ('Decoy', _stat('decoy_calls'), Icons.phone_in_talk_outlined, AppColors.green),
      ('Stealth', _stat('stealth_events'), Icons.visibility_off_outlined, AppColors.blue),
      ('Witness', _stat('witness_reports'), Icons.report_gmailerrorred_outlined, AppColors.amber),
      ('Allies', _stat('ally_alerts'), Icons.groups_outlined, AppColors.red),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.75, crossAxisSpacing: 10, mainAxisSpacing: 10),
      itemBuilder: (_, i) {
        final item = items[i];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
          child: Row(children: [
            CircleAvatar(backgroundColor: item.$4.withValues(alpha: .10), child: Icon(item.$3, color: item.$4)),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(item.$2.toString(), style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.ink)),
              Text(item.$1, style: GoogleFonts.inter(fontSize: 12, color: AppColors.ink2)),
            ]),
          ]),
        );
      },
    );
  }

  Widget _decoyCard() => _card(
        icon: Icons.phone_in_talk_outlined,
        title: 'Decoy Call',
        subtitle: 'Create a fake incoming call to safely leave an uncomfortable situation.',
        child: _primaryButton('Start decoy call', _submitting ? null : _triggerDecoyCall, icon: Icons.call),
      );

  Widget _stealthCard() => _card(
        icon: Icons.visibility_off_outlined,
        title: 'Stealth Mode & Quick Exit',
        subtitle: 'Log stealth mode or instantly return to the safe home screen.',
        child: Row(children: [
          Expanded(child: _outlineButton('Enable stealth', _submitting ? null : () => _logStealth('stealth_enabled'))),
          const SizedBox(width: 10),
          Expanded(child: _primaryButton('Quick exit', _submitting ? null : () => _logStealth('quick_exit'), icon: Icons.exit_to_app)),
        ]),
      );

  Widget _witnessCard() => _card(
        icon: Icons.report_gmailerrorred_outlined,
        title: 'Witness Mode',
        subtitle: 'Report unsafe behavior as an anonymous bystander for admin review.',
        child: Column(children: [
          TextField(controller: _witnessType, decoration: const InputDecoration(labelText: 'Incident type', border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextField(controller: _witnessArea, decoration: const InputDecoration(labelText: 'Area name', border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextField(controller: _witnessDescription, minLines: 2, maxLines: 4, decoration: const InputDecoration(labelText: 'What did you witness?', border: OutlineInputBorder())),
          const SizedBox(height: 10),
          _primaryButton('Submit witness report', _submitting ? null : _submitWitnessReport, icon: Icons.send_outlined),
        ]),
      );

  Widget _alliesCard() => _card(
        icon: Icons.groups_outlined,
        title: 'Allies Nearby',
        subtitle: 'Ask trusted guardians/allies for nearby support. Works best after adding guardians.',
        child: _primaryButton('Alert allies nearby', _submitting ? null : _sendAllyAlert, icon: Icons.group_add_outlined),
      );

  Widget _helplineCard() {
    return _card(
      icon: Icons.support_agent_outlined,
      title: 'Helpline Network',
      subtitle: 'Emergency and legal support numbers for Bangladesh.',
      child: Column(
        children: _helplines.isEmpty
            ? [Text('Helplines loading...', style: GoogleFonts.inter(color: AppColors.ink2))]
            : _helplines.map((item) {
                final m = item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{};
                final number = m['number']?.toString() ?? '';
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.call_outlined, color: AppColors.green),
                  title: Text(m['name']?.toString() ?? 'Helpline', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                  subtitle: Text('${m['category'] ?? ''} • $number'),
                  trailing: TextButton(onPressed: number.isEmpty ? null : () => _callNumber(number), child: const Text('Call')),
                );
              }).toList(),
      ),
    );
  }

  Widget _card({required IconData icon, required String title, required String subtitle, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(backgroundColor: AppColors.greenSoft, child: Icon(icon, color: AppColors.green)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: AppColors.ink)),
            const SizedBox(height: 2),
            Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: AppColors.ink2)),
          ])),
        ]),
        const SizedBox(height: 12),
        child,
      ]),
    );
  }

  Widget _primaryButton(String label, VoidCallback? onTap, {IconData? icon}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        onPressed: onTap,
        icon: Icon(icon ?? Icons.check),
        label: Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
      ),
    );
  }

  Widget _outlineButton(String label, VoidCallback? onTap) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
      onPressed: onTap,
      child: Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
    );
  }
}
