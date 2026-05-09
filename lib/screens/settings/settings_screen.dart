import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';

class SettingsScreen extends StatefulWidget {
  final void Function(String) onNav;
  final VoidCallback onBack;
  const SettingsScreen({super.key, required this.onNav, required this.onBack});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _api = ApiService();
  final _auth = AuthService();

  String _lang = 'en';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final u = await _api.getProfile();
    if (!mounted) return;
    setState(() {
      _lang = u?['preferred_language']?.toString() ?? 'en';
      _loading = false;
    });
  }

  Future<void> _setLang(String lang) async {
    setState(() => _lang = lang);
    final ok = await _api.updateProfile({'preferred_language': lang});
    if (!ok && mounted) {
      _toast('Could not save preference', error: true);
    }
  }

  Future<void> _callHelpline(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
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
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.ink), onPressed: widget.onBack),
        title: Text('Settings',
            style: GoogleFonts.inter(color: AppColors.ink, fontWeight: FontWeight.w700, fontSize: 17)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.green))
          : ListView(
              padding: const EdgeInsets.all(14),
              children: [
                _section('Account', [
                  _Tile(icon: Icons.person_outline, label: 'Profile',
                      onTap: () => Navigator.pushNamed(context, '/profile')),
                  _Tile(icon: Icons.history, label: 'SOS History',
                      onTap: () => Navigator.pushNamed(context, '/sos-history')),
                  _Tile(icon: Icons.notifications_outlined, label: 'Notifications',
                      onTap: () => Navigator.pushNamed(context, '/notifications')),
                ]),
                const SizedBox(height: 14),
                _section('Language', [
                  _LangTile(label: 'English', value: 'en', current: _lang, onTap: () => _setLang('en')),
                  _LangTile(label: 'বাংলা',    value: 'bn', current: _lang, onTap: () => _setLang('bn')),
                ]),
                const SizedBox(height: 14),
                _section('Crisis Helplines', [
                  _Tile(icon: Icons.phone, label: '109 — মহিলা ও শিশু সহায়তা', color: AppColors.red,
                      onTap: () => _callHelpline('109')),
                  _Tile(icon: Icons.phone, label: '999 — National Emergency', color: AppColors.red,
                      onTap: () => _callHelpline('999')),
                  _Tile(icon: Icons.phone, label: 'Kaan Pete Roi (mental health)',
                      onTap: () => _callHelpline('9612119911')),
                ]),
                const SizedBox(height: 14),
                _section('Session', [
                  _Tile(icon: Icons.logout, label: 'Sign Out', color: AppColors.red, onTap: _logout),
                ]),
                const SizedBox(height: 28),
                Center(
                  child: Text('SafeHer Bangladesh • v1.0.0\n'
                              '© 2026 DIU CSE',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(color: AppColors.ink3, fontSize: 11, height: 1.5)),
                ),
                const SizedBox(height: 28),
              ],
            ),
    );
  }

  Widget _section(String title, List<Widget> children) => Container(
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
                  color: AppColors.ink3, fontWeight: FontWeight.w700, fontSize: 11, letterSpacing: 0.6)),
        ),
      ),
      ...children,
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
          Expanded(
            child: Text(label,
                style: GoogleFonts.hindSiliguri(color: c, fontWeight: FontWeight.w600, fontSize: 13.5)),
          ),
          const Icon(Icons.chevron_right, color: AppColors.ink3, size: 18),
        ]),
      ),
    );
  }
}

class _LangTile extends StatelessWidget {
  final String label, value, current;
  final VoidCallback onTap;
  const _LangTile({required this.label, required this.value, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final selected = current == value;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(children: [
          Icon(selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: selected ? AppColors.green : AppColors.ink3, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(label,
              style: GoogleFonts.hindSiliguri(
                  color: AppColors.ink, fontWeight: FontWeight.w600, fontSize: 13.5))),
        ]),
      ),
    );
  }
}
