// lib/widgets/scanning_loading_screen.dart
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class ScanningLoadingScreen extends StatelessWidget {
  const ScanningLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              isDarkMode ? 'assets/lottie/scanning_dark.json' : 'assets/lottie/scanning_light.json',
              width: 200,
              height: 200,
              fit: BoxFit.fill,
            ),
            const SizedBox(height: 20),
            Text(
              'Processing image...',
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}