import 'package:flutter/material.dart';

import 'auth_service.dart';
import 'signup_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';

/// Basic email/password login screen for shopkeepers.
///
/// This is intentionally minimal; customize styling to match your dashboard.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      await AuthService.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      // On success, FirebaseAuth will emit a new auth state and AuthGate
      // will navigate to the signed-in area automatically.
    } on Exception catch (e) {
      setState(() {
        _errorText = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              child: Card(
                elevation: AppTheme.elevationMedium,
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingXl),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo/Icon
                        Container(
                          padding: const EdgeInsets.all(AppTheme.spacingM),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.store_rounded,
                            size: 64,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingL),
                        
                        // Title
                        Text(
                          'Welcome Back',
                          style: Theme.of(context).textTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppTheme.spacingS),
                        Text(
                          'Sign in to your shopkeeper account',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.secondaryText,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppTheme.spacingXl),

                        // Email Field
                        AppTextField(
                          controller: _emailController,
                          labelText: 'Email Address',
                          hintText: 'Enter your email',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Enter your email';
                            }
                            if (!value.contains('@')) {
                              return 'Enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppTheme.spacingM),

                        // Password Field
                        AppTextField(
                          controller: _passwordController,
                          labelText: 'Password',
                          hintText: 'Enter your password',
                          prefixIcon: Icons.lock_outline,
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter your password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppTheme.spacingL),

                        // Error Message
                        if (_errorText != null) ...[
                          Container(
                            padding: const EdgeInsets.all(AppTheme.spacingM),
                            decoration: BoxDecoration(
                              color: AppTheme.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(
                                AppTheme.borderRadiusSmall,
                              ),
                              border: Border.all(color: AppTheme.error),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: AppTheme.error,
                                  size: 20,
                                ),
                                const SizedBox(width: AppTheme.spacingS),
                                Expanded(
                                  child: Text(
                                    _errorText!,
                                    style: const TextStyle(
                                      color: AppTheme.error,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingM),
                        ],

                        // Login Button
                        AppButton(
                          text: 'Sign In',
                          onPressed: _signIn,
                          isLoading: _isLoading,
                          icon: Icons.login,
                        ),
                        const SizedBox(height: AppTheme.spacingL),

                        // Divider
                        const Row(
                          children: [
                            Expanded(child: Divider()),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppTheme.spacingM,
                              ),
                              child: Text(
                                'or',
                                style: TextStyle(color: AppTheme.secondaryText),
                              ),
                            ),
                            Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacingL),

                        // Sign Up Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SignupScreen(),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Sign Up',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}



