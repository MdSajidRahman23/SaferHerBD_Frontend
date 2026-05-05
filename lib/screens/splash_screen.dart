import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';
import '../services/auth_service.dart';
import '../widgets/gov_widgets.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1200))..forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    final loggedIn = await AuthService().isLoggedIn();
    Navigator.pushReplacementNamed(context, loggedIn ? '/home' : '/login');
  }

  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [AppColors.gdd, AppColors.gd, AppColors.g],
          ),
        ),
        child: Center(child: FadeTransition(
          opacity: _ctrl,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const SafeHerLogo(size: 70, light: true),
            const SizedBox(height: 30),
            Text('আপনার নিরাপত্তা, আমাদের অঙ্গীকার',
                style: GoogleFonts.hindSiliguri(
                    color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 6),
            const Text('Your Safety, Our Priority',
                style: TextStyle(color: Colors.white38, fontSize: 11)),
            const SizedBox(height: 40),
            const SizedBox(width: 28, height: 28,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
          ]),
        )),
      ),
    );
  }
}
