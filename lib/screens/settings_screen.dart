import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';
import '../chip_display.dart';
import '../l10n/app_localizations.dart';
import '../locale_controller.dart';
import '../sound_settings.dart';
import '../theme/karata_colors.dart';
import '../theme/karata_text_styles.dart';
import '../widgets/common/karata_button.dart';
import '../widgets/common/karata_card.dart';
import '../widgets/common/karata_dropdown.dart';
import '../widgets/common/karata_icons.dart';
import '../widgets/common/karata_screen.dart';
import '../widgets/common/karata_switch.dart';
import '../widgets/common/karata_text_field.dart';
import '../widgets/common/labeled_field.dart';
import '../widgets/common/note_well.dart';
import '../widgets/common/section_card.dart';
import '../widgets/common/setting_row.dart';

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

  bool _loadingPhone = true;
  bool _savingPhone = false;
  String? _phoneError;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient(baseUrl: widget.serverUrl, token: widget.token);
    _loadPhoneNumber();
    ChipDisplay.instance.refreshRateFromServer(_apiClient);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadPhoneNumber() async {
    try {
      final phone = await _apiClient.getAccountPhoneNumber();
      if (!mounted) return;
      setState(() {
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
      setState(() => _savingPhone = false);
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

  /// Same keys MenuScreen clears - dropping only one of them leaves a half-session that
  /// RootScreen would still try to resume.
  Future<void> _logOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('username');
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return KarataScreen(
      onBack: () => Navigator.of(context).pop(),
      backLabel: t.back,
      title: t.settings,
      children: [
        SectionCard(
          title: t.settingsGeneral,
          children: [_languageRow(t), const CardDivider(), _soundRow(t)],
        ),
        SectionCard(title: t.settingsTable, children: _chipDisplayRows(t)),
        SectionCard(title: t.settingsAccount, children: _accountRows(t)),
        KarataButton(
          label: t.logOut,
          icon: KarataIcons.logout,
          onPressed: _logOut,
          style: KarataButtonStyle.danger,
          height: 50,
        ),
      ],
    );
  }

  Widget _languageRow(AppLocalizations t) {
    return ValueListenableBuilder<Locale?>(
      valueListenable: LocaleController.instance,
      builder: (context, locale, _) => SettingRow(
        icon: KarataIcons.globe,
        title: t.language,
        trailing: KarataDropdown<Locale?>(
          value: locale,
          height: 40,
          fontSize: 14,
          expand: false,
          onChanged: LocaleController.instance.setLocale,
          items: [
            (null, t.systemDefault),
            (const Locale('fr'), 'Français'),
            (const Locale('en'), 'English'),
          ],
        ),
      ),
    );
  }

  Widget _soundRow(AppLocalizations t) {
    return ValueListenableBuilder<bool>(
      valueListenable: SoundSettings.instance,
      builder: (context, enabled, _) => SettingRow(
        icon: KarataIcons.speaker,
        title: t.tableSounds,
        description: t.tableSoundsSubtitle,
        trailing: KarataSwitch(
          value: enabled,
          semanticLabel: t.tableSounds,
          onChanged: SoundSettings.instance.setEnabled,
        ),
      ),
    );
  }

  List<Widget> _chipDisplayRows(AppLocalizations t) {
    return [
      ValueListenableBuilder<ChipDisplaySettings>(
        valueListenable: ChipDisplay.instance,
        builder: (context, settings, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SettingRow(
              icon: KarataIcons.money,
              title: t.chipsAsMoney,
              description: t.chipsAsMoneySubtitle,
              trailing: KarataSwitch(
                value: settings.asMoney,
                semanticLabel: t.chipsAsMoney,
                onChanged: ChipDisplay.instance.setAsMoney,
              ),
            ),
            // A worked example, because the live rate only becomes concrete once you see what a
            // real stack turns into at the table. Held back until a rate is actually known -
            // "100 chips shows as 100" would teach the player the wrong number.
            if (settings.inMoney) ...[
              const SizedBox(height: 16),
              NoteWell(
                text: t.chipsAsMoneyExample(
                  '100',
                  ChipDisplay.formatWith(settings, 100),
                ),
              ),
            ],
          ],
        ),
      ),
    ];
  }

  List<Widget> _accountRows(AppLocalizations t) {
    if (_loadingPhone) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: CircularProgressIndicator(color: KarataColors.gold),
          ),
        ),
      ];
    }
    return [
      LabeledField(
        label: t.paymentPhoneNumber,
        child: KarataTextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          fillColor: KarataColors.backdrop,
        ),
      ),
      Text(t.paymentPhoneNumberSubtitle, style: KarataText.label),
      if (_phoneError != null)
        Text(
          _phoneError!,
          style: karataText(
            size: 13,
            weight: 600,
            color: KarataColors.orangeLight,
          ),
        ),
      KarataButton(
        label: t.savePhoneNumber,
        onPressed: _savingPhone ? null : _savePhoneNumber,
        height: 46,
        style: KarataButtonStyle.surface,
      ),
    ];
  }
}
