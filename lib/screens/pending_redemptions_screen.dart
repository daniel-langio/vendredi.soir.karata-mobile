import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../chip_display.dart';
import '../l10n/app_localizations.dart';
import '../theme/karata_colors.dart';
import '../theme/karata_text_styles.dart';
import '../widgets/common/breakpoints.dart';
import '../widgets/common/circle_icon_button.dart';
import '../widgets/common/karata_card.dart';
import '../widgets/common/karata_icons.dart';
import '../widgets/common/karata_screen.dart';
import '../widgets/common/section_card.dart';
import '../widgets/common/status_pill.dart';
import '../widgets/desktop/desktop_shell.dart';
import '../widgets/desktop/desktop_sidebar.dart';
import '../widgets/desktop/wide_pending_table.dart';
import '../widgets/wallet/pending_payout_row.dart';
import '../widgets/wallet/summary_card.dart';

/// Operator-only: what the house still needs to go and send by mobile money to close out a
/// withdrawal. Cancelling refunds the escrowed chips back to the player.
class PendingRedemptionsScreen extends StatefulWidget {
  final String serverUrl;
  final String token;
  final String username;

  const PendingRedemptionsScreen({
    super.key,
    required this.serverUrl,
    required this.token,
    required this.username,
  });

  @override
  State<PendingRedemptionsScreen> createState() =>
      _PendingRedemptionsScreenState();
}

class _PendingRedemptionsScreenState extends State<PendingRedemptionsScreen> {
  /// What every route this screen pushes needs to keep the session alive across it.
  Map<String, dynamic> get _sessionArgs => {
    'serverUrl': widget.serverUrl,
    'token': widget.token,
    'username': widget.username,
  };
  late final ApiClient _apiClient;
  List<Map<String, dynamic>> _pending = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient(baseUrl: widget.serverUrl, token: widget.token);
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final pending = await _apiClient.listPendingRedemptions();
      if (!mounted) return;
      setState(() => _pending = pending);
    } catch (e) {
      if (mounted) {
        // Resolved here rather than before the await: this loader runs from initState, and
        // looking up an inherited widget that early trips a framework assertion.
        final t = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.couldNotLoadPendingRedemptions('$e')),
            backgroundColor: KarataColors.red,
          ),
        );
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  int get _owedAr => _pending.fold<int>(
    0,
    (total, r) => total + ((r['totalPriceAr'] as num?)?.toInt() ?? 0),
  );

  Future<void> _cancel(Map<String, dynamic> redemption) async {
    final t = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.cancelRedemptionTitle),
        content: Text(t.cancelRedemptionContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.cancelRedemptionButton),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _apiClient.cancelRedemption(redemption['id'] as String);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.couldNotCancelRedemption('$e')),
            backgroundColor: KarataColors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    if (KarataLayout.isWide(context)) return _wide(t);

    return KarataScreen(
      onBack: () => Navigator.of(context).pop(),
      backLabel: t.back,
      title: t.pendingRedemptions,
      subtitle: t.pendingRedemptionsSubtitle,
      actions: [
        CircleIconButton(
          icon: KarataIcons.refresh,
          onPressed: _isLoading ? null : _load,
          semanticLabel: t.refresh,
        ),
      ],
      children: _isLoading
          ? const [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(
                  child: CircularProgressIndicator(color: KarataColors.gold),
                ),
              ),
            ]
          : _pending.isEmpty
          ? [
              KarataCard(
                child: Text(
                  t.noPendingRedemptions,
                  textAlign: TextAlign.center,
                  style: KarataText.subtitle,
                ),
              ),
            ]
          : [
              SummaryCard(
                lines: [
                  (
                    label: t.owedInTotal,
                    value: '${ChipDisplay.groupDigits(_owedAr)} Ar',
                    emphasised: true,
                  ),
                ],
              ),
              SectionCard(
                title: t.toSend,
                trailingWidget: StatusPill(
                  label: t.nPending('${_pending.length}'),
                  height: 22,
                  foreground: KarataColors.onGoldBadge,
                  background: KarataColors.gold,
                  ringColor: KarataColors.goldWash,
                ),
                children: [
                  for (final r in _pending) ...[
                    if (r != _pending.first) const CardDivider(),
                    PendingPayoutRow(
                      amount:
                          '${ChipDisplay.groupDigits((r['totalPriceAr'] as num?)?.toInt() ?? 0)} Ar',
                      phoneNumber: '${r['payoutPhoneNumber']}',
                      provider: _providerLabel('${r['provider']}'),
                      reference: '${r['pspRef'] ?? ''}',
                      cancelLabel: t.cancel,
                      onCancel: () => _cancel(r),
                    ),
                  ],
                ],
              ),
            ],
    );
  }

  /// Artboard 28: the two totals as stat cards, and the payouts themselves as a table.
  Widget _wide(AppLocalizations t) {
    return DesktopShell(
      current: DesktopNav.pending,
      sessionArgs: _sessionArgs,
      username: widget.username,
      title: t.pendingRedemptions,
      subtitle: t.pendingRedemptionsSubtitle,
      actions: [
        CircleIconButton(
          icon: KarataIcons.refresh,
          onPressed: _isLoading ? null : _load,
          semanticLabel: t.refresh,
        ),
      ],
      child: _isLoading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(
                child: CircularProgressIndicator(color: KarataColors.gold),
              ),
            )
          : _pending.isEmpty
          ? KarataCard(
              child: Text(
                t.noPendingRedemptions,
                textAlign: TextAlign.center,
                style: KarataText.subtitle,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 280,
                      child: SummaryCard(
                        lines: [
                          (
                            label: t.owedInTotal,
                            value: '${ChipDisplay.groupDigits(_owedAr)} Ar',
                            emphasised: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 200,
                      child: SummaryCard(
                        lines: [
                          (
                            label: t.requests,
                            value: '${_pending.length}',
                            emphasised: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                WidePendingTable(
                  columnLabels: [
                    t.columnAmount,
                    t.columnPhone,
                    t.columnProvider,
                    t.columnReference,
                  ],
                  cancelLabel: t.cancel,
                  rows: [
                    for (final r in _pending)
                      (
                        amount:
                            '${ChipDisplay.groupDigits((r['totalPriceAr'] as num?)?.toInt() ?? 0)} Ar',
                        phoneNumber: '${r['payoutPhoneNumber']}',
                        provider: _providerLabel('${r['provider']}'),
                        reference: '${r['pspRef'] ?? ''}',
                        onCancel: () => _cancel(r),
                      ),
                  ],
                ),
              ],
            ),
    );
  }

  /// The API's enum, in the spelling the operators themselves use.
  String _providerLabel(String provider) => switch (provider) {
    'MVOLA' => 'MVola',
    'ORANGE_MONEY' => 'Orange Money',
    _ => provider,
  };
}
