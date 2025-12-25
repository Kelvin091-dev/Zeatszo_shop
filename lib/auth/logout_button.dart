import 'package:flutter/material.dart';

import 'auth_service.dart';

/// Simple logout button that signs the user out of FirebaseAuth.
///
/// Place this in your app bar or drawer in the signed-in area.
class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.logout),
      tooltip: 'Logout',
      onPressed: () async {
        await AuthService.instance.signOut();
        // After sign-out, AuthGate will show the login screen again.
      },
    );
  }
}



