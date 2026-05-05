import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/constants.dart';
import '../dashboard/dashboard_screen.dart';
import '../sos/sos_screen.dart';
import '../route/route_screen.dart';
import '../forum/forum_screen.dart';
import '../chatbot/chatbot_screen.dart';
import '../profile/profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _idx = 0;

  final _screens = const [
    DashboardScreen(),
    SosScreen(),
    RouteScreen(),
    ForumScreen(),
    ChatbotScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _idx, children: _screens),
      bottomNavigationBar: _buildNav(),
    );
  }

  Widget _buildNav() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [BoxShadow(
          color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, -2)
        )],
      ),
      child: SafeArea(top: false, child: SizedBox(
        height: 62,
        child: Row(children: [
          _navItem(0, Icons.home_outlined,      Icons.home_rounded,           'হোম'),
          _sosButton(),
          _navItem(2, Icons.alt_route_outlined, Icons.alt_route_rounded,      'পথ'),
          _navItem(3, Icons.people_outline,     Icons.people_rounded,         'সম্প্রদায়'),
          _navItem(4, Icons.chat_bubble_outline,Icons.chat_bubble_rounded,    'সাহায্য'),
          _navItem(5, Icons.person_outline,     Icons.person_rounded,         'প্রোফাইল'),
        ]),
      )),
    );
  }

  Widget _navItem(int idx, IconData icon, IconData activeIcon, String label) {
    final isActive = _idx == idx;
    return Expanded(child: GestureDetector(
      onTap: () => setState(() => _idx = idx),
      behavior: HitTestBehavior.opaque,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(height: 3, width: isActive ? 20 : 0,
          decoration: BoxDecoration(
            color: AppColors.g,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 4),
        Icon(isActive ? activeIcon : icon,
            color: isActive ? AppColors.g : AppColors.t3, size: 21),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.hindSiliguri(
          fontSize: 9, fontWeight: FontWeight.w600,
          color: isActive ? AppColors.g : AppColors.t3,
        )),
      ]),
    ));
  }

  Widget _sosButton() {
    final isActive = _idx == 1;
    return Expanded(child: GestureDetector(
      onTap: () => setState(() => _idx = 1),
      child: Center(child: Container(
        width: 50, height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive ? AppColors.r : Colors.white,
          border: Border.all(color: AppColors.r, width: 2.5),
          boxShadow: [BoxShadow(
            color: AppColors.r.withOpacity(isActive ? 0.35 : 0.2),
            blurRadius: 10, spreadRadius: 1,
          )],
        ),
        child: Icon(Icons.warning_amber_rounded,
          color: isActive ? Colors.white : AppColors.r, size: 26),
      )),
    ));
  }
}
