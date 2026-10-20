import 'package:flutter/material.dart';

import '../../../core/state/session_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import 'widgets/google_button.dart';
import 'widgets/password_field.dart';

/// The first screen every student meets. Sign-in is mandatory — the portal
/// (news, forum, marketplace, synced progress) only makes sense against an
/// account, so there is no "skip" route out of this screen.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

enum _Mode { signIn, signUp }

class _AuthScreenState extends State<AuthScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  _Mode _mode = _Mode.signIn;
  bool _submitting = false;
  String? _error;

  bool get _isSignIn => _mode == _Mode.signIn;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _switchMode(_Mode mode) {
    if (_mode == mode) return;
    setState(() {
      _mode = mode;
      _error = null;
    });
    _formKey.currentState?.reset();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      if (_isSignIn) {
        await sessionController.signInWithEmail(
          email: _email.text,
          password: _password.text,
        );
      } else {
        await sessionController.signUpWithEmail(
          fullName: _name.text,
          email: _email.text,
          password: _password.text,
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = SessionController.describeError(error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _google() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await sessionController.signInWithGoogle();
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = SessionController.describeError(error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _forgotPassword() async {
    if (_email.text.trim().isEmpty) {
      setState(() => _error = 'Enter your email address above first.');
      return;
    }
    try {
      await sessionController.sendPasswordReset(_email.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset link sent — check your inbox.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = SessionController.describeError(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const PrepLogo(size: 56),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    _isSignIn ? 'Welcome back' : 'Create your account',
                    style: text.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _isSignIn
                        ? 'Sign in to pick up exactly where you left off.'
                        : 'Past questions, news, scholarships and more — '
                            'all in one place.',
                    style: text.bodyMedium?.copyWith(
                      color: AppColours.textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppCard(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          _ModeToggle(mode: _mode, onChanged: _switchMode),
                          const SizedBox(height: AppSpacing.lg),
                          if (!_isSignIn) ...<Widget>[
                            Text('Full name', style: text.labelLarge),
                            const SizedBox(height: AppSpacing.sm),
                            TextFormField(
                              controller: _name,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                hintText: 'Your name',
                                prefixIcon: Icon(
                                  Icons.person_outline_rounded,
                                ),
                              ),
                              validator: (String? value) =>
                                  (value == null || value.trim().isEmpty)
                                      ? 'Please enter your name'
                                      : null,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                          ],
                          Text('Email address', style: text.labelLarge),
                          const SizedBox(height: AppSpacing.sm),
                          TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const <String>[
                              AutofillHints.email,
                            ],
                            decoration: const InputDecoration(
                              hintText: 'you@example.com',
                              prefixIcon: Icon(Icons.mail_outline_rounded),
                            ),
                            validator: (String? value) {
                              final String v = value?.trim() ?? '';
                              if (v.isEmpty) return 'Please enter your email';
                              if (!v.contains('@') || !v.contains('.')) {
                                return 'Enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text('Password', style: text.labelLarge),
                          const SizedBox(height: AppSpacing.sm),
                          PasswordField(
                            controller: _password,
                            hint: _isSignIn
                                ? 'Enter your password'
                                : 'At least 6 characters',
                            showStrength: !_isSignIn,
                            validator: (String? value) {
                              if (value == null || value.length < 6) {
                                return 'At least 6 characters';
                              }
                              return null;
                            },
                          ),
                          if (_isSignIn) ...<Widget>[
                            const SizedBox(height: AppSpacing.sm),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _submitting
                                    ? null
                                    : _forgotPassword,
                                child: const Text('Forgot password?'),
                              ),
                            ),
                          ],
                          if (_error != null) ...<Widget>[
                            const SizedBox(height: AppSpacing.sm),
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: const BoxDecoration(
                                color: AppColours.dangerSoft,
                                borderRadius: AppRadii.sm,
                              ),
                              child: Text(
                                _error!,
                                style: text.bodySmall?.copyWith(
                                  color: AppColours.danger,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.lg),
                          FilledButton(
                            onPressed: _submitting ? null : _submit,
                            child: _submitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Text(_isSignIn ? 'Sign in' : 'Create account'),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Row(
                            children: <Widget>[
                              const Expanded(child: Divider()),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                ),
                                child: Text(
                                  'or continue with',
                                  style: text.bodySmall,
                                ),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          GoogleButton(
                            label: 'Sign in with Google',
                            onPressed: _submitting ? null : _google,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    _isSignIn ? 'New to Eduvora Prep?' : 'Already have an account?',
                    style: text.bodyMedium,
                  ),
                  TextButton(
                    onPressed: _submitting
                        ? null
                        : () => _switchMode(
                              _isSignIn ? _Mode.signUp : _Mode.signIn,
                            ),
                    child: Text(
                      _isSignIn ? 'Create an account' : 'Sign in instead',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.mode, required this.onChanged});

  final _Mode mode;
  final ValueChanged<_Mode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColours.surfaceMuted,
        borderRadius: AppRadii.md,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _ToggleButton(
              label: 'Sign in',
              selected: mode == _Mode.signIn,
              onTap: () => onChanged(_Mode.signIn),
            ),
          ),
          Expanded(
            child: _ToggleButton(
              label: 'Create account',
              selected: mode == _Mode.signUp,
              onTap: () => onChanged(_Mode.signUp),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColours.surface : Colors.transparent,
      borderRadius: AppRadii.sm,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.sm,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: selected ? AppColours.primary : AppColours.textMuted,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ),
    );
  }
}
