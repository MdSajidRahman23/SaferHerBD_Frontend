import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/auth_service.dart';
import '../../utils/constants.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const String _doneKey = 'sh_onboarding_done';

  final PageController _controller = PageController();
  final AuthService _auth = AuthService();

  int _pageIndex = 0;

  static const List<_OnboardingItem> _pages = [
    _OnboardingItem(
      badge: 'Welcome',
      title: 'Welcome to SafeHer Bangladesh',
      subtitle:
          'Your personal safety companion for emergency help, safer routes, and digital support.',
      icon: Icons.shield_rounded,
      color: AppColors.green,
      points: [
        'Emergency safety support',
        'Safer travel guidance',
        'Community and legal help',
      ],
    ),
    _OnboardingItem(
      badge: 'SOS Alert',
      title: 'Emergency SOS Alert',
      subtitle:
          'Danger feel korle one-tap SOS diye trusted contacts and emergency support ke alert pathate parben.',
      icon: Icons.sos_rounded,
      color: AppColors.red,
      points: [
        'Quick SOS trigger',
        'Location sharing support',
        'Offline queue and retry system',
      ],
    ),
    _OnboardingItem(
      badge: 'Safe Route',
      title: 'Find Safer Routes',
      subtitle:
          'AI-based Safe Route Finder apnake lower-risk route choose korte help korbe.',
      icon: Icons.route_rounded,
      color: AppColors.green,
      points: [
        'Risk-based route suggestion',
        'Crime hotspot awareness',
        'Safer journey planning',
      ],
    ),
    _OnboardingItem(
      badge: 'AI Protection',
      title: 'AI Harassment Detection',
      subtitle:
          'Bangla online harassment, harmful message, and unsafe content detect korte AI support thakbe.',
      icon: Icons.psychology_alt_rounded,
      color: AppColors.purple,
      points: [
        'Bangla harassment detection',
        'Forum moderation support',
        'Safer digital space',
      ],
    ),
    _OnboardingItem(
      badge: 'Mitra',
      title: 'Mental Health & Chat Support',
      subtitle:
          'Stress, fear, anxiety, or unsafe situation e Mitra chatbot guidance and support dibe.',
      icon: Icons.spa_rounded,
      color: AppColors.blue,
      points: [
        '24/7 supportive chatbot',
        'Safety guidance',
        'Helpful crisis suggestions',
      ],
    ),
    _OnboardingItem(
      badge: 'Resources',
      title: 'Community, Legal Help & Safety Info',
      subtitle:
          'Women-only community, legal resources, emergency contacts, and safety dashboard ek jaygay paben.',
      icon: Icons.groups_rounded,
      color: AppColors.amber,
      points: [
        'Women-only community forum',
        'Bangladesh legal resources',
        'City-wise safety information',
      ],
    ),
  ];

  bool get _isLast => _pageIndex == _pages.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_doneKey, true);

    final loggedIn = await _auth.isLoggedIn();

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, loggedIn ? '/home' : '/login');
  }

  void _next() {
    if (_isLast) {
      _finish();
      return;
    }

    _controller.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = _pages[_pageIndex];

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(999),
                      border:
                          Border.all(color: item.color.withValues(alpha: 0.18)),
                    ),
                    child: Text(
                      item.badge,
                      style: GoogleFonts.inter(
                        color: item.color,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (!_isLast)
                    TextButton(
                      onPressed: _finish,
                      child: Text(
                        'Skip',
                        style: GoogleFonts.inter(
                          color: AppColors.ink2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _pageIndex = index),
                itemBuilder: (context, index) {
                  return _OnboardingPage(
                    item: _pages[index],
                    pageNumber: index + 1,
                    totalPages: _pages.length,
                  );
                },
              ),
            ),
            _BottomControls(
              pageIndex: _pageIndex,
              pageCount: _pages.length,
              isLast: _isLast,
              onNext: _next,
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final _OnboardingItem item;
  final int pageNumber;
  final int totalPages;

  const _OnboardingPage({
    required this.item,
    required this.pageNumber,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 10),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 28, 18, 26),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                colors: [
                  item.color.withValues(alpha: 0.94),
                  item.color.withValues(alpha: 0.72),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: item.color.withValues(alpha: 0.24),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Text(
                    '$pageNumber/$totalPages',
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: 118,
                  height: 118,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.14),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(item.icon, color: item.color, size: 58),
                ),
                const SizedBox(height: 26),
                Text(
                  item.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 26,
                    height: 1.16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  item.subtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.hindSiliguri(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 15,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Column(
            children: item.points
                .map(
                  (point) => _PointTile(
                    text: point,
                    color: item.color,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _PointTile extends StatelessWidget {
  final String text;
  final Color color;

  const _PointTile({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_rounded, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                color: AppColors.ink,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomControls extends StatelessWidget {
  final int pageIndex;
  final int pageCount;
  final bool isLast;
  final VoidCallback onNext;

  const _BottomControls({
    required this.pageIndex,
    required this.pageCount,
    required this.isLast,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
      decoration: const BoxDecoration(
        color: AppColors.bg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              pageCount,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: index == pageIndex ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: index == pageIndex ? AppColors.green : AppColors.line,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: isLast ? AppColors.red : AppColors.green,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isLast ? 'Get Started' : 'Next',
                    style: GoogleFonts.inter(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isLast
                        ? Icons.rocket_launch_rounded
                        : Icons.arrow_forward_rounded,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingItem {
  final String badge;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<String> points;

  const _OnboardingItem({
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.points,
  });
}
