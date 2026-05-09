import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'services/notification_service.dart';
import 'utils/app_theme.dart';

import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/main_shell.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/sos/sos_screen.dart';
import 'screens/sos_history/sos_history_screen.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  // Initialize FCM in the background — never block app launch on this
  // (it gracefully no-ops if Firebase isn't configured)
  unawaited(NotificationService().initialize());

  runApp(const SafeHerApp());
}

class SafeHerApp extends StatelessWidget {
  const SafeHerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeHer Bangladesh',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: '/',
      routes: {
        '/':              (_) => const SplashScreen(),
        '/login':         (_) => const LoginScreen(),
        '/register':      (_) => const RegisterScreen(),
        '/home':          (_) => const MainShell(),
        '/sos':           (_) => const SosScreen(),
        '/sos-history':   (_) => const SosHistoryScreen(),
        '/profile':       (_) => const ProfileScreen(),
        '/notifications': (_) => const NotificationsScreen(),
      },
    );
  }
}

void unawaited(Future<void> future) {
  // Intentional fire-and-forget for non-critical async ops
  future.ignore();
}
