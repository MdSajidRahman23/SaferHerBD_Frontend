import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../widgets/design_widgets.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100))
      ..forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 1700));
    if (!mounted) return;
    final loggedIn = await AuthService().isLoggedIn();
    Navigator.pushReplacementNamed(context, loggedIn ? '/home' : '/login');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TopoBackground(
        child: Center(
          child: FadeTransition(
            opacity: _ctrl,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Logo mark — green shield with red dot
              SizedBox(
                width: 96,
                height: 96,
                child: Stack(clipBehavior: Clip.none, children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: AppColors.green,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.green.withOpacity(0.5),
                          blurRadius: 40,
                          offset: const Offset(0, 18),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.shield_outlined,
                        color: Colors.white, size: 44),
                  ),
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: AppColors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 26),
              const EnText('SafeHer',
                  size: 32, weight: FontWeight.w800, letterSpacing: -0.6),
              const SizedBox(height: 4),
              const BnText('সেফহার বাংলাদেশ',
                  size: 16, weight: FontWeight.w600, color: AppColors.green),
              const SizedBox(height: 30),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: AppColors.green),
              ),
              const SizedBox(height: 60),
              const BnText('স্মার্ট বাংলাদেশ',
                  size: 11, color: AppColors.ink3),
              const SizedBox(height: 2),
              const EnText('Smart Bangladesh Initiative',
                  size: 10, color: AppColors.ink3, letterSpacing: 0.4),
            ]),
          ),
        ),
      ),
    );
  }
}
