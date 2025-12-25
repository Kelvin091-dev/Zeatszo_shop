import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'auth/login_screen.dart';
import 'navigation/onboarding_gate.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Firebase initialization failed - will show error in app
    debugPrint('❌ Firebase initialization failed: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shopkeeper Dashboard',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,

      home: FutureBuilder(
        future: _checkFirebaseInitialization(),
        builder: (context, snapshot) {
          // Still checking Firebase initialization
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Initializing...'),
                  ],
                ),
              ),
            );
          }

          // Firebase initialization failed
          if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Firebase Not Configured',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Error: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Please run: flutterfire configure',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          // Firebase initialized successfully - show auth flow
          return StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              // Still checking auth state
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              // Not logged in → Show Login screen
              if (!snapshot.hasData) {
                return const LoginScreen();
              }

              // Logged in → OnboardingGate handles routing
              // - If profile not completed → Profile tab
              // - If pricing not completed → Pricing tab
              // - If fully completed → Dashboard (Home tab)
              return const OnboardingGate();
            },
          );
        },
      ),
    );
  }

  Future<void> _checkFirebaseInitialization() async {
    // Check if Firebase was initialized
    try {
      // This will throw if Firebase is not initialized
      Firebase.app();
    } catch (e) {
      throw Exception('Firebase not initialized. Run: flutterfire configure');
    }
  }
}
