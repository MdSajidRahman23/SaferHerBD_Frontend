import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import '../../widgets/design_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _auth = AuthService();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();

  String _pin = '';
  int _step = 0;
  bool _showPwd = false;
  bool _loading = false;
  String? _error;

  Future<void> _next() async {
    setState(() => _error = null);
    if (_step == 0) {
      if (_nameCtrl.text.trim().isEmpty ||
          _phoneCtrl.text.trim().isEmpty ||
          _pwdCtrl.text.length < 6) {
        setState(() => _error = 'সব ঘর পূরণ করুন (password 6+ characters)');
        return;
      }
      setState(() => _step = 1);
      return;
    }
    if (_step == 1) {
      if (_pin.length != 6) {
        setState(() => _error = '৬ সংখ্যার PIN দিন');
        return;
      }
      // Submit
      setState(() => _loading = true);
      final res = await _auth.register(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        password: _pwdCtrl.text,
        emergencyPin: _pin,
      );
      if (!mounted) return;
      setState(() => _loading = false);
      if (res['token'] != null) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        String msg = res['message'] ?? 'রেজিস্ট্রেশন ব্যর্থ';
        if (res['errors'] != null) {
          final errors = res['errors'] as Map;
          msg = errors.values.first[0] ?? msg;
        }
        setState(() => _error = msg);
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _pwdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TopoBackground(
        child: SafeArea(
            child: _step == 0 ? _buildAccountForm() : _buildPinPane()),
      ),
    );
  }

  // ── Step 1: Account info ────────────────────────────────────────
  Widget _buildAccountForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          IconBtn(
              icon: Icons.chevron_left,
              size: 36,
              iconSize: 20,
              onTap: () => Navigator.pop(context)),
          const SizedBox(width: 10),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.green,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.shield_outlined,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 8),
          const EnText('SafeHer', size: 14, weight: FontWeight.w800),
        ]),
        const SizedBox(height: 24),

        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.greenSoft,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const EnText('STEP 1 OF 2 · ACCOUNT',
              size: 10,
              weight: FontWeight.w700,
              color: AppColors.green,
              letterSpacing: 0.4),
        ),
        const SizedBox(height: 14),

        const EnText('Create account',
            size: 24, weight: FontWeight.w800, letterSpacing: -0.4),
        const SizedBox(height: 4),
        const BnText('আপনার তথ্য দিন', size: 14, color: AppColors.ink2),
        const SizedBox(height: 20),

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
                  child: BnText(_error!, size: 12, color: AppColors.red)),
            ]),
          ),
          const SizedBox(height: 12),
        ],

        GovField(
            label: 'Full Name',
            icon: Icons.person_outline,
            controller: _nameCtrl),
        const SizedBox(height: 12),
        GovField(
            label: 'Phone Number',
            hint: '+880',
            icon: Icons.phone_outlined,
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone),
        const SizedBox(height: 12),
        GovField(
          label: 'Password',
          icon: Icons.lock_outline,
          controller: _pwdCtrl,
          obscure: !_showPwd,
          suffix: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(_showPwd ? Icons.visibility_off : Icons.visibility,
                size: 16, color: AppColors.ink3),
            onPressed: () => setState(() => _showPwd = !_showPwd),
          ),
        ),
        const SizedBox(height: 22),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _next,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  EnText('Next: Set Emergency PIN',
                      size: 15,
                      weight: FontWeight.w700,
                      color: Colors.white),
                  SizedBox(width: 6),
                  Icon(Icons.chevron_right, color: Colors.white, size: 18),
                ]),
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: RichText(
                text: const TextSpan(children: [
              TextSpan(
                  text: 'Already have an account? ',
                  style:
                      TextStyle(fontSize: 11, color: AppColors.ink3)),
              TextSpan(
                  text: 'Sign in',
                  style: TextStyle(
                      fontSize: 11,
                      color: AppColors.green,
                      fontWeight: FontWeight.w600)),
            ])),
          ),
        ),
      ]),
    );
  }

  // ── Step 2: PIN keypad ──────────────────────────────────────────
  Widget _buildPinPane() {
    final keys = [
      '1', '2', '3', //
      '4', '5', '6',
      '7', '8', '9',
      '', '0', 'del'
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          IconBtn(
              icon: Icons.chevron_left,
              size: 36,
              iconSize: 20,
              onTap: () => setState(() => _step = 0)),
          const SizedBox(width: 10),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.redSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.warning_amber_rounded,
                color: AppColors.red, size: 16),
          ),
          const SizedBox(width: 8),
          const EnText('STEP 2 OF 2 · EMERGENCY PIN',
              size: 11,
              weight: FontWeight.w700,
              color: AppColors.red,
              letterSpacing: 0.4),
        ]),
        const SizedBox(height: 14),

        const EnText('Set your 6-digit PIN',
            size: 24, weight: FontWeight.w800, letterSpacing: -0.4),
        const SizedBox(height: 4),
        const BnText(
            'বিপদের সময় এই গোপন PIN চাপলে SOS পাঠানো হবে — অ্যাপ না খুলেই।',
            size: 13.5,
            color: AppColors.ink2,
            height: 1.5),

        if (_error != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.redSoft,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.red.withOpacity(0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.error_outline,
                  size: 14, color: AppColors.red),
              const SizedBox(width: 6),
              Expanded(
                  child: BnText(_error!, size: 12, color: AppColors.red)),
            ]),
          ),
        ],

        // PIN dots
        const SizedBox(height: 28),
        Center(
          child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (i) {
                final filled = i < _pin.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 7),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled ? AppColors.red : Colors.transparent,
                    border: filled
                        ? null
                        : Border.all(color: AppColors.line, width: 2),
                  ),
                );
              })),
        ),

        const Spacer(),

        // Keypad
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 350 / (60 * 3),
          ),
          itemCount: 12,
          itemBuilder: (_, i) {
            final k = keys[i];
            if (k.isEmpty) return const SizedBox();
            return Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _press(k),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: k == 'del'
                      ? const Icon(Icons.backspace_outlined,
                          size: 20, color: AppColors.ink)
                      : EnText(k, size: 22, weight: FontWeight.w600),
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 14),
        Center(
            child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
              Icon(Icons.lock_outline, size: 11, color: AppColors.ink3),
              SizedBox(width: 4),
              EnText('Stored encrypted on this device only',
                  size: 11, color: AppColors.ink3),
            ])),
        const SizedBox(height: 14),

        if (_pin.length == 6)
          SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _next,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const EnText('Complete Registration',
                        size: 15,
                        weight: FontWeight.w700,
                        color: Colors.white),
              )),
      ]),
    );
  }

  void _press(String k) {
    if (k == 'del') {
      if (_pin.isNotEmpty) {
        setState(() => _pin = _pin.substring(0, _pin.length - 1));
      }
      return;
    }
    if (_pin.length < 6) {
      setState(() => _pin += k);
    }
  }
}
