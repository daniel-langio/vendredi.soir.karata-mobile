import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';
import '../l10n/app_localizations.dart';
import '../theme.dart';

class RegisterScreen extends StatefulWidget {
  final String serverUrl;

  /// From /signup?promocode=... (or /register?promocode=...) - applied atomically with
  /// registration server-side, so an invalid code fails the whole submission (see _submit).
  final String? promoCode;

  /// Where to land after registration succeeds - carried through from a protected route the
  /// caller was redirected away from (see main.dart's _RequireSession). Defaults to '/menu'.
  final String? redirectTarget;

  const RegisterScreen({
    super.key,
    required this.serverUrl,
    this.promoCode,
    this.redirectTarget,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    setState(() => _isLoading = true);
    try {
      final client = ApiClient(baseUrl: widget.serverUrl);
      final token = await client.register(username, password, promoCode: widget.promoCode);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('server_url', widget.serverUrl);
      await prefs.setString('jwt_token', token);
      await prefs.setString('username', username);

      if (mounted) {
        // Clears the whole stack (not just this screen) - reached via WelcomeScreen's
        // RootScreen, which would otherwise linger below Menu and show as a stray back button.
        Navigator.of(context).pushNamedAndRemoveUntil(
          widget.redirectTarget ?? '/menu',
          (route) => false,
          arguments: {'serverUrl': widget.serverUrl, 'token': token, 'username': username},
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context).couldNotCreateAccount('$e')),
              backgroundColor: KarataColors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  t.createAccount,
                  style: const TextStyle(
                      fontSize: 34, fontWeight: FontWeight.w300, color: KarataColors.ink),
                ),
                const SizedBox(height: 8),
                Text(
                  t.registerSubtitle,
                  style: const TextStyle(fontSize: 13.5, color: KarataColors.dim, height: 1.45),
                ),
                if (widget.promoCode != null && widget.promoCode!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    t.promoCodeWillApply(widget.promoCode!),
                    style: const TextStyle(fontSize: 13, color: KarataColors.live, height: 1.4),
                  ),
                ],
                const SizedBox(height: 26),
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(labelText: t.username),
                  validator: (v) =>
                      (v == null || v.trim().length < 3) ? t.usernameTooShort : null,
                ),
                const SizedBox(height: 11),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(labelText: t.password),
                  validator: (v) => (v == null || v.length < 6) ? t.passwordTooShort : null,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: KarataColors.ink),
                        )
                      : Text(t.createAccount),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
