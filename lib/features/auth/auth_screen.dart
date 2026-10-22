import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_theme.dart';
import '../../state/app_state.dart';
import '../../state/core_providers.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/ui_helpers.dart';
import '../onboarding/wizard_screen.dart';
import 'preset_accounts.dart';

final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Log in or sign up with email and password. Accounts live on this device
/// (prototype). Tap the logo five times to reach the preset accounts.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _code = TextEditingController();
  bool _signup = false;
  bool _hide = true;
  String? _error;

  int _taps = 0;
  DateTime? _firstTap;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    _code.dispose();
    super.dispose();
  }

  /// Five quick taps on the logo open the preset accounts.
  void _logoTap() {
    final now = DateTime.now();
    if (_firstTap == null ||
        now.difference(_firstTap!) > const Duration(seconds: 3)) {
      _firstTap = now;
      _taps = 0;
    }
    _taps++;
    if (_taps >= 5) {
      _taps = 0;
      _firstTap = null;
      showPresetAccounts(context, ref);
    }
  }

  void _switchMode(bool signup) {
    setState(() {
      _signup = signup;
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    final auth = ref.read(authRepoProvider);
    final email = _email.text.trim();
    if (_signup) {
      if (auth.emailTaken(email)) {
        setState(
          () => _error =
              'An account with this email already exists. Try logging in.',
        );
        return;
      }
      final codes = ref
          .read(referenceProvider)
          .residentCodes
          .map((c) => c.toLowerCase())
          .toList();
      if (!codes.contains(_code.text.trim().toLowerCase())) {
        setState(() => _error = 'That resident code was not recognised.');
        return;
      }
      setState(() => _error = null);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => WizardScreen(
            credentials: SignupCredentials(
              email: email,
              password: _password.text,
            ),
          ),
        ),
      );
    } else {
      final id = auth.login(email, _password.text);
      final exists =
          id != null && ref.read(usersProvider).any((u) => u.id == id);
      if (!exists) {
        setState(() => _error = 'Wrong email or password.');
        return;
      }
      await ref.read(sessionProvider.notifier).signIn(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: _logoTap,
                        child: const AppLogo(size: 88),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'NeighbourFit',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: kPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Meet your neighbours, one workout at a time.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: kMuted, fontSize: 16),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      _signup ? 'Create your account' : 'Welcome back',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                      validator: (v) =>
                          (v == null || !_emailRe.hasMatch(v.trim()))
                          ? 'Enter a valid email address'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _password,
                      obscureText: _hide,
                      textInputAction: _signup
                          ? TextInputAction.next
                          : TextInputAction.done,
                      onFieldSubmitted: (_) => _signup ? null : _submit(),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: _hide ? 'Show password' : 'Hide password',
                          icon: Icon(
                            _hide
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(() => _hide = !_hide),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Enter your password';
                        }
                        if (_signup && v.length < 6) {
                          return 'Use at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    if (_signup) ...[
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _confirm,
                        obscureText: _hide,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Confirm password',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        validator: (v) => v != _password.text
                            ? 'Passwords do not match'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _code,
                        textCapitalization: TextCapitalization.characters,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'Resident code',
                          helperText:
                              'For residents only. Ask your township office.',
                          prefixIcon: Icon(Icons.verified_user_outlined),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Enter your resident code'
                            : null,
                      ),
                    ],
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: Color(0xFFB91C1C),
                            fontSize: 15,
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _submit,
                      child: Text(_signup ? 'Continue' : 'Log in'),
                    ),
                    if (!_signup)
                      TextButton(
                        onPressed: () => showSnack(
                          'Password reset is not available in this prototype.',
                        ),
                        child: const Text('Forgot password?'),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _signup
                              ? 'Already have an account?'
                              : 'New to NeighbourFit?',
                          style: const TextStyle(color: kMuted),
                        ),
                        TextButton(
                          onPressed: () => _switchMode(!_signup),
                          child: Text(_signup ? 'Log in' : 'Sign up'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Prototype: accounts are stored on this device only.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: kMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
