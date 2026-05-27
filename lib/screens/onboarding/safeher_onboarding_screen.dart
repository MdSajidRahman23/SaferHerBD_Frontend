import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/auth_service.dart';

class SafeHerOnboardingScreen extends StatefulWidget {
  const SafeHerOnboardingScreen({super.key});

  @override
  State<SafeHerOnboardingScreen> createState() =>
      _SafeHerOnboardingScreenState();
}

class _SafeHerOnboardingScreenState extends State<SafeHerOnboardingScreen> {
  static const String _seenKey = 'safeher_onboarding_seen';

  final PageController _pageController = PageController();
  final AuthService _auth = AuthService();

  int _index = 0;

  static const List<_SlideData> _slides = [
    _SlideData(
      badge: 'Bangladesh Safety',
      title: 'SafeHerBD',
      subtitle:
          'Emergency SOS, Mitra AI, safe routes, guardian tracking, evidence support, and women-only community safety in one app.',
      icon: Icons.health_and_safety_rounded,
      accent: Color(0xFF4961F2),
      points: [
        _PointData(Icons.warning_amber_rounded, 'One-tap SOS',
            'Queue-based emergency dispatch with trusted contacts.'),
        _PointData(Icons.route_rounded, 'Safer journey',
            'Risk-aware route, safe walk and guardian check-in.'),
        _PointData(Icons.folder_copy_rounded, 'Evidence ready',
            'Private evidence notes, case tracker and export support.'),
      ],
      chips: ['Mitra', 'Sister Circle', 'Guardian', 'Legal Aid'],
    ),
    _SlideData(
      badge: 'Emergency Help',
      title: 'One-Tap SOS Alert',
      subtitle:
          'In danger, press SOS to send emergency alert with your location and important details.',
      icon: Icons.sos_rounded,
      accent: Color(0xFFEF4444),
      points: [
        _PointData(Icons.touch_app_rounded, 'Fast trigger',
            'Send emergency alert quickly from the app.'),
        _PointData(Icons.location_on_rounded, 'Live location',
            'Share your current location with trusted contacts.'),
        _PointData(Icons.sync_rounded, 'Offline retry',
            'If network is poor, SOS can be queued and retried.'),
      ],
      chips: ['SOS', 'Location', 'Retry', 'Contacts'],
    ),
    _SlideData(
      badge: 'Safe Route',
      title: 'Choose Safer Routes',
      subtitle:
          'SafeHerBD helps you check risk-aware routes so you can travel with more confidence.',
      icon: Icons.route_rounded,
      accent: Color(0xFF10B981),
      points: [
        _PointData(Icons.map_rounded, 'Route guidance',
            'Find safer route options for your journey.'),
        _PointData(Icons.analytics_rounded, 'Risk score',
            'Crime and safety data can help detect risky areas.'),
        _PointData(Icons.shield_rounded, 'Guardian mode',
            'Keep trusted people aware during travel.'),
      ],
      chips: ['Route', 'Risk', 'Map', 'Guardian'],
    ),
    _SlideData(
      badge: 'Mitra AI',
      title: 'Mental Health & Chat Support',
      subtitle:
          'Talk with Mitra for safety guidance, emotional support, and helpful next steps during stressful situations.',
      icon: Icons.psychology_alt_rounded,
      accent: Color(0xFF8B5CF6),
      points: [
        _PointData(Icons.chat_bubble_rounded, 'AI companion',
            'Get supportive safety guidance anytime.'),
        _PointData(Icons.spa_rounded, 'Stress support',
            'Helpful responses for fear, stress, and anxiety.'),
        _PointData(Icons.local_phone_rounded, 'Crisis advice',
            'Emergency suggestions when quick action is needed.'),
      ],
      chips: ['Mitra', 'AI Chat', 'Support', 'Help'],
    ),
    _SlideData(
      badge: 'Digital Safety',
      title: 'AI Harassment Detection',
      subtitle:
          'SafeHerBD can support safer online spaces by detecting harmful or harassment-related content.',
      icon: Icons.security_rounded,
      accent: Color(0xFFF59E0B),
      points: [
        _PointData(Icons.language_rounded, 'Bangla support',
            'Designed for Bangla digital safety context.'),
        _PointData(Icons.report_rounded, 'Unsafe content',
            'Flag harmful messages and harassment patterns.'),
        _PointData(Icons.forum_rounded, 'Forum safety',
            'Helps keep community conversations safer.'),
      ],
      chips: ['AI', 'Bangla', 'Forum', 'Moderation'],
    ),
    _SlideData(
      badge: 'Community & Legal',
      title: 'Community, Legal Help & Safety Info',
      subtitle:
          'Access women-only community support, legal resources, emergency contacts, and safety information in one place.',
      icon: Icons.groups_rounded,
      accent: Color(0xFF2563EB),
      points: [
        _PointData(Icons.groups_2_rounded, 'Sister Circle',
            'A women-only community for safe support.'),
        _PointData(Icons.gavel_rounded, 'Legal Aid',
            'Find legal resources and important safety information.'),
        _PointData(Icons.dashboard_rounded, 'Safety dashboard',
            'View useful safety insights and resources.'),
      ],
      chips: ['Community', 'Legal Aid', 'Safety', 'Resources'],
    ),
  ];

