
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'reset_password_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLogin = true;
  bool isLoading = false;
  bool hidePassword = true;
  String? errorMessage;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (isLoading || !formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final auth = FirebaseAuth.instance;
      final email = emailController.text.trim();
      final password = passwordController.text;

      if (isLogin) {
        await auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        await auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = switch (error.code) {
          'invalid-email' => 'Enter a valid email address.',
          'weak-password' => 'Choose a stronger password.',
          'email-already-in-use' =>
            'An account already uses this email. Try logging in.',
          'invalid-credential' ||
          'user-not-found' ||
          'wrong-password' =>
            'Unable to log in. Check your email and password.',
          'network-request-failed' =>
            'Check your internet connection and try again.',
          'too-many-requests' =>
            'Too many attempts. Please wait and try again.',
          'operation-not-allowed' =>
            'Email/password login needs to be enabled in Firebase.',
          _ => 'Unable to continue. Please try again.',
        };
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Something went wrong. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void switchMode() {
    if (isLoading) return;

    FocusScope.of(context).unfocus();

    setState(() {
      isLogin = !isLogin;
      errorMessage = null;
      hidePassword = true;
      passwordController.clear();
      formKey.currentState?.reset();
    });
  }

  Widget welcomePanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF123C25),
            Color(0xFF227447),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE5F6BD),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.kitchen_outlined,
              size: 34,
              color: Color(0xFF123C25),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Good food.\nLess waste.',
            style: TextStyle(
              fontSize: 32,
              height: 1.15,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'A little help keeping your pantry organised '
            'and your spending in view.',
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Color(0xFFE3F1E6),
            ),
          ),
        ],
      ),
    );
  }

  Widget accountForm() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isLogin ? 'Welcome back' : 'Make yourself at home',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isLogin
                    ? 'Log in to your Faithful Pantry account.'
                    : 'Create your Faithful Pantry account.',
                style: textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: emailController,
                enabled: !isLoading,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                textCapitalization: TextCapitalization.none,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (value) {
                  final email = value?.trim() ?? '';

                  if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                      .hasMatch(email)) {
                    return 'Enter a valid email address.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                enabled: !isLoading,
                obscureText: hidePassword,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => submit(),
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  helperText: isLogin ? null : 'Use at least 6 characters.',
                  suffixIcon: IconButton(
                    tooltip: hidePassword
                        ? 'Show password'
                        : 'Hide password',
                    onPressed: isLoading
                        ? null
                        : () {
                            setState(() {
                              hidePassword = !hidePassword;
                            });
                          },
                    icon: Icon(
                      hidePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter your password.';
                  }

                  if (!isLogin && value.length < 6) {
                    return 'Use at least 6 characters.';
                  }

                  return null;
                },
              ),
              if (isLogin)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            FocusScope.of(context).unfocus();

                            Navigator.of(context).push<void>(
                              MaterialPageRoute(
                                builder: (_) => ResetPasswordScreen(
                                  initialEmail:
                                      emailController.text.trim(),
                                ),
                              ),
                            );
                          },
                    child: const Text('Forgot password?'),
                  ),
                ),
              if (errorMessage != null) ...[
                const SizedBox(height: 16),
                Semantics(
                  liveRegion: true,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      errorMessage!,
                      style: textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                        color: colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: isLoading ? null : submit,
                child: isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.onPrimary,
                        ),
                      )
                    : Text(isLogin ? 'Login' : 'Create account'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: isLoading ? null : switchMode,
                child: Text(
                  isLogin
                      ? 'New here? Create an account'
                      : 'Already registered? Login',
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Faithful Pantry'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                welcomePanel(),
                const SizedBox(height: 20),
                accountForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
