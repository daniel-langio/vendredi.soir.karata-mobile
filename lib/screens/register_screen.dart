import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';
import '../l10n/app_localizations.dart';
import '../theme/karata_colors.dart';
import '../theme/karata_text_styles.dart';
import '../widgets/common/inline_prompt.dart';
import '../widgets/common/karata_button.dart';
import '../widgets/common/karata_form_field.dart';
import '../widgets/common/karata_screen.dart';
import '../widgets/common/labeled_field.dart';
import '../widgets/common/password_reveal_button.dart';

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
  bool _revealPassword = false;

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
      final token = await client.register(
        username,
        password,
        promoCode: widget.promoCode,
      );

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
          arguments: {
            'serverUrl': widget.serverUrl,
            'token': token,
            'username': username,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).couldNotCreateAccount('$e'),
            ),
            backgroundColor: KarataColors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final promoCode = widget.promoCode;

    return Form(
      key: _formKey,
      child: KarataScreen(
        onBack: () => Navigator.of(context).pop(),
        backLabel: t.back,
        title: t.createAccount,
        subtitle: t.registerSubtitle,
        gap: 18,
        children: [
          if (promoCode != null && promoCode.isNotEmpty)
            Text(
              t.promoCodeWillApply(promoCode),
              style: karataText(
                size: 13,
                weight: 600,
                color: KarataColors.tealLight,
                height: 1.4,
              ),
            ),
          LabeledField(
            label: t.username,
            child: KarataFormField(
              controller: _usernameController,
              hintText: t.usernameHint,
              textInputAction: TextInputAction.next,
              validator: (v) => (v == null || v.trim().length < 3)
                  ? t.usernameTooShort
                  : null,
            ),
          ),
          LabeledField(
            label: t.password,
            child: KarataFormField(
              controller: _passwordController,
              hintText: t.passwordHint,
              obscureText: !_revealPassword,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _isLoading ? null : _submit(),
              trailing: PasswordRevealButton(
                revealed: _revealPassword,
                semanticLabel: t.showPassword,
                onPressed: () =>
                    setState(() => _revealPassword = !_revealPassword),
              ),
              validator: (v) =>
                  (v == null || v.length < 6) ? t.passwordTooShort : null,
            ),
          ),
          // The design puts a 4px breather between the last field and the action.
          const SizedBox(height: 4),
          KarataButton(
            label: t.createAccount,
            onPressed: _isLoading ? null : _submit,
          ),
          InlinePrompt(
            question: t.alreadyHaveAnAccount,
            linkLabel: t.logIn,
            onPressed: () => Navigator.of(context).pushReplacementNamed(
              '/login',
              arguments: {'serverUrl': widget.serverUrl},
            ),
          ),
        ],
      ),
    );
  }
}