  bool get _isLast => _index == _slides.length - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seenKey, true);

    final loggedIn = await _auth.isLoggedIn();

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, loggedIn ? '/home' : '/login');
  }

  void _next() {
    if (_isLast) {
      _finish();
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  void _createAccount() {
    Navigator.pushReplacementNamed(context, '/register');
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_index];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF101A33),
              Color(0xFF2E4EAA),
              Color(0xFF6538F6),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
                child: Row(
                  children: [
                    _Badge(label: slide.badge),
                    const Spacer(),
                    TextButton(
                      onPressed: _finish,
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (value) => setState(() => _index = value),
                  itemBuilder: (context, index) {
                    return _OnboardingSlide(slide: _slides[index]);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 4, 22, 20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _slides.length,
                        (dotIndex) => AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: dotIndex == _index ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: dotIndex == _index
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 26,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            _isLast
                                ? 'Ready to start SafeHerBD?'
                                : 'Explore SafeHerBD features',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF172033),
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isLast
                                ? 'Get started now and stay connected with safety support.'
                                : 'Tap Next to see how the app helps with safety, route, AI, legal aid, and community support.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF64708A),
                              fontSize: 13,
                              height: 1.35,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: _next,
                              icon: Icon(
                                _isLast
                                    ? Icons.login_rounded
                                    : Icons.arrow_forward_rounded,
                              ),
                              label: Text(_isLast ? 'Get Started' : 'Next'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: slide.accent,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                          if (_isLast) ...[
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              height: 44,
                              child: OutlinedButton.icon(
                                onPressed: _createAccount,
                                icon:
                                    const Icon(Icons.person_add_alt_1_rounded),
                                label: const Text('Create Account'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: slide.accent,
                                  side: BorderSide(color: slide.accent),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingSlide extends StatelessWidget {
  final _SlideData slide;

  const _OnboardingSlide({required this.slide});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 34),
      child: Column(
        children: [
          const SizedBox(height: 8),
          _HeroIcon(icon: slide.icon, accent: slide.accent),
          const SizedBox(height: 20),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              height: 1.05,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.2,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            slide.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 15,
              height: 1.45,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children:
                  slide.points.map((point) => _PointRow(point: point)).toList(),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: slide.chips.map((chip) => _Chip(label: chip)).toList(),
          ),
        ],
      ),
    );
  }
}

class _HeroIcon extends StatelessWidget {
  final IconData icon;
  final Color accent;

  const _HeroIcon({
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 178,
      height: 178,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 122,
          height: 122,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(34),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Icon(icon, color: accent, size: 62),
        ),
      ),
    );
  }
}

class _PointRow extends StatelessWidget {
  final _PointData point;

  const _PointRow({required this.point});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(point.icon, color: Colors.white, size: 23),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  point.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  point.description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.86),
                    fontSize: 12.5,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;

  const _Badge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on_rounded, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;

  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SlideData {
  final String badge;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final List<_PointData> points;
  final List<String> chips;

  const _SlideData({
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.points,
    required this.chips,
  });
}

class _PointData {
  final IconData icon;
  final String title;
  final String description;

  const _PointData(this.icon, this.title, this.description);
}
