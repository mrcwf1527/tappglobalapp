// lib/config/routes.dart
import 'package:flutter/material.dart';
import '../screens/auth_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/home_screen.dart';

class AppRoutes {
  static const String auth = '/auth';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';

  static Map<String, WidgetBuilder> routes = {
    auth: (context) => const AuthScreen(),
    forgotPassword: (context) => const ForgotPasswordScreen(),
    home: (context) => const HomeScreen(),
  };
}