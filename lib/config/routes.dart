// lib/config/routes.dart
import 'package:flutter/material.dart';
import '../screens/auth_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/home_screen.dart';
import '../screens/leads_screen.dart';
import '../screens/scan_screen.dart';
import '../screens/inbox_screen.dart';
import '../screens/digital_profile_screen.dart';
import '../screens/settings_screen.dart';

class AppRoutes {
  static final navigatorKey = GlobalKey<NavigatorState>();

  static const String auth = '/auth';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String leads = '/leads';
  static const String scan = '/scan';
  static const String inbox = '/inbox';
  static const String digitalProfile = '/digital-profile';
  static const String settings = '/settings';

  static PageRoute _buildRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);
        return SlideTransition(position: offsetAnimation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  static final Map<String, Widget Function(BuildContext)> _routes = {
    auth: (context) => const AuthScreen(),
    forgotPassword: (context) => const ForgotPasswordScreen(),
    home: (context) => const HomeScreen(),
    leads: (context) => const LeadsScreen(),
    scan: (context) => const ScanScreen(),
    inbox: (context) => const InboxScreen(),
    digitalProfile: (context) => const DigitalProfileScreen(),
    settings: (context) => const SettingsScreen(),
  };

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final builder = _routes[settings.name];
    if (builder != null) {
      return _buildRoute(builder(navigatorKey.currentContext!));
    }
    return MaterialPageRoute(
      builder: (_) => const Scaffold(
        body: Center(child: Text('Route not found')),
      ),
    );
  }
}