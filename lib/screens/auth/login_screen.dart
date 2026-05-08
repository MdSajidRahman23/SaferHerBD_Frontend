import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import '../../widgets/design_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = AuthService();
  final _phoneCtrl = TextEditingController(text: '');
  final _pwdCtrl = TextEditingController(text: '');
  bool _show = false;
  bool _loading = false;
  bool _remember = true;
  String? _error;

  Future<void> _login() async {
    if (_phoneCtrl.text.trim().isEmpty || _pwdCtrl.text.isEmpty) {
      setState(() => _error = 'সব ঘর পূরণ করুন');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await _auth.login(_phoneCtrl.text.trim(), _pwdCtrl.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (res['token'] != null) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      setState(() => _error = res['message'] ?? 'লগইন ব্যর্থ');
    }
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _pwdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TopoBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Logo row
              Row(children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.green,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.shield_outlined,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      EnText('SafeHer', size: 14, weight: FontWeight.w800),
                      BnText('নিরাপত্তা · বিশ্বাস · সম্মান',
                          size: 10.5, color: AppColors.ink3),
                    ]),
              ]),
              const SizedBox(height: 28),

              // Headings
              const EnText('Welcome back',
                  size: 24, weight: FontWeight.w800, letterSpacing: -0.4),
              const SizedBox(height: 4),
              const BnText('আপনার অ্যাকাউন্টে সাইন ইন করুন',
                  size: 14, color: AppColors.ink2),
              const SizedBox(height: 24),

              // Error
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.redSoft,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.red.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline,
                        size: 16, color: AppColors.red),
                    const SizedBox(width: 6),
                    Expanded(
                        child: BnText(_error!,
                            size: 12, color: AppColors.red)),
                  ]),
                ),
                const SizedBox(height: 12),
              ],

              GovField(
                label: 'Phone Number',
                hint: '+880',
                icon: Icons.phone_outlined,
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              GovField(
                label: 'Password',
                icon: Icons.lock_outline,
                controller: _pwdCtrl,
                obscure: !_show,
                suffix: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(_show ? Icons.visibility_off : Icons.visibility,
                      size: 16, color: AppColors.ink3),
                  onPressed: () => setState(() => _show = !_show),
                ),
                onSubmitted: (_) => _login(),
              ),
              const SizedBox(height: 12),

              // Remember + Forgot
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: Checkbox(
                          value: _remember,
                          onChanged: (v) => setState(() => _remember = v!),
                          activeColor: AppColors.green,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const EnText('Remember device',
                          size: 12, color: AppColors.ink2),
                    ]),
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 0)),
                      child: const EnText('Forgot?',
                          size: 12,
                          weight: FontWeight.w600,
                          color: AppColors.green),
                    ),
                  ]),
              const SizedBox(height: 18),

              // Sign in button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                    shadowColor: AppColors.green.withOpacity(0.6),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const EnText('Sign In Securely',
                          size: 15,
                          weight: FontWeight.w700,
                          color: Colors.white),
                ),
              ),
              const SizedBox(height: 18),

              // Emergency hint
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.redSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFBC8CE)),
                ),
                child: Row(children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.warning_amber_rounded,
                        color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        EnText('In immediate danger?',
                            size: 12,
                            weight: FontWeight.w700,
                            color: AppColors.red),
                        SizedBox(height: 1),
                        BnText('সরাসরি কল করুন ৯৯৯ — no login needed',
                            size: 11.5, color: AppColors.ink2),
                      ])),
                ]),
              ),
              const SizedBox(height: 28),

              // Create account link
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/register'),
                  child: RichText(
                      text: const TextSpan(children: [
                    TextSpan(
                        text: 'New here? ',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.ink3)),
                    TextSpan(
                        text: 'Create account',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.green,
                            fontWeight: FontWeight.w600)),
                  ])),
                ),
              ),
              const SizedBox(height: 18),
              const Center(
                  child: BnText('স্মার্ট বাংলাদেশ · v1.0.0',
                      size: 10, color: AppColors.ink3)),
            ]),
          ),
        ),
      ),
    );
  }
}
