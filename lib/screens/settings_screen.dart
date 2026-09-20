import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';
import '../chip_display.dart';
import '../l10n/app_localizations.dart';
import '../locale_controller.dart';
import '../sound_settings.dart';
import '../theme.dart';

/// Everything that used to be scattered across app bars, or had no home at all: language, table
/// sounds, how chip amounts are rendered, and the payment phone number - which until now could
/// only be changed as a side effect of buying or redeeming chips.
///
/// Deliberately absent: the server URL. That control is per-platform (a debug backend picker on
/// mobile, a plain field on web) and this file is shared between both clients, so it stays on the
/// welcome screen where each build can have its own.
class SettingsScreen extends StatefulWidget {
  final String serverUrl;
  final String token;
  final String username;

  const SettingsScreen({
    super.key,
    required this.serverUrl,
    required this.token,
    required this.username,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final ApiClient _apiClient;
  final _phoneController = TextEditingController();
  final _rateController = TextEditingController();

  bool _loadingPhone = true;
  bool _savingPhone = false;
  String? _phoneError;
  String? _savedPhone;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient(baseUrl: widget.serverUrl, token: widget.token);
    _rateController.text = ChipDisplay.instance.value.arPerChip.toString();
    _loadPhoneNumber();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  Future<void> _loadPhoneNumber() async {
    try {
      final phone = await _apiClient.getAccountPhoneNumber();
      if (!mounted) return;
      setState(() {
        _savedPhone = phone;
        _phoneController.text = phone ?? '';
        _loadingPhone = false;
      });
    } catch (e) {
      // The screen stays usable: a server we cannot reach only costs the phone-number row, and
      // saying so beats leaving an empty field that reads as "you have no number saved".
      if (!mounted) return;
      setState(() {
        _phoneError = AppLocalizations.of(
          context,
        ).couldNotLoadPhoneNumber(e.toString());
        _loadingPhone = false;
      });
    }
  }

  Future<void> _savePhoneNumber() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return;
    setState(() {
      _savingPhone = true;
      _phoneError = null;
    });
    try {
      await _apiClient.setAccountPhoneNumber(phone);
      if (!mounted) return;
      setState(() {
        _savedPhone = phone;
        _savingPhone = false;
      });
      final t = AppLocalizations.of(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.phoneNumberSaved)));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _savingPhone = false;
        _phoneError = AppLocalizations.of(
          context,
        ).couldNotSavePhoneNumber(e.toString());
      });
    }
  }

  void _onRateChanged(String raw) {
    final parsed = int.tryParse(raw.trim());
    if (parsed == null || parsed < ChipDisplay.minArPerChip) {
      setState(() {}); // Re-render so the invalid-rate hint appears.
      return;
    }
    ChipDisplay.instance.setArPerChip(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.settings)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            _SectionHeader(t.settingsGeneral),
            _languageTile(t),
            _soundTile(t),
            const SizedBox(height: 20),
            _SectionHeader(t.settingsTable),
            _chipDisplayTiles(t),
            const SizedBox(height: 20),
            _SectionHeader(t.settingsAccount),
            _phoneNumberTile(t),
            const SizedBox(height: 12),
            _logOutTile(t),
          ],
        ),
      ),
    );
  }

  Widget _languageTile(AppLocalizations t) {
    return ValueListenableBuilder<Locale?>(
      valueListenable: LocaleController.instance,
      builder: (context, locale, _) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.language, color: KarataColors.dim),
          title: Text(t.language, style: _titleStyle),
          trailing: DropdownButton<Locale?>(
            value: locale,
            underline: const SizedBox.shrink(),
            dropdownColor: KarataColors.pill,
            onChanged: LocaleController.instance.setLocale,
            items: [
              DropdownMenuItem(value: null, child: Text(t.systemDefault)),
              const DropdownMenuItem(
                value: Locale('en'),
                child: Text('English'),
              ),
              const DropdownMenuItem(
                value: Locale('fr'),
                child: Text('Français'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _soundTile(AppLocalizations t) {
    return ValueListenableBuilder<bool>(
      valueListenable: SoundSettings.instance,
      builder: (context, enabled, _) {
        return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: enabled,
          onChanged: SoundSettings.instance.setEnabled,
          title: Text(t.tableSounds, style: _titleStyle),
          subtitle: Text(t.tableSoundsSubtitle, style: _subtitleStyle),
          secondary: Icon(
            enabled ? Icons.volume_up : Icons.volume_off,
            color: KarataColors.dim,
          ),
        );
      },
    );
  }

  Widget _chipDisplayTiles(AppLocalizations t) {
    return ValueListenableBuilder<ChipDisplaySettings>(
      valueListenable: ChipDisplay.instance,
      builder: (context, settings, _) {
        final typed = int.tryParse(_rateController.text.trim());
        final rateValid = typed != null && typed >= ChipDisplay.minArPerChip;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: settings.asMoney,
              onChanged: ChipDisplay.instance.setAsMoney,
              title: Text(t.chipsAsMoney, style: _titleStyle),
              subtitle: Text(t.chipsAsMoneySubtitle, style: _subtitleStyle),
              secondary: const Icon(Icons.payments, color: KarataColors.dim),
            ),
            if (settings.asMoney) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _rateController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: _onRateChanged,
                decoration: InputDecoration(
                  labelText: t.arPerChip,
                  errorText: rateValid ? null : t.arPerChipInvalid,
                ),
              ),
              const SizedBox(height: 8),
              // A worked example, because "1 chip = 50 Ar" only becomes concrete once you see what
              // a real stack turns into at the table.
              Text(
                t.chipsAsMoneyExample(
                  '100',
                  ChipDisplay.formatWith(settings, 100),
                ),
                style: _subtitleStyle,
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _phoneNumberTile(AppLocalizations t) {
    if (_loadingPhone) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.phone, color: KarataColors.dim),
          title: Text(t.paymentPhoneNumber, style: _titleStyle),
          subtitle: Text(
            _savedPhone ?? t.phoneNumberNotSet,
            style: _subtitleStyle,
          ),
        ),
        Text(t.paymentPhoneNumberSubtitle, style: _subtitleStyle),
        const SizedBox(height: 10),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(labelText: t.paymentPhoneNumber),
        ),
        if (_phoneError != null) ...[
          const SizedBox(height: 8),
          Text(
            _phoneError!,
            style: const TextStyle(fontSize: 12.5, color: KarataColors.red),
          ),
        ],
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: _savingPhone ? null : _savePhoneNumber,
          child: _savingPhone
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(t.savePhoneNumber),
        ),
      ],
    );
  }

  /// Same keys MenuScreen clears - dropping only one of them leaves a half-session that
  /// RootScreen would still try to resume.
  Future<void> _logOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('username');
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  Widget _logOutTile(AppLocalizations t) {
    return OutlinedButton.icon(
      onPressed: _logOut,
      icon: const Icon(Icons.logout, color: KarataColors.red),
      label: Text(t.logOut, style: const TextStyle(color: KarataColors.red)),
    );
  }

  static const _titleStyle = TextStyle(fontSize: 15, color: KarataColors.ink);
  static const _subtitleStyle = TextStyle(
    fontSize: 12.5,
    color: KarataColors.dim,
  );
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11.5,
          letterSpacing: 1.1,
          color: KarataColors.dim,
        ),
      ),
    );
  }
}
