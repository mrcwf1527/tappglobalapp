// lib/screens/digital_profile_screen.dart
import 'package:flutter/material.dart';
import '../../widgets/responsive_layout.dart';
import 'edit_digital_profile_screen.dart';

class DigitalProfileScreen extends StatelessWidget {
  const DigitalProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobileLayout: _DigitalProfileMobileLayout(),
      desktopLayout: _DigitalProfileDesktopLayout(),
    );
  }
}

class _DigitalProfileMobileLayout extends StatelessWidget {
 const _DigitalProfileMobileLayout();

 @override
 Widget build(BuildContext context) {
   final isDarkMode = Theme.of(context).brightness == Brightness.dark;
   
   return Scaffold(
     body: Center(
       child: Column(
         mainAxisAlignment: MainAxisAlignment.center,
         children: [
           Image.asset(
             'assets/images/digital_profile_illustration.png',
             width: 200,
             height: 200,
           ),
           const SizedBox(height: 16),
           Text(
             'Create your first digital profile',
             style: Theme.of(context).textTheme.titleMedium?.copyWith(
               color: isDarkMode ? const Color(0xFFD9D9D9) : Colors.black,
             ),
           ),
         ],
       ),
     ),
     floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const EditDigitalProfileScreen(),
          ),
        ),
        backgroundColor: isDarkMode ? const Color(0xFFD9D9D9) : Colors.black,
        child: Icon(
          Icons.add,
          color: isDarkMode ? Colors.black : Colors.white,
        ),
      ),
   );
 }
}

class _DigitalProfileDesktopLayout extends StatelessWidget {
  const _DigitalProfileDesktopLayout();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Image.asset(
                'assets/images/digital_profile_illustration.png',
                width: 300,
                height: 300,
              ),
              const SizedBox(height: 24),
              Text(
                'Create your first digital profile',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: const Color(0xFFD9D9D9),
                    ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.5,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Navigate to create new profile screen
                  },
                  icon: const Icon(Icons.add, color: Colors.black, size: 24),
                  label: const Text('Create New Profile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD9D9D9),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}