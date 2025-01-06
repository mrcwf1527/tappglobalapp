// lib/config/routes.dart
// Under TAPP! Global Flutter Project
import 'package:flutter/material.dart';
import '../screens/auth_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/home_screen.dart';
import '../screens/leads_screen.dart';
import '../screens/scan_screen.dart';
import '../screens/inbox_screen.dart';
import '../screens/digital_profile/digital_profile_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/digital_profile/edit_digital_profile_screen.dart';
import '../screens/digital_profile/public_digital_profile_screen.dart';

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
  static const String editDigitalProfile = '/edit-digital-profile';

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

  static bool isKnownRoute(String path) {
    if (path.isEmpty) return false;
    return _routes.containsKey(path);
  }

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    // Handle existing routes first
    final builder = _routes[settings.name];
    if (builder != null) {
      return _buildRoute(builder(navigatorKey.currentContext!));
    }

    if (settings.name == editDigitalProfile) {
      return _buildRoute(EditDigitalProfileScreen(
        profileId: settings.arguments as String,
      ));
    }

    // Then handle username paths
    final uri = Uri.tryParse(settings.name ?? '');

    if (uri != null && uri.pathSegments.isNotEmpty) {
      if (uri.pathSegments.length == 1) {
        final username = uri.pathSegments[0];
        return _buildRoute(PublicProfileScreen(username: username));
      }
    }
    // Fallback route
    return MaterialPageRoute(
      builder: (_) => const Scaffold(
        body: Center(child: Text('Route not found')),
      ),
    );
  }
}