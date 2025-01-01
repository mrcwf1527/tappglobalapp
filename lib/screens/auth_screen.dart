// lib/screens/auth_screen.dart
// ignore_for_file: use_build_context_synchronously, deprecated_member_use
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/auth_service.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  
  bool _isLoading = false;
  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/logo/logo_black.png',
                    width: 120,
                    height: 120,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _isLogin ? 'Welcome to TAPP!' : 'Create Account',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 24),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _emailController,
                          hintText: 'Email Address',
                          prefixIcon: const Icon(Icons.mail_outline),
                          keyboardType: TextInputType.emailAddress,
                          errorText: _emailError,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _passwordController,
                          hintText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          obscureText: _obscurePassword,
                          errorText: _passwordError,
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        if (!_isLogin) ...[
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _confirmPasswordController,
                            hintText: 'Confirm Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            obscureText: _obscureConfirmPassword,
                            errorText: _confirmPasswordError,
                            suffixIcon: IconButton(
                              icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (_isLogin)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.pushNamed(
                          context, 
                          '/forgot-password'
                        ),
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(color: Colors.black87),
                        ),
                      ),
                    ),
                  const SizedBox(height: 6),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            _isLogin ? 'Sign In' : 'Sign Up',
                            style: const TextStyle(color: Colors.white),
                          ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => setState(() => _isLogin = !_isLogin),
                    child: Text(
                      _isLogin
                          ? "Don't have an account? Sign Up"
                          : 'Already have an account? Sign In',
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('OR', style: TextStyle(color: Colors.grey)),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSocialButton(
                    onPressed: () => _authService.signInWithGoogle(),
                    icon: FontAwesomeIcons.google,
                    text: 'Continue with Google',
                  ),
                  if (Theme.of(context).platform == TargetPlatform.iOS) ...[
                    const SizedBox(height: 16),
                    _buildSocialButton(
                      onPressed: () => _authService.signInWithApple(),
                      icon: FontAwesomeIcons.apple,
                      text: 'Continue with Apple',
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required Widget prefixIcon,
    Widget? suffixIcon,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? errorText,
  }) {
    final isError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          onChanged: (value) {
            if (hintText == 'Password') {
              setState(() {
                _passwordError = _validatePassword(value);
                if (!_isLogin && _confirmPasswordController.text.isNotEmpty) {
                  _confirmPasswordError = _validateConfirmPassword(_confirmPasswordController.text);
                }
              });
            } else if (hintText == 'Confirm Password') {
              setState(() {
                _confirmPasswordError = _validateConfirmPassword(value);
              });
            } else if (hintText == 'Email Address') {
              setState(() {
                _emailError = _validateEmail(value);
              });
            }
          },
          style: TextStyle(color: isError ? Colors.red : Colors.black),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: isError ? Colors.red.withOpacity(0.5) : null),
            prefixIcon: IconTheme(
              data: IconThemeData(color: isError ? Colors.red : null),
              child: prefixIcon,
            ),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: isError ? Colors.red : Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: isError ? Colors.red : Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: isError ? Colors.red : Colors.black, width: 2),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 12),
            child: Text(
              errorText,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildSocialButton({
    required Future<UserCredential?> Function() onPressed,
    required IconData icon,
    required String text,
  }) {
    return OutlinedButton.icon(
      onPressed: () async {
        setState(() => _isLoading = true);
        try {
          final result = await onPressed();
          if (result != null && mounted) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(result.user!.uid)
                .update({
              'lastLogin': FieldValue.serverTimestamp(),
            });
            Navigator.pushReplacementNamed(context, '/home');
          }
        } on SignInWithAppleAuthorizationException {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Sign in cancelled by user',
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: Color.fromARGB(255, 117, 88, 86),
              ),
            );
          }
        } on FirebaseAuthException catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  e.message ?? 'Authentication failed',
                  style: const TextStyle(color: Colors.white), 
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Authentication failed',
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      },
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        side: const BorderSide(color: Colors.grey),
      ),
      icon: FaIcon(icon, size: 18),
      label: _isLoading ? 
        const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.black,
          ),
        ) : 
        Text(text),
    );
  }

  String? _validateEmail(String value) {
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (value.isEmpty) {
      return null;
    }
    if (!emailRegExp.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String value) {
    if (value.isEmpty) return null;
    if (value.length < 8 || value.length > 30) {
      return 'Password must be 8-30 characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Include at least one uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Include at least one lowercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Include at least one number';
    }
    if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'Include at least one special character';
    }
    return null;
  }

  String? _validateConfirmPassword(String value) {
    if (value.isEmpty) return null;
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> _handleSubmit() async {
    // Email validation
    final emailError = _validateEmail(_emailController.text);
    setState(() => _emailError = emailError);
    if (emailError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(emailError, style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Password validation
    final passwordError = _validatePassword(_passwordController.text);
    setState(() => _passwordError = passwordError);
    if (passwordError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(passwordError, style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Confirm password validation
    if (!_isLogin) {
      final confirmPasswordError = _validateConfirmPassword(_confirmPasswordController.text);
      setState(() => _confirmPasswordError = confirmPasswordError);
      if (confirmPasswordError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(confirmPasswordError, style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final result = _isLogin
          ? await _authService.loginWithEmail(
              _emailController.text,
              _passwordController.text,
            )
          : await _authService.signUpWithEmail(
              _emailController.text,
              _passwordController.text,
            );

      if (result != null) {
        if (!_isLogin) {
          await _authService.createUserDocument(result.user!);
        }
        await FirebaseFirestore.instance
            .collection('users')
            .doc(result.user!.uid)
            .update({
          'lastLogin': FieldValue.serverTimestamp(),
        });
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.message ?? 'Authentication failed',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Authentication failed',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}