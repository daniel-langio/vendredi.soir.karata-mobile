import 'dart:async';

import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../chip_display.dart';
import '../l10n/app_localizations.dart';
import '../theme/karata_colors.dart';
import '../theme/karata_text_styles.dart';
import '../widgets/common/amount_field.dart';
import '../widgets/common/breakpoints.dart';
import '../widgets/common/choice_chips_row.dart';
import '../widgets/common/karata_button.dart';
import '../widgets/common/karata_screen.dart';
import '../widgets/common/karata_text_field.dart';
import '../widgets/common/labeled_field.dart';
import '../widgets/common/segmented_tabs.dart';
import '../widgets/wallet/payment_notice.dart';
import '../widgets/common/circle_icon_button.dart';
import '../widgets/common/karata_icons.dart';
import '../widgets/common/section_card.dart';
import '../widgets/desktop/desktop_shell.dart';
import '../widgets/desktop/desktop_sidebar.dart';
import '../widgets/wallet/step_heading.dart';
import '../widgets/wallet/summary_card.dart';

class ChipPurchaseScreen extends StatefulWidget {
  final String serverUrl;
  final String token;
  final String username;

  /// Shown to a player who has just registered, rather than reached from the wallet.
  ///
  /// Changes only the framing - the heading welcomes them, and there is a way past it unless the
  /// house has said there isn't. The deposit itself is the same flow, so there is one of it to
  /// keep working rather than a second, nearly-identical first-run form.
  final bool onboarding;

  /// Whether a way past is offered. False means the house requires the deposit - see the economy
  /// config's enforceDepositOnRegistration.
  final bool skippable;

  const ChipPurchaseScreen({
    super.key,
    required this.serverUrl,
    required this.token,
    required this.username,
    this.onboarding = false,
    this.skippable = true,
  });

  @override
  State<ChipPurchaseScreen> createState() => _ChipPurchaseScreenState();
}

class _ChipPurchaseScreenState extends State<ChipPurchaseScreen> {
  /// What every route this screen pushes needs to keep the session alive across it.
  Map<String, dynamic> get _sessionArgs => {
    'serverUrl': widget.serverUrl,
    'token': widget.token,
    'username': widget.username,
  };
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

  /// Leaves the first-run deposit for the lobby, clearing the stack behind it - there is nothing
  /// back there but the registration form.
  void _leaveOnboarding() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/menu',
      (route) => false,
      arguments: {
        'serverUrl': widget.serverUrl,
        'token': widget.token,
        'username': widget.username,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final status = _purchase?['status'] as String?;

    const spinner = Padding(
      padding: EdgeInsets.symmetric(vertical: 60),
      child: Center(child: CircularProgressIndicator(color: KarataColors.gold)),
    );
    final rows = _isLoadingPrice
        ? const <Widget>[spinner]
        : switch (status) {
            null => _form(t),
            'PENDING_PAYMENT' => _waiting(t),
            _ => _done(t),
          };

    // The first-run deposit keeps the phone's frame at every width: it is a gate, and the wide
    // frame is a sidebar that would walk straight around it. The mockups draw no wide version
    // of it either.
    if (!widget.onboarding && KarataLayout.isWide(context)) {
      return DesktopShell(
        // Deposit has no entry of its own; artboard 26 keeps the wallet lit behind it.
        current: DesktopNav.wallet,
        sessionArgs: _sessionArgs,
        username: widget.username,
        title: t.buyChips,
        subtitle: t.depositSubtitle,
        actions: [
          CircleIconButton(
            icon: KarataIcons.back,
            onPressed: () => Navigator.of(context).pop(),
            semanticLabel: t.back,
          ),
        ],
        child: _isLoadingPrice || status != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: rows,
              )
            : _wideForm(t),
      );
    }

    return KarataScreen(
      // No way back during onboarding: there is nothing behind it but the form they just left.
      onBack: widget.onboarding ? null : () => Navigator.of(context).pop(),
      backLabel: t.back,
      title: widget.onboarding ? t.onboardingTitle : t.buyChips,
      subtitle: widget.onboarding ? t.onboardingSubtitle : t.depositSubtitle,
      children: rows,
    );
  }

  /// Artboard 26: what to pay on the left, how to pay it on the right.
  Widget _wideForm(AppLocalizations t) {
    return DesktopColumns(
      left: [
        // The phone lists these three rows down the page; the wide drawing gathers them into a
        // card of their own.
        SectionCard(title: t.amount, ribbon: true, children: _amountRows(t)),
        _summaryCard(t),
      ],
      right: _paymentRows(t),
    );
  }

  List<Widget> _form(AppLocalizations t) => [
    ..._amountRows(t),
    _summaryCard(t),
    ..._paymentRows(t),
  ];

  /// How much, from which provider.
  List<Widget> _amountRows(AppLocalizations t) => [
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
  ];

  /// What that comes to, once the fee is added.
  Widget _summaryCard(AppLocalizations t) => SummaryCard(
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
  );

  /// Sending the money, then telling the house you have.
  List<Widget> _paymentRows(AppLocalizations t) => [
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
    if (widget.onboarding && widget.skippable)
      KarataButton(
        label: t.skipForNow,
        onPressed: _leaveOnboarding,
        style: KarataButtonStyle.secondary,
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
