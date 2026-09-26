import 'dart:async';

import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../chip_display.dart';
import '../l10n/app_localizations.dart';
import '../theme/karata_colors.dart';
import '../theme/karata_text_styles.dart';
import '../widgets/common/amount_field.dart';
import '../widgets/common/choice_chips_row.dart';
import '../widgets/common/karata_button.dart';
import '../widgets/common/karata_screen.dart';
import '../widgets/common/karata_text_field.dart';
import '../widgets/common/labeled_field.dart';
import '../widgets/common/segmented_tabs.dart';
import '../widgets/wallet/summary_card.dart';

class ChipRedemptionScreen extends StatefulWidget {
  final String serverUrl;
  final String token;
  final String username;

  const ChipRedemptionScreen({
    super.key,
    required this.serverUrl,
    required this.token,
    required this.username,
  });

  @override
  State<ChipRedemptionScreen> createState() => _ChipRedemptionScreenState();
}

class _ChipRedemptionScreenState extends State<ChipRedemptionScreen> {
  late final ApiClient _apiClient;
  final _quantityController = TextEditingController(text: '1');
  final _phoneController = TextEditingController();
  String _provider = 'MVOLA';
  int? _buyPricePerChip;
  int? _walletChips;
  bool _isLoading = false;
  bool _isLoadingPrice = true;
  Map<String, dynamic>? _redemption;
  Timer? _pollTimer;

  static const _providers = ['MVOLA', 'ORANGE_MONEY'];

  ChipDisplaySettings get _display => ChipDisplay.instance.value;

  /// Chips to escrow for the payout. The field asks for whichever unit the player reads the rest
  /// of the app in - chips normally, Ariary once "show chips as money" is on - rather than quietly
  /// asking for chips under a wallet-flavoured screen. The API only ever speaks chips, so a money
  /// entry is divided back out at the very rate the payout itself is priced at ([_buyPricePerChip]
  /// is the server's `arPerChip`, the same number every balance on screen is rendered with).
  int get _quantity =>
      AmountField.chipsFrom(_display, _quantityController.text) ?? 0;
  int get _totalPriceAr => _quantity * (_buyPricePerChip ?? 0);

