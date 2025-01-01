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
  static const String auth = '/auth';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String leads = '/leads';
  static const String scan = '/scan';
  static const String inbox = '/inbox';
  static const String digitalProfile = '/digital-profile';
  static const String settings = '/settings';

  static Map<String, WidgetBuilder> routes = {
    auth: (context) => const AuthScreen(),
    forgotPassword: (context) => const ForgotPasswordScreen(),
    home: (context) => const HomeScreen(),
    leads: (context) => const LeadsScreen(),
    scan: (context) => const ScanScreen(),
    inbox: (context) => const InboxScreen(),
    digitalProfile: (context) => const DigitalProfileScreen(),
    settings: (context) => const SettingsScreen(),
  };
}