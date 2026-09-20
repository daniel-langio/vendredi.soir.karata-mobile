import 'dart:async';
import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../l10n/app_localizations.dart';
import '../theme.dart';

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

  int get _quantity => int.tryParse(_quantityController.text.trim()) ?? 0;
  int get _totalPriceAr => _quantity * (_sellPricePerChip ?? 0);

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
    final t = AppLocalizations.of(context);
    try {
      final price = await _apiClient.getChipPrice();
      final config = await _apiClient.getEconomyConfig();
      if (!mounted) return;
      setState(() {
        _sellPricePerChip = (price['sellPricePerChip'] as num).toInt();
        _houseReceivingPhoneNumber =
            config['houseReceivingPhoneNumber'] as String?;
      });
    } catch (e) {
      if (mounted) {
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

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: _isLoadingPrice
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                children: [
                  Text(
                    t.buyChips,
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w300,
                      color: KarataColors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t.sellPriceLine('${_sellPricePerChip ?? 0}'),
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: KarataColors.dim,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (status == null) ...[
                    Text(
                      t.quantity,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: KarataColors.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: KarataColors.ink),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      t.paymentProvider,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: KarataColors.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _provider,
                      dropdownColor: KarataColors.field,
                      style: const TextStyle(color: KarataColors.ink),
                      items: const [
                        DropdownMenuItem(value: 'MVOLA', child: Text('MVola')),
                        DropdownMenuItem(
                          value: 'ORANGE_MONEY',
                          child: Text('Orange Money'),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _provider = value ?? _provider),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: KarataColors.field,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        t.payInstructions(
                          '$_totalPriceAr',
                          _houseReceivingPhoneNumber ?? '',
                        ),
                        style: const TextStyle(
                          color: KarataColors.ink,
                          fontSize: 13.5,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      t.yourPhoneNumber,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: KarataColors.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: KarataColors.ink),
                      decoration: const InputDecoration(hintText: '+261...'),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      t.transactionRef,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: KarataColors.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _refController,
                      style: const TextStyle(color: KarataColors.ink),
                      decoration: InputDecoration(
                        hintText: t.transactionRefHint,
                      ),
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitPayment,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: KarataColors.ink,
                              ),
                            )
                          : Text(t.submitPayment),
                    ),
                  ] else if (status == 'PENDING_PAYMENT') ...[
                    const SizedBox(height: 40),
                    const Center(child: CircularProgressIndicator()),
                    const SizedBox(height: 20),
                    Text(
                      t.waitingForConfirmation,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: KarataColors.dim,
                        fontSize: 13.5,
                        height: 1.5,
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 40),
                    const Center(
                      child: Icon(
                        Icons.check_circle,
                        color: KarataColors.chipInk,
                        size: 56,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      t.chipsCredited,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: KarataColors.ink,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(t.close),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}
