import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../l10n/app_localizations.dart';
import '../theme.dart';

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
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                children: [
                  Text(
                    t.economySettings,
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w300,
                      color: KarataColors.ink,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    t.chipPriceField,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: KarataColors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: KarataColors.ink),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isSavingPrice ? null : _savePrice,
                    child: _isSavingPrice
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: KarataColors.ink,
                            ),
                          )
                        : Text(t.savePrice),
                  ),
                  const SizedBox(height: 32),
                  const Divider(color: Color(0xFF1A181E)),
                  const SizedBox(height: 24),
                  Text(
                    t.sellSpreadPercentField,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: KarataColors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _spreadController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: KarataColors.ink),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    t.rakePercentField,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: KarataColors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _rakePercentController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: KarataColors.ink),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    t.rakeMinField,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: KarataColors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _rakeMinController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: KarataColors.ink),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    t.houseReceivingPhoneNumberField,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: KarataColors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _housePhoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: KarataColors.ink),
                    decoration: const InputDecoration(hintText: '+261...'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isSavingConfig ? null : _saveConfig,
                    child: _isSavingConfig
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: KarataColors.ink,
                            ),
                          )
                        : Text(t.saveConfig),
                  ),
                ],
              ),
      ),
    );
  }
}
