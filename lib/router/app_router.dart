import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';

class AppRouter {
  static const login = '/login';
  static const dashboard = '/dashboard';
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      default:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
    }
  }
  static void goToLogin(BuildContext context) => Navigator.of(context).pushNamedAndRemoveUntil(login, (r) => false);
  static void goToDashboard(BuildContext context) => Navigator.of(context).pushNamedAndRemoveUntil(dashboard, (r) => false);
}
