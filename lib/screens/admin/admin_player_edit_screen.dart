import 'package:flutter/material.dart';

import '../../api/api_client.dart';
import '../../chip_display.dart';
import '../../l10n/app_localizations.dart';
import '../../models/admin_player_detail.dart';
import '../../theme/karata_colors.dart';
import '../../theme/karata_text_styles.dart';
import '../../widgets/admin/admin_page.dart';
import '../../widgets/common/avatar.dart';
import '../../widgets/common/karata_button.dart';
import '../../widgets/common/karata_switch.dart';
import '../../widgets/common/karata_text_field.dart';
import '../../widgets/common/labeled_field.dart';
import '../../widgets/common/section_card.dart';
import '../../widgets/common/setting_row.dart';
import '../../widgets/desktop/desktop_sidebar.dart';

/// One account, with the two things an operator can actually change about it and the figures
/// that explain why they might.
class AdminPlayerEditScreen extends StatefulWidget {
  final String serverUrl;
  final String token;
  final String username;

  /// The account being edited, which is not [username] - that is whoever is signed in.
  final String subject;

  const AdminPlayerEditScreen({
    super.key,
    required this.serverUrl,
    required this.token,
    required this.username,
    required this.subject,
  });

  @override
  State<AdminPlayerEditScreen> createState() => _AdminPlayerEditScreenState();
}

class _AdminPlayerEditScreenState extends State<AdminPlayerEditScreen> {
  late final ApiClient _api;
  final _phone = TextEditingController();
  AdminPlayerDetail? _detail;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  bool _suspended = false;

  @override
  void initState() {
    super.initState();
    _api = ApiClient(baseUrl: widget.serverUrl, token: widget.token);
    _load();
    ChipDisplay.instance.refreshRateFromServer(_api);
  }

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _detail == null;
      _error = null;
    });
    try {
      final body = await _api.getAdminPlayer(widget.subject);
      if (!mounted) return;
      setState(() {
        _detail = AdminPlayerDetail.fromJson(body);
        _phone.text = _detail!.phoneNumber ?? '';
        _suspended = _detail!.player.suspended;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is ApiException ? e.message : '$e';
        _loading = false;
      });
    }
  }

  Map<String, dynamic> get _sessionArgs => {
    'serverUrl': widget.serverUrl,
    'token': widget.token,
    'username': widget.username,
  };

  Future<void> _apply(
    Future<Map<String, dynamic>> Function() call,
    String done,
  ) async {
    setState(() => _saving = true);
    try {
      final body = await call();
      if (!mounted) return;
      setState(() {
        _detail = AdminPlayerDetail.fromJson(body);
        _suspended = _detail!.player.suspended;
        _phone.text = _detail!.phoneNumber ?? '';
      });
      _say(done, KarataColors.green);
    } catch (e) {
      if (!mounted) return;
      // Put the switch back where the server says it is, so the screen never shows a suspension
      // that did not take.
      setState(() => _suspended = _detail?.player.suspended ?? false);
      _say(e is ApiException ? e.message : '$e', KarataColors.red);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _say(String message, Color colour) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message), backgroundColor: colour));

  Future<void> _save(AppLocalizations t) => _apply(
    () => _api.updateAdminPlayer(
      widget.subject,
      phoneNumber: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      suspended: _suspended,
    ),
    t.adminSaved(widget.subject),
  );

  Future<void> _resetBalance(AppLocalizations t) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        backgroundColor: KarataColors.surface,
        title: Text(t.adminResetBalance, style: KarataText.sectionTitle),
        content: Text(t.adminResetBalanceHint, style: KarataText.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: Text(t.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(true),
            child: Text(
              t.adminResetBalanceAction,
              style: karataText(
                size: 14,
                weight: 700,
                color: KarataColors.orangeLight,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _apply(
      () => _api.setAdminPlayerBalance(widget.subject, 0),
      t.adminSaved(widget.subject),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final detail = _detail;
    return ValueListenableBuilder<ChipDisplaySettings>(
      valueListenable: ChipDisplay.instance,
      builder: (context, chips, _) => AdminPage(
        nav: DesktopNav.adminPlayers,
        sessionArgs: _sessionArgs,
        username: widget.username,
        title: widget.subject,
        subtitle: t.adminEditPlayerSubtitle,
        loading: _loading,
        error: _error,
        onRetry: _load,
        children: detail == null
            ? const []
            : [
                _summary(detail, t, chips),
                SectionCard(
                  title: t.adminAccount,
                  children: [
                    LabeledField(
                      label: t.adminPaymentPhone,
                      child: KarataTextField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        fillColor: KarataColors.backdrop,
                        enabled: !_saving,
                      ),
                    ),
                    SettingRow(
                      title: t.adminSuspendAccount,
                      description: t.adminSuspendAccountHint,
                      trailing: KarataSwitch(
                        value: _suspended,
                        semanticLabel: t.adminSuspendAccount,
                        onChanged: _saving
                            ? null
                            : (v) => setState(() => _suspended = v),
                      ),
                    ),
                  ],
                ),
                SectionCard(
                  title: t.adminDangerZone,
                  children: [
                    SettingRow(
                      title: t.adminResetBalance,
                      description: detail.player.seated
                          ? t.adminCannotResetWhileSeated
                          : t.adminResetBalanceHint,
                      trailing: KarataButton(
                        label: t.adminResetBalanceAction,
                        style: KarataButtonStyle.danger,
                        height: 38,
                        fontSize: 13,
                        expand: false,
                        // The server refuses this while they are seated, and saying so before the
                        // tap is kinder than a snackbar after it.
                        onPressed: _saving || detail.player.seated
                            ? null
                            : () => _resetBalance(t),
                      ),
                    ),
                  ],
                ),
                KarataButton(
                  label: t.adminSaveChanges,
                  onPressed: _saving ? null : () => _save(t),
                ),
              ],
      ),
    );
  }

  Widget _summary(
    AdminPlayerDetail detail,
    AppLocalizations t,
    ChipDisplaySettings chips,
  ) {
    final joined = detail.player.joinedAt;
    return SectionCard(
      title: detail.player.username,
      trailingWidget: Avatar(name: detail.player.username, diameter: 36),
      children: [
        _fact(
          t.adminJoined,
          joined == null
              ? t.adminUnknownDate
              : MaterialLocalizations.of(
                  context,
                ).formatShortDate(joined.toLocal()),
        ),
        _fact(t.balance, ChipDisplay.formatWith(chips, detail.player.balance)),
        _fact(
          t.adminColumnAtTable,
          detail.player.atTableName ?? t.adminNotSeated,
        ),
        _fact(
          t.adminLifetimeDeposits,
          ChipDisplay.formatWith(chips, detail.lifetimeDeposited),
        ),
        _fact(
          t.adminLifetimeWithdrawals,
          ChipDisplay.formatWith(chips, detail.lifetimeWithdrawn),
        ),
      ],
    );
  }

  Widget _fact(String label, String value) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Flexible(
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: karataText(
            size: 13,
            weight: 500,
            color: KarataColors.inkMuted,
          ),
        ),
      ),
      const SizedBox(width: 12),
      Text(value, maxLines: 1, style: karataText(size: 15, weight: 800)),
    ],
  );
}
