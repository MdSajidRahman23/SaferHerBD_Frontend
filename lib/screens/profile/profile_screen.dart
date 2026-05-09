import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _api = ApiService();
  final _auth = AuthService();

  bool _loading = true;
  Map<String, dynamic>? _user;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _api.getProfile();
    if (!mounted) return;
    setState(() {
      _user = data;
      _loading = false;
    });
  }

  Future<void> _editName() async {
    final ctrl = TextEditingController(text: _user?['name']?.toString() ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Name', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'Your name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.green),
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty && mounted) {
      final ok = await _api.updateProfile({'name': result});
      _toast(ok ? 'Name updated' : 'Update failed', error: !ok);
      if (ok) _load();
    }
  }

  Future<void> _changePassword() async {
    final cur = TextEditingController(), neu = TextEditingController(), conf = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Change Password', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: cur, obscureText: true, decoration: const InputDecoration(hintText: 'Current password')),
          TextField(controller: neu, obscureText: true, decoration: const InputDecoration(hintText: 'New password (≥6)')),
          TextField(controller: conf, obscureText: true, decoration: const InputDecoration(hintText: 'Confirm new password')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.green),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Update', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    if (neu.text.length < 6) { _toast('Min 6 characters', error: true); return; }
    if (neu.text != conf.text) { _toast("Passwords don't match", error: true); return; }

    final res = await _api.changePassword(currentPassword: cur.text, newPassword: neu.text);
    _toast(res['message']?.toString() ?? 'Done', error: res['success'] != true);
  }

  Future<void> _changePin() async {
    final cur = TextEditingController(), pin = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Change Emergency PIN', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: cur, obscureText: true, decoration: const InputDecoration(hintText: 'Current password')),
          TextField(
            controller: pin, obscureText: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
            decoration: const InputDecoration(hintText: 'New 6-digit PIN'),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.green),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Update', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    if (pin.text.length != 6) { _toast('PIN must be 6 digits', error: true); return; }
    final res = await _api.changeEmergencyPin(currentPassword: cur.text, newPin: pin.text);
    _toast(res['message']?.toString() ?? 'Done', error: res['success'] != true);
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Sign out?', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: const Text("You'll need to log in again to access your account."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _auth.logout();
    if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  void _toast(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.red : AppColors.green,
      duration: const Duration(seconds: 2),
    ));
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
        title: Text('Profile',
            style: GoogleFonts.inter(color: AppColors.ink, fontWeight: FontWeight.w700, fontSize: 17)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.green))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.green,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildStats(),
                  const SizedBox(height: 20),
                  _buildSection('Account', [
                    _Tile(icon: Icons.person_outline, label: 'Edit Name', onTap: _editName),
                    _Tile(icon: Icons.lock_outline, label: 'Change Password', onTap: _changePassword),
                    _Tile(icon: Icons.shield_outlined, label: 'Change Emergency PIN', onTap: _changePin),
                  ]),
                  const SizedBox(height: 14),
                  _buildSection('History', [
                    _Tile(icon: Icons.history, label: 'SOS History',
                        onTap: () => Navigator.pushNamed(context, '/sos-history')),
                    _Tile(icon: Icons.notifications_outlined, label: 'Notifications',
                        onTap: () => Navigator.pushNamed(context, '/notifications')),
                  ]),
                  const SizedBox(height: 14),
                  _buildSection('Session', [
                    _Tile(icon: Icons.logout, label: 'Sign Out', color: AppColors.red, onTap: _logout),
                  ]),
                  const SizedBox(height: 30),
                  Center(child: Text('SafeHer Bangladesh • v1.0.0',
                      style: GoogleFonts.inter(color: AppColors.ink3, fontSize: 11))),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    final initials = _initials(_user?['name']?.toString() ?? 'U');
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.green, AppColors.greenDeep],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: Colors.white24,
          child: Text(initials,
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_user?['name']?.toString() ?? 'User',
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17)),
            const SizedBox(height: 2),
            Text(_user?['phone']?.toString() ?? '',
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 12.5)),
            if ((_user?['district'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 2),
              Text('${_user!['district']}, ${_user!['division'] ?? ''}',
                  style: GoogleFonts.inter(color: Colors.white60, fontSize: 11.5)),
            ],
          ]),
        ),
      ]),
    );
  }

  Widget _buildStats() {
    final contacts = _user?['contacts_count'] ?? 0;
    final sosCount = _user?['sos_count'] ?? 0;
    return Row(children: [
      Expanded(child: _StatCard(label: 'Contacts', value: '$contacts', icon: Icons.people_outline)),
      const SizedBox(width: 10),
      Expanded(child: _StatCard(label: 'SOS Alerts', value: '$sosCount', icon: Icons.shield_outlined)),
      const SizedBox(width: 10),
      Expanded(child: _StatCard(
        label: 'Language',
        value: (_user?['preferred_language'] ?? 'en').toString().toUpperCase(),
        icon: Icons.translate,
      )),
    ]);
  }

  Widget _buildSection(String title, List<Widget> tiles) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(title,
                  style: GoogleFonts.inter(
                      color: AppColors.ink3,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: 0.6)),
            ),
          ),
          ...tiles,
        ]),
      );

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    final first = parts[0][0];
    final last = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _StatCard({required this.label, required this.value, required this.icon});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: AppColors.green, size: 18),
          const SizedBox(height: 6),
          Text(value,
              style: GoogleFonts.inter(color: AppColors.ink, fontWeight: FontWeight.w800, fontSize: 17)),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.inter(color: AppColors.ink3, fontSize: 11)),
        ]),
      );
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _Tile({required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.ink;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(children: [
          Icon(icon, color: c, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(label,
              style: GoogleFonts.inter(color: c, fontWeight: FontWeight.w600, fontSize: 13.5))),
          const Icon(Icons.chevron_right, color: AppColors.ink3, size: 18),
        ]),
      ),
    );
  }
}
