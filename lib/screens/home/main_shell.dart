import 'package:flutter/material.dart';

import '../chatbot/chatbot_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../community_safety/community_safety_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../admin/admin_management_screen.dart';
import '../forum/forum_screen.dart';
import '../legal/legal_screen.dart';
import '../profile/profile_screen.dart';
import '../route/route_screen.dart';
import '../settings/settings_screen.dart';
import '../safety_tools/safety_tools_screen.dart';
import '../emergency_tools/emergency_tools_screen.dart';
import '../learning_profile/learning_profile_screen.dart';

/// MainShell ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â host of the bottom-nav tabs after login.
///
/// The dashboard's onNav callback receives string keys:
///   'home' | 'route' | 'mitra' | 'community' | 'legal' |
///   'settings' | 'profile' | 'sos' | 'sos-history' | 'notifications'
///
/// Top-level routes (sos, sos-history, profile, notifications) are pushed
/// using Navigator.pushNamed; in-shell tabs swap the body via setState.
class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  String _route = 'home';

  void _onNav(String r) {
    // Routes that should push as full-screen pages
    const fullScreenRoutes = {'sos', 'sos-history', 'notifications'};
    if (fullScreenRoutes.contains(r)) {
      Navigator.pushNamed(context, '/$r');
      return;
    }

    setState(() => _route = r);
  }

  void _goHome() => setState(() => _route = 'home');

  @override
  Widget build(BuildContext context) {
    Widget body;

    switch (_route) {
      case 'route':
        body = RouteScreen(onNav: _onNav, onBack: _goHome);
        break;
      case 'mitra':
        body = ChatbotScreen(onNav: _onNav, onBack: _goHome);
        break;
      case 'communitySafety':
        body = CommunitySafetyScreen(onNav: _onNav, onBack: _goHome);
        break;
      case 'community':
        body = ForumScreen(onNav: _onNav, onBack: _goHome);
        break;
      case 'legal':
        body = LegalScreen(onNav: _onNav, onBack: _goHome);
        break;
      case 'admin-management':
        body = AdminManagementScreen(onNav: _onNav, onBack: _goHome);
        break;      case 'admin':
        body = AdminDashboardScreen(onNav: _onNav, onBack: _goHome);
        break;
      case 'safety-tools':
        body = SafetyToolsScreen(onNav: _onNav, onBack: _goHome);
        break;      case 'learning-profile':
        body = LearningProfileScreen(onNav: _onNav, onBack: _goHome);
        break;      case 'emergency-tools':
        body = EmergencyToolsScreen(onNav: _onNav, onBack: _goHome);
        break;      case 'settings':
        body = SettingsScreen(onNav: _onNav, onBack: _goHome);
        break;
      case 'profile':
        body = ProfileScreen(onBack: _goHome);
        break;
      default:
        body = DashboardScreen(onNav: _onNav);
    }

    return Scaffold(body: body);
  }
}