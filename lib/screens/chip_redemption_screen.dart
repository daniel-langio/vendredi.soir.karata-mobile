import 'dart:async';
import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../l10n/app_localizations.dart';
import '../theme.dart';

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
  bool _isLoading = false;
  bool _isLoadingPrice = true;
  Map<String, dynamic>? _redemption;
  Timer? _pollTimer;

  int get _quantity => int.tryParse(_quantityController.text.trim()) ?? 0;
  int get _totalPriceAr => _quantity * (_buyPricePerChip ?? 0);

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
    final t = AppLocalizations.of(context);
    try {
      final price = await _apiClient.getChipPrice();
      if (!mounted) return;
      setState(() => _buyPricePerChip = (price['arPerChip'] as num).toInt());
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

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: _isLoadingPrice
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                children: [
                  Text(
                    t.redeemChips,
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w300,
                      color: KarataColors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t.buyPriceLine('${_buyPricePerChip ?? 0}'),
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
                        t.redeemTotalLine('$_totalPriceAr'),
                        style: const TextStyle(
                          color: KarataColors.ink,
                          fontSize: 13.5,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      t.payoutPhoneNumber,
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
                    const SizedBox(height: 28),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitRedemption,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: KarataColors.ink,
                              ),
                            )
                          : Text(t.submitRedemption),
                    ),
                  ] else if (status == 'PENDING_PAYOUT') ...[
                    const SizedBox(height: 40),
                    const Center(child: CircularProgressIndicator()),
                    const SizedBox(height: 20),
                    Text(
                      t.waitingForPayout,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: KarataColors.dim,
                        fontSize: 13.5,
                        height: 1.5,
                      ),
                    ),
                  ] else if (status == 'COMPLETED') ...[
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
                      t.redemptionPaidOut,
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
                  ] else ...[
                    const SizedBox(height: 40),
                    const Center(
                      child: Icon(
                        Icons.cancel_rounded,
                        color: KarataColors.red,
                        size: 56,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      t.redemptionCancelled,
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
