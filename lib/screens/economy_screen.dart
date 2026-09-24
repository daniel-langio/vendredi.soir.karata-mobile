import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../chip_display.dart';
import '../l10n/app_localizations.dart';
import '../theme.dart';

/// Landing page for the chip economy: the current global price, and the two things a player can
/// do with it (buy/redeem). Replaces the old marketplace's listing browser - there is nothing to
/// browse anymore, just one global rate. Operator-only affordances (moving the price/config,
/// seeing what payouts are still owed) show up as app bar actions rather than a FAB, since there
/// isn't a single "create" action anymore.
class EconomyScreen extends StatefulWidget {
  final String serverUrl;
  final String token;
  final String username;

  const EconomyScreen({
    super.key,
    required this.serverUrl,
    required this.token,
    required this.username,
  });

  @override
  State<EconomyScreen> createState() => _EconomyScreenState();
}

class _EconomyScreenState extends State<EconomyScreen> {
  late final ApiClient _apiClient;
  Map<String, dynamic>? _price;
  bool _isLoading = true;

  /// Answered by the server (`operator` on GET /account) rather than by comparing the username to
  /// a hardcoded "dev". Defaults to false so a failed lookup hides the affordances rather than
  /// offering ones that would 403.
  bool _isOperator = false;

  Map<String, dynamic> get _sessionArgs => {
    'serverUrl': widget.serverUrl,
    'token': widget.token,
    'username': widget.username,
  };

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient(baseUrl: widget.serverUrl, token: widget.token);
    _load();
    _loadIsOperator();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final t = AppLocalizations.of(context);
    try {
      final price = await _apiClient.getChipPrice();
      if (!mounted) return;
      setState(() => _price = price);
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
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadIsOperator() async {
    try {
      final isOperator = await _apiClient.isOperator();
      if (mounted) setState(() => _isOperator = isOperator);
    } catch (_) {
      // Leave false - an unreachable server is not a reason to show operator affordances.
    }
  }

  Future<void> _openBuy() async {
    await Navigator.of(
      context,
    ).pushNamed('/economy/buy', arguments: _sessionArgs);
    _load();
  }

  Future<void> _openRedeem() async {
    await Navigator.of(
      context,
    ).pushNamed('/economy/redeem', arguments: _sessionArgs);
    _load();
  }

  Future<void> _openConfig() async {
    await Navigator.of(
      context,
    ).pushNamed('/economy/config', arguments: _sessionArgs);
    _load();
  }

  Future<void> _openPending() async {
    await Navigator.of(
      context,
    ).pushNamed('/economy/pending', arguments: _sessionArgs);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final buyPrice = _price?['arPerChip'];
    final sellPrice = _price?['sellPricePerChip'];

    return Scaffold(
      appBar: AppBar(
        actions: [
          if (_isOperator)
            IconButton(
              icon: const Icon(Icons.pending_actions_rounded),
              onPressed: _openPending,
              tooltip: t.pendingRedemptions,
            ),
          if (_isOperator)
            IconButton(
              icon: const Icon(Icons.tune_rounded),
              onPressed: _openConfig,
              tooltip: t.economySettings,
            ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      t.economyTitle,
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w300,
                        color: KarataColors.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      t.economySubtitle,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: KarataColors.dim,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // The per-chip rate is the one thing that can't be said without naming chips,
                    // and it's redundant once every amount is already shown in Ariary - so it's
                    // dropped entirely rather than reworded when money display is on.
                    if (!ChipDisplay.instance.value.asMoney) ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: KarataColors.field,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.buyPriceLine('$buyPrice'),
                              style: const TextStyle(
                                color: KarataColors.ink,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              t.sellPriceLine('$sellPrice'),
                              style: const TextStyle(
                                color: KarataColors.dim,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],
                    ElevatedButton(
                      onPressed: _openBuy,
                      child: Text(t.buyChips),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _openRedeem,
                      child: Text(t.redeemChips),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
