// lib/config/routes.dart
// Manages application routing and navigation, Handles custom URL paths for public profiles, Implements route transitions and error handling, Supports web-specific routing logic
import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;
import '../screens/auth_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/home_screen.dart';
import '../screens/leads_screen.dart';
import '../screens/inbox_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/digital_profile/digital_profile_screen.dart';
import '../screens/digital_profile/edit_digital_profile_screen.dart';
import '../screens/digital_profile/tabs/blocks/edit_block_screen.dart';
import '../screens/digital_profile/public_digital_profile_screen.dart';
import '../models/block.dart';

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
  static const String editBlock = '/edit-block';

  static final List<String> profileDomains = [
    'tappglobal-app-profile.web.app',
    'tappglobal-app-profile.firebaseapp.com',
    'page.tappglobal.app'
  ];

  static bool isProfileDomain(String host) {
    return profileDomains.any((domain) => host.contains(domain));
  }

  static bool isKnownRoute(String path) {
    if (path.isEmpty) return false;
    return _routes.containsKey(path) || path == editBlock;
  }

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

  static PageRoute _buildNoAnimationRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
      transitionDuration: Duration.zero,
    );
  }

  static final Map<String, Widget Function(BuildContext)> _routes = {
    auth: (context) => const AuthScreen(),
    forgotPassword: (context) => const ForgotPasswordScreen(),
    home: (context) => const HomeScreen(),
    leads: (context) => const LeadsScreen(),
    inbox: (context) => const InboxScreen(),
    digitalProfile: (context) => const DigitalProfileScreen(),
    settings: (context) => const SettingsScreen(),
  };

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final host = html.window.location.host;
    final path = settings.name ?? '';

    if (isProfileDomain(host)) {
      final uri = Uri.parse(path);
      if (uri.pathSegments.isNotEmpty) {
        return _buildRoute(PublicProfileScreen(username: uri.pathSegments[0]));
      }
      return _buildRoute(const Scaffold(
        body: Center(child: Text('Profile not found')),
      ));
    }

    if (settings.name == editBlock) {
      final block = settings.arguments as Block;
      return _buildNoAnimationRoute(EditBlockScreen(block: block));
    }

    final builder = _routes[settings.name];
    if (builder != null) {
      return _buildRoute(builder(navigatorKey.currentContext!));
    }

    if (settings.name == editDigitalProfile) {
      return _buildNoAnimationRoute(EditDigitalProfileScreen(
        profileId: settings.arguments as String,
      ));
    }

    final uri = Uri.tryParse(settings.name ?? '');
    if (uri != null && uri.pathSegments.isNotEmpty) {
      if (uri.pathSegments.length == 1) {
        return _buildRoute(PublicProfileScreen(username: uri.pathSegments[0]));
      }
    }

    return MaterialPageRoute(
      builder: (_) => const Scaffold(
        body: Center(child: Text('Route not found')),
      ),
    );
  }
}