import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../chip_display.dart';
import '../l10n/app_localizations.dart';
import '../session_summary.dart';
import '../theme/karata_colors.dart';
import '../theme/karata_text_styles.dart';
import '../widgets/common/breakpoints.dart';
import '../widgets/common/circle_icon_button.dart';
import '../widgets/common/karata_card.dart';
import '../widgets/common/karata_icon.dart';
import '../widgets/common/karata_icons.dart';
import '../widgets/common/karata_screen.dart';
import '../widgets/common/section_card.dart';
import '../widgets/common/setting_row.dart';
import '../widgets/desktop/desktop_shell.dart';
import '../widgets/desktop/desktop_sidebar.dart';
import '../widgets/desktop/wide_balance_strip.dart';
import '../widgets/wallet/how_it_works_card.dart';
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
      // The sidebar shows this balance too, on every wide screen; publishing it here keeps the
      // two from drifting apart after a deposit or a withdrawal.
      SessionSummary.instance.setBalance(wallet);
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
      SessionSummary.instance.setHouse(isOperator: isOperator);
      if (!mounted) return;
      setState(() => _isOperator = isOperator);
      if (!isOperator) return;
      // Only an operator can see what is owed, and the badge is the only thing that needs it.
      final pending = await _apiClient.listPendingRedemptions();
      SessionSummary.instance.setHouse(
        isOperator: true,
        pendingCount: pending.length,
      );
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
      builder: (context, chipSettings, _) => KarataLayout.isWide(context)
          ? _wide(t, chipSettings)
          : KarataScreen(
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
                if (_isOperator) _houseCard(t),
              ],
            ),
    );
  }

  /// The operator's own corner of the wallet: the last card on the phone's page, and the
  /// right-hand column of the wide grid.
  Widget _houseCard(AppLocalizations t) {
    return SectionCard(
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
    );
  }

  /// Artboard 25: the balance as a band across the top, then the explainer and the House card
  /// side by side.
  Widget _wide(AppLocalizations t, ChipDisplaySettings chipSettings) {
    final rate = _price;
    return DesktopShell(
      current: DesktopNav.wallet,
      sessionArgs: _sessionArgs,
      username: widget.username,
      title: t.economyTitle,
      subtitle: t.economySubtitle,
      actions: [
        CircleIconButton(
          icon: KarataIcons.refresh,
          onPressed: _isLoading ? null : _load,
          semanticLabel: t.refresh,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WideBalanceStrip(
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
          const SizedBox(height: 28),
          DesktopColumns(
            left: [
              HowItWorksCard(
                title: t.howItWorks,
                steps: [
                  (t.deposit, t.howItWorksDeposit),
                  (t.howItWorksPlayLead, t.howItWorksPlay),
                  (t.withdraw, t.howItWorksWithdraw),
                ],
              ),
              // Same reasoning as the phone: the per-chip rate is the one thing that cannot be
              // said without naming chips, and is redundant once amounts are already in Ariary.
              if (!chipSettings.asMoney && rate != null) _rateCard(t, rate),
            ],
            right: [if (_isOperator) _houseCard(t)],
          ),
        ],
      ),
    );
  }

  Widget _rateCard(AppLocalizations t, Map<String, dynamic> rate) {
    return KarataCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.buyPriceLine('${rate['arPerChip']}'), style: KarataText.body),
          const SizedBox(height: 6),
          Text(
            t.sellPriceLine('${rate['sellPricePerChip']}'),
            style: KarataText.label,
          ),
        ],
      ),
    );
  }
}
