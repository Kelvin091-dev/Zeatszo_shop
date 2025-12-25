import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'login_screen.dart';

/// Top-level gate that routes between login and the signed-in area.
///
/// Place this as the `home` (or in your router) so auth state drives navigation.
class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    required this.signedInBuilder,
    this.signedOutBuilder,
  });

  /// Builder for the UI shown when the user is signed in (e.g. dashboard).
  final WidgetBuilder signedInBuilder;

  /// Optional builder for a custom signed-out screen.
  ///
  /// If null, a default [LoginScreen] is shown.
  final WidgetBuilder? signedOutBuilder;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Still checking auth state; show a simple loading scaffold.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        // Signed out.
        if (user == null) {
          if (signedOutBuilder != null) {
            return signedOutBuilder!(context);
          }
          return const LoginScreen();
        }

        // Signed in.
        return signedInBuilder(context);
      },
    );
  }
}



