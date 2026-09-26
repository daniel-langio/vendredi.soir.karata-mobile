import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../chip_display.dart';
import '../l10n/app_localizations.dart';
import '../theme/karata_colors.dart';
import '../theme/karata_text_styles.dart';
import '../widgets/common/circle_icon_button.dart';
import '../widgets/common/karata_card.dart';
import '../widgets/common/karata_icon.dart';
import '../widgets/common/karata_icons.dart';
import '../widgets/common/karata_screen.dart';
import '../widgets/common/section_card.dart';
import '../widgets/common/setting_row.dart';
import '../widgets/common/status_pill.dart';
import '../widgets/wallet/balance_card.dart';

/// The player's wallet: what they hold, what is tied up at tables, and the two things they can do
/// with it. Operator-only affordances - the payouts still owed, and the economy's own settings -
/// sit in a "House" card below rather than in the app bar.
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
  int? _walletChips;
  int? _atTablesChips;
  int _pendingCount = 0;
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
    try {
      final price = await _apiClient.getChipPrice();
      final wallet = await _apiClient.getWallet();
      final mine = await _apiClient.listMyTables();
      if (!mounted) return;
      setState(() {
        _price = price;
        _walletChips = wallet;
        // What the player has in front of them elsewhere, summed from the tables they are
        // actually seated at.
        _atTablesChips = mine.fold<int>(0, (total, game) {
          for (final p in (game['players'] as List<dynamic>? ?? const [])) {
            final player = p as Map<String, dynamic>;
            if (player['username'] == widget.username) {
              return total + ((player['chips'] as num?)?.toInt() ?? 0);
            }
          }
          return total;
        });
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

  Future<void> _loadIsOperator() async {
    try {
      final isOperator = await _apiClient.isOperator();
      if (!mounted) return;
      setState(() => _isOperator = isOperator);
      if (!isOperator) return;
      // Only an operator can see what is owed, and the badge is the only thing that needs it.
      final pending = await _apiClient.listPendingRedemptions();
      if (mounted) setState(() => _pendingCount = pending.length);
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
    _loadIsOperator();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return ValueListenableBuilder<ChipDisplaySettings>(
      valueListenable: ChipDisplay.instance,
      builder: (context, chipSettings, _) => KarataScreen(
        onBack: () => Navigator.of(context).pop(),
        backLabel: t.back,
        title: t.economyTitle,
        subtitle: t.economySubtitle,
        actions: [
          CircleIconButton(
            icon: KarataIcons.refresh,
            onPressed: _isLoading ? null : _load,
            semanticLabel: t.refresh,
          ),
        ],
        children: [
          BalanceCard(
            balanceLabel: t.balance,
            balance: _walletChips == null
                ? '—'
                : ChipDisplay.amountOnly(chipSettings, _walletChips),
            unit: chipSettings.unitLabel,
            atTablesLabel: t.atTables,
            atTables: _atTablesChips == null
                ? '—'
                : ChipDisplay.amountOnly(chipSettings, _atTablesChips),
            depositLabel: t.deposit,
            withdrawLabel: t.withdraw,
            onDeposit: _openBuy,
            onWithdraw: _openRedeem,
          ),
          // The per-chip rate is the one thing that can't be said without naming chips, and it's
          // redundant once every amount is already shown in Ariary - so it's dropped entirely
          // rather than reworded when money display is on.
          if (!chipSettings.asMoney && _price != null)
            KarataCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.buyPriceLine('${_price!['arPerChip']}'),
                    style: KarataText.body,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    t.sellPriceLine('${_price!['sellPricePerChip']}'),
                    style: KarataText.label,
                  ),
                ],
              ),
            ),
          if (_isOperator)
            SectionCard(
              title: t.house,
              trailing: t.admin,
              children: [
                SettingRow(
                  icon: KarataIcons.clock,
                  title: t.pendingRedemptions,
                  description: t.pendingRedemptionsHint,
                  onTap: _openPending,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_pendingCount > 0) ...[
                        StatusPill(
                          label: '$_pendingCount',
                          height: 22,
                          foreground: KarataColors.onGoldBadge,
                          background: KarataColors.gold,
                          ringColor: KarataColors.goldWash,
                        ),
                        const SizedBox(width: 8),
                      ],
                      const KarataIcon(
                        KarataIcons.chevronRight,
                        size: 18,
                        color: KarataColors.inkFaint,
                      ),
                    ],
                  ),
                ),
                const CardDivider(),
                SettingRow(
                  icon: KarataIcons.sliders,
                  title: t.economySettings,
                  description: t.economySettingsHint,
                  onTap: _openConfig,
                  trailing: const KarataIcon(
                    KarataIcons.chevronRight,
                    size: 18,
                    color: KarataColors.inkFaint,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
