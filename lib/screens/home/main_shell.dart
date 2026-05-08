import 'package:flutter/material.dart';
import '../dashboard/dashboard_screen.dart';
import '../route/route_screen.dart';
import '../chatbot/chatbot_screen.dart';
import '../forum/forum_screen.dart';
import '../legal/legal_screen.dart';
import '../settings/settings_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  String _route = 'home';

  @override
  Widget build(BuildContext context) {
    Widget body;
    switch (_route) {
      case 'route':     body = RouteScreen(onNav: _onNav, onBack: _goHome); break;
      case 'mitra':     body = ChatbotScreen(onNav: _onNav, onBack: _goHome); break;
      case 'community': body = ForumScreen(onNav: _onNav, onBack: _goHome); break;
      case 'legal':     body = LegalScreen(onNav: _onNav, onBack: _goHome); break;
      case 'settings':  body = SettingsScreen(onNav: _onNav, onBack: _goHome); break;
      default:          body = DashboardScreen(onNav: _onNav);
    }
    return Scaffold(body: body);
  }

  void _onNav(String r) => setState(() => _route = r);
  void _goHome() => setState(() => _route = 'home');
}
