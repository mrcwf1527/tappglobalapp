// lib/main.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'firebase_options.dart';
import 'screens/auth_screen.dart';
import 'providers/theme_provider.dart';
import 'providers/digital_profile_provider.dart';
import 'screens/home_screen.dart';
import 'screens/digital_profile/public_digital_profile_screen.dart';
import 'package:universal_html/html.dart' as html;


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  final prefs = await SharedPreferences.getInstance();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(prefs)),
        ChangeNotifierProvider(create: (_) => DigitalProfileProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  String? _initialRoute;
  bool _isInitialRouteChecked = false;

  @override
  void initState() {
    super.initState();
    _checkInitialRoute();
  }
  
  Future<void> _checkInitialRoute() async {
        final path = html.window.location.pathname;
        final uri = Uri.tryParse(path!);

      if (uri != null && uri.pathSegments.length == 1 &&
          !AppRoutes.isKnownRoute('/${uri.pathSegments[0]}')) {
          setState(() {
              _initialRoute = path;
          });
      }
       setState(() {
          _isInitialRouteChecked = true;
      });
  }

  @override
  Widget build(BuildContext context) {
       if (!_isInitialRouteChecked) {
            return _buildLoadingScreen();
        }

      return Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => MaterialApp(
          title: 'TAPP',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          navigatorKey: AppRoutes.navigatorKey,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: _getHomeWidget(),
            debugShowCheckedModeBanner: false,
        ),
      );
  }
  
   Widget _getHomeWidget() {
        if (_initialRoute != null) {
            final uri = Uri.parse(_initialRoute!);
          return PublicProfileScreen(username: uri.pathSegments[0]);
        }
        
        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingScreen(); //Change to the loading screen
            }
            return snapshot.data == null ? const AuthScreen() : const HomeScreen();
          },
        );
    }
    
    Widget _buildLoadingScreen() {
      return Container(
        color: Colors.white,
        child: const Center(
          child: SizedBox(
            width: 120,
            height: 120,
            child:  Image(image: AssetImage('assets/tapp_logo.png')),
          ),
        ),
      );
    }
}
// TODO: Implement theme toggle in settings_screen.dart
// - Add radio buttons for system/light/dark theme selection
// - Use ThemeProvider to update theme preference
// - Persist selection using SharedPreferences