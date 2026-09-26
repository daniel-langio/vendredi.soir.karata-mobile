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
import '../widgets/wallet/payment_notice.dart';
import '../widgets/wallet/step_heading.dart';
import '../widgets/wallet/summary_card.dart';

class ChipPurchaseScreen extends StatefulWidget {
  final String serverUrl;
  final String token;
  final String username;

  const ChipPurchaseScreen({
    super.key,
    required this.serverUrl,
    required this.token,
    required this.username,
  });

  @override
  State<ChipPurchaseScreen> createState() => _ChipPurchaseScreenState();
}

class _ChipPurchaseScreenState extends State<ChipPurchaseScreen> {
  late final ApiClient _apiClient;
  final _quantityController = TextEditingController(text: '1');
  final _phoneController = TextEditingController();
  final _refController = TextEditingController();
  String _provider = 'MVOLA';
  String? _houseReceivingPhoneNumber;
  int? _sellPricePerChip;
  bool _isLoading = false;
  bool _isLoadingPrice = true;
  Map<String, dynamic>? _purchase;
  Timer? _pollTimer;

  static const _providers = ['MVOLA', 'ORANGE_MONEY'];

  ChipDisplaySettings get _display => ChipDisplay.instance.value;

  /// Chips to credit. In money mode the field asks for the amount the player wants *in their
  /// wallet*, converted at the same rate their balance is shown at - so the number they type is
  /// the number they will see afterwards. What they actually have to send is [_totalPriceAr],
  /// which is higher: the house's spread lives between the two, and the pay instructions below
  /// state it outright rather than burying it in a per-chip rate.
  int get _quantity =>
      AmountField.chipsFrom(_display, _quantityController.text) ?? 0;
  int get _totalPriceAr => _quantity * (_sellPricePerChip ?? 0);

  /// What the credited chips are worth at the rate balances are shown at - the top line of the
  /// breakdown, and the thing the spread is measured against.
  int get _creditedValueAr => _quantity * _display.arPerChip;
  int get _feeAr => _totalPriceAr - _creditedValueAr;

  /// The one-tap amounts under the field, in whichever unit the field is asking for.
  List<int> get _presetEntries => _display.inMoney
      ? const [10000, 20000, 50000, 100000]
      : const [10, 20, 50, 100];

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient(baseUrl: widget.serverUrl, token: widget.token);
    _loadDefaultPhoneNumber();
    _loadPriceAndConfig();
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

  Future<void> _loadPriceAndConfig() async {
    setState(() => _isLoadingPrice = true);
    try {
      final price = await _apiClient.getChipPrice();
      final config = await _apiClient.getEconomyConfig();
      if (!mounted) return;
      // Adopt the rate we just fetched, so the field's unit and the app's balances can't disagree.
      ChipDisplay.instance.applyRate(price);
      setState(() {
        _sellPricePerChip = (price['sellPricePerChip'] as num).toInt();
        _houseReceivingPhoneNumber =
            config['houseReceivingPhoneNumber'] as String?;
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
    _refController.dispose();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      try {
        final updated = await _apiClient.getChipPurchase(
          _purchase!['id'] as String,
        );
        if (!mounted) return;
        setState(() => _purchase = updated);
        if (updated['status'] != 'PENDING_PAYMENT') _pollTimer?.cancel();
      } catch (_) {
        // Transient network hiccup while polling - just try again next tick.
      }
    });
  }

  Future<void> _copyHouseNumber() async {
    final number = _houseReceivingPhoneNumber;
    if (number == null || number.isEmpty) return;
    await copyToClipboard(number);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).numberCopied)),
    );
  }

  Future<void> _submitPayment() async {
    final t = AppLocalizations.of(context);
    final phone = _phoneController.text.trim();
    final ref = _refController.text.trim();
    if (_quantity <= 0 || phone.isEmpty || ref.isEmpty) {
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
      final purchase = await _apiClient.buyChips(
        quantity: _quantity,
        buyerPhoneNumber: phone,
        provider: _provider,
        pspRef: ref,
      );
      if (!mounted) return;
      setState(() => _purchase = purchase);
      _startPolling();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.couldNotBuyChips('$e')),
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
    final status = _purchase?['status'] as String?;

    return KarataScreen(
      onBack: () => Navigator.of(context).pop(),
      backLabel: t.back,
      title: t.buyChips,
      subtitle: t.depositSubtitle,
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
              'PENDING_PAYMENT' => _waiting(t),
              _ => _done(t),
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
      ],
      selectedIndex: _presetEntries.indexWhere(
        (entry) => _display.chipsFromEntry(entry) == _quantity,
      ),
      onSelected: (i) => setState(() {
        _quantityController.text = _display.inMoney
            ? ChipDisplay.groupDigits(_presetEntries[i])
            : '${_presetEntries[i]}';
      }),
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
    SummaryCard(
      lines: [
        (
          label: t.chipsYouGet,
          value: ChipDisplay.formatWith(_display, _quantity),
          emphasised: false,
        ),
        (
          label: t.fee,
          value: '${ChipDisplay.groupDigits(_feeAr)} Ar',
          emphasised: false,
        ),
        (
          label: t.youPay,
          value: '${ChipDisplay.groupDigits(_totalPriceAr)} Ar',
          emphasised: true,
        ),
      ],
    ),
    StepHeading(number: 1, label: t.sendThePayment),
    PaymentNotice(
      sentence: t.payInstructions('{amount}', '{phone}'),
      amount: '${ChipDisplay.groupDigits(_totalPriceAr)} Ar',
      phoneNumber: _houseReceivingPhoneNumber ?? '',
      copyLabel: t.copyNumber,
      onCopy: _copyHouseNumber,
    ),
    StepHeading(number: 2, label: t.confirmItHere),
    LabeledField(
      label: t.yourPhoneNumber,
      child: KarataTextField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        hintText: '+261...',
      ),
    ),
    LabeledField(
      label: t.transactionRef,
      child: KarataTextField(
        controller: _refController,
        hintText: t.transactionRefHint,
      ),
    ),
    KarataButton(
      label: t.submitPayment,
      onPressed: _isLoading ? null : _submitPayment,
    ),
  ];

  List<Widget> _waiting(AppLocalizations t) => [
    const Padding(
      padding: EdgeInsets.only(top: 40),
      child: Center(child: CircularProgressIndicator(color: KarataColors.gold)),
    ),
    Text(
      t.waitingForConfirmation,
      textAlign: TextAlign.center,
      style: KarataText.subtitle,
    ),
  ];

  List<Widget> _done(AppLocalizations t) => [
    const SizedBox(height: 24),
    Text(
      t.chipsCredited,
      textAlign: TextAlign.center,
      style: karataText(size: 17, weight: 800),
    ),
    KarataButton(label: t.close, onPressed: () => Navigator.of(context).pop()),
  ];
}
