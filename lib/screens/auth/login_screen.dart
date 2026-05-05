import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import '../../widgets/gov_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth      = AuthService();
  final _phoneCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _loading    = false;
  bool _showPass   = false;
  String? _error;

  Future<void> _login() async {
    if (_phoneCtrl.text.trim().isEmpty || _passCtrl.text.isEmpty) {
      setState(() => _error = 'সব ঘর পূরণ করুন');
      return;
    }
    setState(() { _loading = true; _error = null; });
    final res = await _auth.login(_phoneCtrl.text.trim(), _passCtrl.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (res['token'] != null) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      setState(() => _error = res['message'] ?? 'লগইন ব্যর্থ — তথ্য পরীক্ষা করুন');
    }
  }

  @override void dispose() {
    _phoneCtrl.dispose(); _passCtrl.dispose(); super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(child: SingleChildScrollView(
        child: Column(children: [

          // Hero header
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [AppColors.gdd, AppColors.gd, AppColors.g],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 36, 24, 36),
            child: Column(children: [
              const SafeHerLogo(size: 56, light: true),
              const SizedBox(height: 18),
              Text('স্বাগতম', style: GoogleFonts.hindSiliguri(
                  color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
              Text('Welcome back to SafeHerBD',
                  style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 13)),
            ]),
          ),
          const SizedBox(height: 28),

          // Form card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: GovCard(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                Text('লগইন করুন', style: GoogleFonts.hindSiliguri(
                    color: AppColors.t1, fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Sign in to continue',
                    style: GoogleFonts.dmSans(color: AppColors.t3, fontSize: 12)),
                const SizedBox(height: 18),

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

                TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: TextStyle(color: AppColors.t1),
                  decoration: InputDecoration(
                    labelText: 'Phone Number / ফোন নম্বর',
                    prefixIcon: Icon(Icons.phone_rounded, color: AppColors.t3, size: 20),
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
                  onSubmitted: (_) => _login(),
                ),
                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity, height: 48,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _login,
                    child: _loading
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text('লগইন করুন / Sign In',
                            style: GoogleFonts.hindSiliguri(
                                fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 12),

                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/register'),
                  child: RichText(text: TextSpan(children: [
                    TextSpan(text: 'নতুন অ্যাকাউন্ট নেই? ',
                        style: GoogleFonts.hindSiliguri(color: AppColors.t3)),
                    TextSpan(text: 'রেজিস্ট্রেশন করুন',
                        style: GoogleFonts.hindSiliguri(
                            color: AppColors.g, fontWeight: FontWeight.w600)),
                  ])),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          const GovFooter(),
        ]),
      )),
    );
  }
}