  /// The one-tap amounts under the field. The last is the whole balance, which is why it is
  /// "All" rather than a figure.
  List<int> get _presetEntries =>
      _display.inMoney ? const [10000, 50000, 100000] : const [10, 50, 100];

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient(baseUrl: widget.serverUrl, token: widget.token);
    _loadDefaultPhoneNumber();
    _loadPrice();
  }

  Future<void> _loadDefaultPhoneNumber() async {
    try {
      final phone = await _apiClient.getAccountPhoneNumber();
      if (mounted && phone != null) {
        setState(() => _phoneController.text = phone);
      }
    } catch (_) {
      // Non-critical - the field just starts empty if we can't reach the server.
    }
  }

  Future<void> _loadPrice() async {
    setState(() => _isLoadingPrice = true);
    try {
      final price = await _apiClient.getChipPrice();
      final wallet = await _apiClient.getWallet();
      if (!mounted) return;
      // Adopt the rate we just quoted, so the field's unit and the app's balances can't disagree.
      ChipDisplay.instance.applyRate(price);
      setState(() {
        _buyPricePerChip = (price['arPerChip'] as num).toInt();
        _walletChips = wallet;
        // Seed the default in the unit the field ended up asking for - "1" means one chip, which
        // is one rate's worth of Ariary once the amount is typed as money.
        _quantityController.text = AmountField.entryText(_display, 1);
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
    if (mounted) setState(() => _isLoadingPrice = false);
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _quantityController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      try {
        final updated = await _apiClient.getChipRedemption(
          _redemption!['id'] as String,
        );
        if (!mounted) return;
        setState(() => _redemption = updated);
        if (updated['status'] != 'PENDING_PAYOUT') _pollTimer?.cancel();
      } catch (_) {
        // Transient network hiccup while polling - just try again next tick.
      }
    });
  }

  Future<void> _submitRedemption() async {
    final t = AppLocalizations.of(context);
    final phone = _phoneController.text.trim();
    if (_quantity <= 0 || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.fillValidValues),
          backgroundColor: KarataColors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final redemption = await _apiClient.redeemChips(
        quantity: _quantity,
        payoutPhoneNumber: phone,
        provider: _provider,
      );
      if (!mounted) return;
      setState(() => _redemption = redemption);
      _startPolling();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.couldNotRedeemChips('$e')),
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
    final status = _redemption?['status'] as String?;

    return KarataScreen(
      onBack: () => Navigator.of(context).pop(),
      backLabel: t.back,
      title: t.redeemChips,
      subtitle: t.withdrawSubtitle,
      children: _isLoadingPrice
          ? const [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(
                  child: CircularProgressIndicator(color: KarataColors.gold),
                ),
              ),
            ]
          : switch (status) {
              null => _form(t),
              'PENDING_PAYOUT' => _message(t, t.waitingForPayout, busy: true),
              'COMPLETED' => _message(t, t.redemptionPaidOut),
              _ => _message(t, t.redemptionCancelled),
            },
    );
  }

  List<Widget> _form(AppLocalizations t) => [
    LabeledField(
      label: t.amount,
      child: AmountField(
        controller: _quantityController,
        display: _display,
        onChanged: (_) => setState(() {}),
      ),
    ),
    ChoiceChipsRow(
      labels: [
        for (final entry in _presetEntries)
          _display.inMoney ? ChipDisplay.groupDigits(entry) : '$entry',
        t.allPreset,
      ],
      selectedIndex: _selectedPreset,
      onSelected: _applyPreset,
    ),
    LabeledField(
      label: t.paymentProvider,
      child: SegmentedTabs(
        height: 40,
        labels: const ['MVola', 'Orange Money'],
        selectedIndex: _providers.indexOf(_provider),
        onChanged: (i) => setState(() => _provider = _providers[i]),
      ),
    ),
    LabeledField(
      label: t.payoutPhoneNumber,
      child: KarataTextField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        hintText: '+261...',
      ),
    ),
    SummaryCard(
      lines: [
        (
          label: t.chipsBurned,
          value: ChipDisplay.formatWith(_display, _quantity),
          emphasised: false,
        ),
        (
          label: t.youWillReceive,
          value: '${ChipDisplay.groupDigits(_totalPriceAr)} Ar',
          emphasised: true,
        ),
      ],
    ),
    Text(t.payoutsByHand, style: KarataText.label),
    KarataButton(
      label: t.redeemChips,
      onPressed: _isLoading ? null : _submitRedemption,
    ),
  ];

  int? get _selectedPreset {
    for (var i = 0; i < _presetEntries.length; i++) {
      if (_display.chipsFromEntry(_presetEntries[i]) == _quantity) return i;
    }
    if (_walletChips != null && _quantity == _walletChips) {
      return _presetEntries.length;
    }
    return null;
  }

  void _applyPreset(int index) {
    setState(() {
      if (index < _presetEntries.length) {
        _quantityController.text = _display.inMoney
            ? ChipDisplay.groupDigits(_presetEntries[index])
            : '${_presetEntries[index]}';
      } else if (_walletChips != null) {
        _quantityController.text = AmountField.entryText(
          _display,
          _walletChips!,
        );
      }
    });
  }

  /// The terminal states: waiting for the house to pay out, paid, or cancelled.
  List<Widget> _message(
    AppLocalizations t,
    String message, {
    bool busy = false,
  }) => [
    if (busy)
      const Padding(
        padding: EdgeInsets.only(top: 40),
        child: Center(
          child: CircularProgressIndicator(color: KarataColors.gold),
        ),
      )
    else
      const SizedBox(height: 24),
    Text(
      message,
      textAlign: TextAlign.center,
      style: busy ? KarataText.subtitle : karataText(size: 17, weight: 800),
    ),
    if (!busy)
      KarataButton(
        label: t.close,
        onPressed: () => Navigator.of(context).pop(),
      ),
  ];
}
