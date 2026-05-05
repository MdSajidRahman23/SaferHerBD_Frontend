import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import '../../widgets/gov_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _auth      = AuthService();
  final _nameCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _pinCtrl   = TextEditingController();
  bool _loading    = false;
  bool _showPass   = false;
  String? _error;

  Future<void> _register() async {
    if (_nameCtrl.text.trim().isEmpty ||
        _phoneCtrl.text.trim().isEmpty ||
        _passCtrl.text.isEmpty) {
      setState(() => _error = 'সব ঘর পূরণ করুন');
      return;
    }
    if (_pinCtrl.text.length != 6) {
      setState(() => _error = 'Emergency PIN অবশ্যই ৬ সংখ্যার হতে হবে');
      return;
    }
    if (_passCtrl.text.length < 6) {
      setState(() => _error = 'Password কমপক্ষে ৬ অক্ষরের হতে হবে');
      return;
    }

    setState(() { _loading = true; _error = null; });
    final res = await _auth.register(
      name:         _nameCtrl.text.trim(),
      phone:        _phoneCtrl.text.trim(),
      password:     _passCtrl.text,
      emergencyPin: _pinCtrl.text,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (res['token'] != null) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      // Show specific validation errors from Laravel
      String msg = res['message'] ?? 'রেজিস্ট্রেশন ব্যর্থ';
      if (res['errors'] != null) {
        final errors = res['errors'] as Map;
        msg = errors.values.first[0] ?? msg;
      }
      setState(() => _error = msg);
    }
  }

  @override void dispose() {
    _nameCtrl.dispose(); _phoneCtrl.dispose();
    _passCtrl.dispose(); _pinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.gd,
        title: Text('Create Account', style: GoogleFonts.dmSans(
            color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [

          const SafeHerLogo(size: 50),
          const SizedBox(height: 6),
          Text('নতুন অ্যাকাউন্ট তৈরি করুন',
              style: GoogleFonts.hindSiliguri(
                  color: AppColors.t2, fontSize: 12)),
          const SizedBox(height: 20),

          if (_error != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.r.withOpacity(0.08),
                border: Border.all(color: AppColors.r.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                Icon(Icons.error_outline, size: 16, color: AppColors.r),
                const SizedBox(width: 6),
                Expanded(child: Text(_error!,
                    style: GoogleFonts.hindSiliguri(
                        color: AppColors.r, fontSize: 12))),
              ]),
            ),

          // Personal info card
          GovCard(child: Column(children: [
            TextField(
              controller: _nameCtrl,
              style: TextStyle(color: AppColors.t1),
              decoration: InputDecoration(
                labelText: 'Full Name / পুরো নাম',
                prefixIcon: Icon(Icons.person_outline,
                    color: AppColors.t3, size: 20),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              style: TextStyle(color: AppColors.t1),
              decoration: InputDecoration(
                labelText: 'Phone / ফোন নম্বর',
                prefixIcon: Icon(Icons.phone_rounded,
                    color: AppColors.t3, size: 20),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passCtrl,
              obscureText: !_showPass,
              style: TextStyle(color: AppColors.t1),
              decoration: InputDecoration(
                labelText: 'Password / পাসওয়ার্ড',
                prefixIcon: Icon(Icons.lock_outline_rounded,
                    color: AppColors.t3, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _showPass ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.t3, size: 20,
                  ),
                  onPressed: () => setState(() => _showPass = !_showPass),
                ),
              ),
            ),
          ])),
          const SizedBox(height: 12),

          // Emergency PIN card
          GovCard(
            borderColor: AppColors.r.withOpacity(0.3),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.emergency_rounded, color: AppColors.r, size: 18),
                const SizedBox(width: 6),
                Text('Emergency PIN',
                    style: GoogleFonts.dmSans(
                        color: AppColors.r,
                        fontWeight: FontWeight.w700, fontSize: 14)),
              ]),
              const SizedBox(height: 4),
              Text('ভুল PIN দিলে স্বয়ংক্রিয়ভাবে SOS trigger হবে। ৬ সংখ্যার PIN দিন।',
                  style: GoogleFonts.hindSiliguri(
                      color: AppColors.t2, fontSize: 11, height: 1.5)),
              const SizedBox(height: 12),
              TextField(
                controller: _pinCtrl,
                keyboardType: TextInputType.number,
                maxLength: 6,
                obscureText: true,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: TextStyle(
                    color: AppColors.t1, fontSize: 22,
                    letterSpacing: 10, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  hintText: '● ● ● ● ● ●',
                  hintStyle: TextStyle(
                      color: AppColors.t3.withOpacity(0.5),
                      letterSpacing: 8, fontSize: 18),
                  counterText: '',
                  prefixIcon: Icon(Icons.pin_outlined,
                      color: AppColors.t3, size: 20),
                ),
                textAlign: TextAlign.center,
              ),
            ]),
          ),
          const SizedBox(height: 22),

          SizedBox(
            width: double.infinity, height: 48,
            child: ElevatedButton(
              onPressed: _loading ? null : _register,
              child: _loading
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('রেজিস্ট্রেশন করুন / Register',
                      style: GoogleFonts.hindSiliguri(
                          fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 12),

          TextButton(
            onPressed: () => Navigator.pop(context),
            child: RichText(text: TextSpan(children: [
              TextSpan(text: 'আগে থেকে অ্যাকাউন্ট আছে? ',
                  style: GoogleFonts.hindSiliguri(color: AppColors.t3)),
              TextSpan(text: 'লগইন করুন',
                  style: GoogleFonts.hindSiliguri(
                      color: AppColors.g, fontWeight: FontWeight.w600)),
            ])),
          ),
          const SizedBox(height: 16),
          const GovFooter(),
        ]),
      ),
    );
  }
}
