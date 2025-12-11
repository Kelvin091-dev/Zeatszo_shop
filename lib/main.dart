import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.initialize();
  runApp(const ShopkeeperApp());
}

class ShopkeeperApp extends StatefulWidget {
  const ShopkeeperApp({super.key});
  static final navigatorKey = GlobalKey<NavigatorState>();
  @override
  State<ShopkeeperApp> createState() => _ShopkeeperAppState();
}

class _ShopkeeperAppState extends State<ShopkeeperApp> {
  final ThemeMode _themeMode = ThemeMode.system;
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [Provider<AuthService>(create: (_) => AuthService())],
      child: MaterialApp(
        title: 'Zeatszo Shopkeeper Dashboard',
        debugShowCheckedModeBanner: false,
        themeMode: _themeMode,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        navigatorKey: ShopkeeperApp.navigatorKey,
        onGenerateRoute: AppRouter.onGenerateRoute,
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  StreamSubscription? _sub;
  @override
  void initState() {
    super.initState();
    _sub = FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user == null) {
        AppRouter.goToLogin(context);
      } else {
        await NotificationService.registerShopDeviceToken(user.uid);
        AppRouter.goToDashboard(context);
      }
    });
  }
  @override
  void dispose() { _sub?.cancel(); super.dispose(); }
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: CircularProgressIndicator()));
}
