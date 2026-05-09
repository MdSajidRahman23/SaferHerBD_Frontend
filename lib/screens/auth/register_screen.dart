import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../utils/constants.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _pass = TextEditingController();
  final _passConf = TextEditingController();
  final _pin = TextEditingController();
  final _district = TextEditingController(text: 'Dhaka');
  final _division = TextEditingController(text: 'Dhaka');
  final _auth = AuthService();
  bool _loading = false;
  String _lang = 'bn';

  Future<void> _register() async {
    if (_name.text.trim().isEmpty || _phone.text.trim().isEmpty || _pass.text.isEmpty) {
      _toast('All fields are required', error: true);
      return;
    }
    if (_pass.text.length < 6) { _toast('Password min 6 chars', error: true); return; }
    if (_pass.text != _passConf.text) { _toast("Passwords don't match", error: true); return; }
    if (_pin.text.length != 6) { _toast('PIN must be 6 digits', error: true); return; }

    setState(() => _loading = true);
    final res = await _auth.register({
      'name': _name.text.trim(),
      'phone': _phone.text.trim(),
      'password': _pass.text,
      'password_confirmation': _passConf.text,
      'emergency_pin': _pin.text,
      'preferred_language': _lang,
      'division': _division.text.trim(),
      'district': _district.text.trim(),
    });
    if (!mounted) return;
    setState(() => _loading = false);

    if (res['success'] == true) {
      NotificationService().registerToken();
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } else {
      _toast(res['message']?.toString() ?? 'Registration failed', error: true);
    }
  }

  void _toast(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.red : AppColors.green,
    ));
  }

  @override
  void dispose() {
    _name.dispose(); _phone.dispose(); _pass.dispose();
    _passConf.dispose(); _pin.dispose();
    _district.dispose(); _division.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: AppColors.ink),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('Create your account',
                style: GoogleFonts.inter(color: AppColors.ink, fontWeight: FontWeight.w800, fontSize: 24)),
            const SizedBox(height: 4),
            Text('Join the SafeHer community',
                style: GoogleFonts.inter(color: AppColors.ink2, fontSize: 13)),
            const SizedBox(height: 24),

            _Field(controller: _name, label: 'Full name', icon: Icons.person_outline),
            const SizedBox(height: 12),
            _Field(controller: _phone, label: 'Phone (+8801…)', icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\- ]'))]),
            const SizedBox(height: 12),
            _Field(controller: _pass, label: 'Password (≥6)', icon: Icons.lock_outline, obscure: true),
            const SizedBox(height: 12),
            _Field(controller: _passConf, label: 'Confirm password', icon: Icons.lock_outline, obscure: true),
            const SizedBox(height: 12),
            _Field(controller: _pin, label: 'Emergency PIN (6 digits)', icon: Icons.shield_outlined,
                obscure: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _Field(controller: _division, label: 'Division', icon: Icons.location_on_outlined)),
              const SizedBox(width: 10),
              Expanded(child: _Field(controller: _district, label: 'District', icon: Icons.place_outlined)),
            ]),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                const Icon(Icons.translate, color: AppColors.ink2),
                const SizedBox(width: 12),
                Text('Language:',
                    style: GoogleFonts.inter(color: AppColors.ink2, fontSize: 13)),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text('বাংলা'),
                  selected: _lang == 'bn',
                  onSelected: (_) => setState(() => _lang = 'bn'),
                ),
                const SizedBox(width: 6),
                ChoiceChip(
                  label: const Text('English'),
                  selected: _lang == 'en',
                  onSelected: (_) => setState(() => _lang = 'en'),
                ),
              ]),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _loading ? null : _register,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : Text('Create Account',
                        style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text('By continuing, you agree to SafeHer\'s safe use policy.',
                  style: GoogleFonts.inter(color: AppColors.ink3, fontSize: 11)),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.keyboardType,
    this.inputFormatters,
  });
  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
}
