/// Authentication module root (Firebase auth, guards, etc.).
///
/// Usage example in `main.dart`:
///
/// ```dart
/// return MaterialApp(
///   home: AuthGate(
///     signedInBuilder: (context) => const DashboardHome(), // your dashboard root
///   ),
/// );
/// ```
library auth;

export 'auth_gate.dart';
export 'auth_service.dart';
export 'login_screen.dart';
export 'logout_button.dart';
