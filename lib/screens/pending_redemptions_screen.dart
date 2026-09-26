import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../chip_display.dart';
import '../l10n/app_localizations.dart';
import '../theme.dart';

/// Operator-only: what the dev still needs to manually go send via mobile money to close out a
/// redemption. Cancelling refunds the escrowed chips back to the player.
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
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                t.pendingRedemptions,
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w300,
                  color: KarataColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                t.pendingRedemptionsSubtitle,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: KarataColors.dim,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _pending.isEmpty
                    ? Center(
                        child: Text(
                          t.noPendingRedemptions,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: KarataColors.dim),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _pending.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1, color: Color(0xFF1A181E)),
                        itemBuilder: (context, index) {
                          final r = _pending[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.call_made_rounded,
                              color: KarataColors.chipInk,
                            ),
                            title: Text(
                              t.redeemTotalLine(
                                ChipDisplay.groupDigits(
                                  (r['totalPriceAr'] as num?)?.toInt() ?? 0,
                                ),
                              ),
                              style: const TextStyle(
                                color: KarataColors.ink,
                                fontSize: 16.5,
                              ),
                            ),
                            subtitle: Text(
                              '${r['payoutPhoneNumber']} - ${r['provider']} - ${r['pspRef']}',
                              style: const TextStyle(
                                color: KarataColors.dim,
                                fontSize: 12.5,
                              ),
                            ),
                            trailing: TextButton(
                              onPressed: () => _cancel(r),
                              child: Text(t.cancelRedemptionButton),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
