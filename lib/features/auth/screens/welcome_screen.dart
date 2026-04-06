import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../../core/auth/providers/auth_provider.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLogin = true;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isLogin) {
      await ref.read(authProvider.notifier).login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    } else {
      await ref.read(authProvider.notifier).register(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            name: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              // App Logo/Title
              const Icon(
                Icons.restaurant_menu,
                size: 80,
                color: Color(0xFF2E7D32),
              ),
              const SizedBox(height: 24),

              Text(
                'SmartMeal',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2E7D32),
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              Text(
                'Deine smarte Rezept-App mit Kühlschrank-Scanner und Deal-Finder',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              // Email/Password Form
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Name Field (only for registration)
                    if (!_isLogin) ...[
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Name (optional)',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        textInputAction: TextInputAction.next,
                        enabled: !authState.isLoading,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'E-Mail',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      enabled: !authState.isLoading,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Bitte E-Mail eingeben';
                        }
                        if (!value.contains('@')) {
                          return 'Bitte gültige E-Mail eingeben';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Passwort',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      enabled: !authState.isLoading,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Bitte Passwort eingeben';
                        }
                        if (!_isLogin && value.length < 6) {
                          return 'Passwort muss mindestens 6 Zeichen lang sein';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _handleSubmit(),
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    ElevatedButton(
                      onPressed: authState.isLoading ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: authState.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              _isLogin ? 'Anmelden' : 'Registrieren',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),

                    // Toggle Login/Register
                    TextButton(
                      onPressed: authState.isLoading
                          ? null
                          : () {
                              setState(() {
                                _isLogin = !_isLogin;
                              });
                            },
                      child: Text(
                        _isLogin
                            ? 'Noch kein Konto? Registrieren'
                            : 'Schon ein Konto? Anmelden',
                        style: const TextStyle(
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Divider
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey[300])),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'oder',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey[300])),
                ],
              ),

              const SizedBox(height: 24),

              // Sign in with Apple Button
              SignInWithAppleButton(
                onPressed: authState.isLoading
                    ? () {}
                    : () async {
                        await ref.read(authProvider.notifier).signInWithApple();
                      },
                text: 'Mit Apple anmelden',
                height: 50,
                borderRadius: const BorderRadius.all(Radius.circular(12)),
              ),

              const SizedBox(height: 16),

              // Error Message
              if (authState.error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          authState.error!,
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 14,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () {
                          ref.read(authProvider.notifier).clearError();
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 32),

              // Privacy Info
              Text(
                'Mit der Anmeldung stimmst du unseren Nutzungsbedingungen und Datenschutzrichtlinien zu.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
