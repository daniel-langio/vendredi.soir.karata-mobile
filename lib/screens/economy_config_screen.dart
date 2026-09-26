import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../l10n/app_localizations.dart';
import '../theme/karata_colors.dart';
import '../widgets/common/karata_button.dart';
import '../widgets/common/karata_screen.dart';
import '../widgets/common/karata_switch.dart';
import '../widgets/common/setting_row.dart';
import '../widgets/common/karata_text_field.dart';
import '../widgets/common/labeled_field.dart';
import '../widgets/common/section_card.dart';

/// Operator-only. Two independent actions - the price and the rest of the config are separate
/// append-only ledgers server-side, so "save" for one never touches the other.
class EconomyConfigScreen extends StatefulWidget {
  final String serverUrl;
  final String token;
  final String username;

  const EconomyConfigScreen({
    super.key,
    required this.serverUrl,
    required this.token,
    required this.username,
  });

  @override
  State<EconomyConfigScreen> createState() => _EconomyConfigScreenState();
}

class _EconomyConfigScreenState extends State<EconomyConfigScreen> {
  late final ApiClient _apiClient;
  final _priceController = TextEditingController();
  final _spreadController = TextEditingController();
  final _rakePercentController = TextEditingController();
  final _rakeMinController = TextEditingController();
  final _housePhoneController = TextEditingController();

  /// Whether a new player must fund their wallet before they can reach the rest of the app.
  bool _enforceDeposit = false;
  bool _isLoading = true;
  bool _isSavingPrice = false;
  bool _isSavingConfig = false;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient(baseUrl: widget.serverUrl, token: widget.token);
    _load();
  }

  @override
  void dispose() {
    _priceController.dispose();
    _spreadController.dispose();
    _rakePercentController.dispose();
    _rakeMinController.dispose();
    _housePhoneController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final price = await _apiClient.getChipPrice();
      final config = await _apiClient.getEconomyConfig();
      if (!mounted) return;
      setState(() {
        _priceController.text = '${price['arPerChip']}';
        _spreadController.text = '${config['sellSpreadPercent']}';
        _rakePercentController.text = '${config['rakePercent']}';
        _rakeMinController.text = '${config['rakeMin']}';
        _housePhoneController.text = '${config['houseReceivingPhoneNumber']}';
        _enforceDeposit = config['enforceDepositOnRegistration'] == true;
      });
    } catch (e) {
      if (mounted) {
        // Resolved here rather than before the await: this loader runs from initState, and
        // looking up an inherited widget that early trips a framework assertion.
        final t = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.couldNotLoadPrice('$e')),
            backgroundColor: KarataColors.red,
          ),
        );
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _savePrice() async {
    final t = AppLocalizations.of(context);
    final price = int.tryParse(_priceController.text.trim());
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.fillValidValues),
          backgroundColor: KarataColors.red,
        ),
      );
      return;
    }
    setState(() => _isSavingPrice = true);
    try {
      await _apiClient.setChipPrice(price);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t.priceUpdated)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.couldNotUpdatePrice('$e')),
            backgroundColor: KarataColors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingPrice = false);
    }
  }

  Future<void> _saveConfig() async {
    final t = AppLocalizations.of(context);
    final spread = int.tryParse(_spreadController.text.trim());
    final rakePercent = int.tryParse(_rakePercentController.text.trim());
    final rakeMin = int.tryParse(_rakeMinController.text.trim());
    final housePhone = _housePhoneController.text.trim();
    if (spread == null ||
        spread < 0 ||
        rakePercent == null ||
        rakePercent < 0 ||
        rakeMin == null ||
        rakeMin < 0 ||
        housePhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.fillValidValues),
          backgroundColor: KarataColors.red,
        ),
      );
      return;
    }
    setState(() => _isSavingConfig = true);
    try {
      await _apiClient.setEconomyConfig(
        sellSpreadPercent: spread,
        rakePercent: rakePercent,
        rakeMin: rakeMin,
        houseReceivingPhoneNumber: housePhone,
        enforceDepositOnRegistration: _enforceDeposit,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t.configUpdated)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.couldNotUpdateConfig('$e')),
            backgroundColor: KarataColors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingConfig = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return KarataScreen(
      onBack: () => Navigator.of(context).pop(),
      backLabel: t.back,
      title: t.economySettings,
      children: _isLoading
          ? const [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(
                  child: CircularProgressIndicator(color: KarataColors.gold),
                ),
              ),
            ]
          : [
              SectionCard(
                title: t.chipPrice,
                children: [
                  LabeledField(
                    label: t.price,
                    child: KarataTextField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      fillColor: KarataColors.backdrop,
                      suffixText: t.arPerChip,
                    ),
                  ),
                  KarataButton(
                    label: t.savePrice,
                    onPressed: _isSavingPrice ? null : _savePrice,
                    height: 46,
                    style: KarataButtonStyle.surface,
                  ),
                ],
              ),
              SectionCard(
                title: t.fees,
                children: [
                  LabeledField(
                    label: t.sellSpreadPercentField,
                    child: KarataTextField(
                      controller: _spreadController,
                      keyboardType: TextInputType.number,
                      fillColor: KarataColors.backdrop,
                      suffixText: '%',
                    ),
                  ),
                  LabeledField(
                    label: t.rakePercentField,
                    child: KarataTextField(
                      controller: _rakePercentController,
                      keyboardType: TextInputType.number,
                      fillColor: KarataColors.backdrop,
                      suffixText: '%',
                    ),
                  ),
                  LabeledField(
                    label: t.rakeMinField,
                    child: KarataTextField(
                      controller: _rakeMinController,
                      keyboardType: TextInputType.number,
                      fillColor: KarataColors.backdrop,
                      suffixText: 'Ar',
                      hintText: t.noMinimum,
                    ),
                  ),
                ],
              ),
              SectionCard(
                title: t.registration,
                children: [
                  SettingRow(
                    title: t.enforceDeposit,
                    description: t.enforceDepositHint,
                    trailing: KarataSwitch(
                      value: _enforceDeposit,
                      semanticLabel: t.enforceDeposit,
                      onChanged: _isSavingConfig
                          ? null
                          : (value) => setState(() => _enforceDeposit = value),
                    ),
                  ),
                ],
              ),
              SectionCard(
                title: t.houseAccount,
                children: [
                  LabeledField(
                    label: t.receivingPhoneNumber,
                    child: KarataTextField(
                      controller: _housePhoneController,
                      keyboardType: TextInputType.phone,
                      fillColor: KarataColors.backdrop,
                    ),
                  ),
                ],
              ),
              KarataButton(
                label: t.saveConfig,
                onPressed: _isSavingConfig ? null : _saveConfig,
              ),
            ],
    );
  }
}
