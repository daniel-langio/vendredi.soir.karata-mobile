import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';
import 'auth_redirect.dart';
import '../l10n/app_localizations.dart';
import '../theme/karata_colors.dart';
import '../widgets/common/breakpoints.dart';
import '../widgets/common/inline_prompt.dart';
import '../widgets/common/karata_button.dart';
import '../widgets/common/karata_form_field.dart';
import '../widgets/common/karata_screen.dart';
import '../widgets/common/labeled_field.dart';
import '../widgets/common/password_reveal_button.dart';
import '../widgets/desktop/auth_split.dart';

class LoginScreen extends StatefulWidget {
  final String serverUrl;

  /// Where to land after login succeeds - carried through from a protected route the caller was
  /// redirected away from (see main.dart's _RequireSession). Defaults to '/menu'.
  final String? redirectTarget;

  const LoginScreen({super.key, required this.serverUrl, this.redirectTarget});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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
      final token = await client.login(username, password);

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
            content: Text(AppLocalizations.of(context).couldNotLogIn('$e')),
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

    // The wide drawing of this screen is the same form in the same order, on the same 18px
    // rhythm - only the frame around it changes, from a back button and a 32px heading to the
    // felt panel and a 38px one.
    final fields = <Widget>[
      LabeledField(
        label: t.username,
        child: KarataFormField(
          controller: _usernameController,
          hintText: t.usernameHint,
          textInputAction: TextInputAction.next,
          validator: (v) => (v == null || v.trim().isEmpty) ? t.required : null,
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
            onPressed: () => setState(() => _revealPassword = !_revealPassword),
          ),
          validator: (v) => (v == null || v.isEmpty) ? t.required : null,
        ),
      ),
      const SizedBox(height: 4),
      KarataButton(label: t.logIn, onPressed: _isLoading ? null : _submit),
      InlinePrompt(
        question: t.newHere,
        linkLabel: t.createAccount,
        onPressed: () => Navigator.of(context).pushReplacementNamed(
          authRouteWithRedirect('/register', widget.redirectTarget),
          arguments: {'serverUrl': widget.serverUrl},
        ),
      ),
    ];

    return Form(
      key: _formKey,
      child: KarataLayout.isWide(context)
          ? AuthSplitLayout(
              title: t.logIn,
              subtitle: t.loginSubtitle,
              children: fields,
            )
          : KarataScreen(
              onBack: () => Navigator.of(context).pop(),
              backLabel: t.back,
              title: t.logIn,
              subtitle: t.loginSubtitle,
              gap: 18,
              children: fields,
            ),
    );
  }
}
