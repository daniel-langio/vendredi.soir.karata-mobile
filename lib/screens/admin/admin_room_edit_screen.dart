import 'package:flutter/material.dart';

import '../../api/api_client.dart';
import '../../chip_display.dart';
import '../../l10n/app_localizations.dart';
import '../../models/admin_room.dart';
import '../../theme/karata_colors.dart';
import '../../theme/karata_text_styles.dart';
import '../../widgets/admin/admin_page.dart';
import '../../widgets/common/amount_field.dart';
import '../../widgets/common/karata_button.dart';
import '../../widgets/common/karata_card.dart';
import '../../widgets/common/karata_dropdown.dart';
import '../../widgets/common/karata_switch.dart';
import '../../widgets/common/karata_tag.dart';
import '../../widgets/common/karata_text_field.dart';
import '../../widgets/common/labeled_field.dart';
import '../../widgets/common/note_well.dart';
import '../../widgets/common/section_card.dart';
import '../../widgets/common/setting_row.dart';
import '../../widgets/desktop/desktop_sidebar.dart';

/// One stake tier's configuration, plus the tables it currently has running.
///
/// The tables are listed from the room's own stats endpoint, which is built not to rebuild any
/// game state - so opening this screen costs a count, not a replay.
class AdminRoomEditScreen extends StatefulWidget {
  final String serverUrl;
  final String token;
  final String username;
  final String roomId;

  const AdminRoomEditScreen({
    super.key,
    required this.serverUrl,
    required this.token,
    required this.username,
    required this.roomId,
  });

  @override
  State<AdminRoomEditScreen> createState() => _AdminRoomEditScreenState();
}

class _AdminRoomEditScreenState extends State<AdminRoomEditScreen> {
  late final ApiClient _api;
  final _name = TextEditingController();
  final _small = TextEditingController();
  final _big = TextEditingController();
  final _buyIn = TextEditingController();

  AdminRoom? _room;
  List<AdminRoom> _all = [];
  Map<String, dynamic>? _stats;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String _variant = 'TEXAS_HOLDEM';
  bool _cashout = true;

  @override
  void initState() {
    super.initState();
    _api = ApiClient(baseUrl: widget.serverUrl, token: widget.token);
    _load();
    ChipDisplay.instance.refreshRateFromServer(_api);
  }

  @override
  void dispose() {
    for (final c in [_name, _small, _big, _buyIn]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _room == null;
      _error = null;
    });
    try {
      final rooms = (await _api.listAdminRooms())
          .map(AdminRoom.fromJson)
          .toList();
      final room = rooms
          .where((r) => r.room.roomId == widget.roomId)
          .firstOrNull;
      if (room == null) {
        throw ApiException(code: 'NOT_FOUND', message: 'Room not found');
      }
      // A closed room has no live tables worth listing, and the stats call is the operator's
      // per-table view rather than something the form needs - so a failure here leaves the form
      // usable instead of taking the screen down.
      Map<String, dynamic>? stats;
      try {
        stats = await _api.getRoomStats(widget.roomId);
      } catch (_) {
        stats = null;
      }
      if (!mounted) return;
      setState(() {
        _all = rooms;
        _room = room;
        _stats = stats;
        _fill(room);
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

  void _fill(AdminRoom entry) {
    final display = ChipDisplay.instance.value;
    _name.text = entry.room.name;
    _small.text = AmountField.entryText(display, entry.room.smallBlind);
    _big.text = AmountField.entryText(display, entry.room.bigBlind);
    _buyIn.text = AmountField.entryText(display, entry.room.defaultBuyIn);
    _variant = entry.room.variant;
    _cashout = entry.room.cashoutEnabled;
  }

  Map<String, dynamic> get _sessionArgs => {
    'serverUrl': widget.serverUrl,
    'token': widget.token,
    'username': widget.username,
  };

  void _say(String message, Color colour) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message), backgroundColor: colour));

  Future<void> _save(AppLocalizations t) async {
    final entry = _room!;
    final display = ChipDisplay.instance.value;
    final small = AmountField.chipsFrom(display, _small.text);
    final big = AmountField.chipsFrom(display, _big.text);
    final buyIn = AmountField.chipsFrom(display, _buyIn.text);
    if (_name.text.trim().isEmpty ||
        small == null ||
        big == null ||
        buyIn == null) {
      _say(t.enterValidBuyIn, KarataColors.red);
      return;
    }

    setState(() => _saving = true);
    try {
      // A PUT, so every field goes - including the three this form does not show, which would
      // otherwise silently fall back to their defaults and change the room behind the operator.
      await _api.saveRoom(
        roomId: widget.roomId,
        name: _name.text.trim(),
        smallBlind: small,
        bigBlind: big,
        defaultBuyIn: buyIn,
        variant: _variant,
        cashoutEnabled: _cashout,
        enforceMinimumBuyIn: entry.room.enforceMinimumBuyIn,
        autoRebuyEnabled: entry.room.autoRebuyEnabled,
        maxTables: entry.room.maxTables,
      );
      if (!mounted) return;
      _say(t.adminSaved(_name.text.trim()), KarataColors.green);
      await _load();
    } catch (e) {
      if (!mounted) return;
      _say(e is ApiException ? e.message : '$e', KarataColors.red);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _toggleClosed(AppLocalizations t) async {
    final entry = _room!;
    setState(() => _saving = true);
    try {
      if (entry.closed) {
        await _api.reopenRoom(widget.roomId);
      } else {
        await _api.closeRoom(widget.roomId);
      }
      if (!mounted) return;
      await _load();
    } catch (e) {
      if (!mounted) return;
      _say(e is ApiException ? e.message : '$e', KarataColors.red);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final entry = _room;
    return ValueListenableBuilder<ChipDisplaySettings>(
      valueListenable: ChipDisplay.instance,
      builder: (context, chips, _) => AdminPage(
        nav: DesktopNav.adminRooms,
        sessionArgs: _sessionArgs,
        username: widget.username,
        title: entry?.room.name ?? t.adminEditRoom,
        subtitle: t.adminEditRoomSubtitle,
        loading: _loading,
        error: _error,
        onRetry: _load,
        children: entry == null
            ? const []
            : [
                _facts(entry, t),
                SectionCard(
                  title: t.adminRoomSection,
                  children: [
                    LabeledField(
                      label: t.name,
                      child: KarataTextField(
                        controller: _name,
                        fillColor: KarataColors.backdrop,
                        enabled: !_saving,
                      ),
                    ),
                    LabeledField(
                      label: t.gameVariant,
                      child: KarataDropdown<String>(
                        value: _variant,
                        items: [
                          ('TEXAS_HOLDEM', t.variantTexasHoldemShort),
                          ('OMAHA', t.variantOmahaShort),
                          ('FIVE_CARD_DRAW', t.variantFiveCardDrawShort),
                        ],
                        onChanged: _saving
                            ? null
                            : (v) => setState(() => _variant = v ?? _variant),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: LabeledField(
                            label: t.smallBlind,
                            child: AmountField(
                              controller: _small,
                              display: chips,
                              fillColor: KarataColors.backdrop,
                              enabled: !_saving,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: LabeledField(
                            label: t.bigBlind,
                            child: AmountField(
                              controller: _big,
                              display: chips,
                              fillColor: KarataColors.backdrop,
                              enabled: !_saving,
                            ),
                          ),
                        ),
                      ],
                    ),
                    LabeledField(
                      label: t.roomDefaultBuyIn,
                      child: AmountField(
                        controller: _buyIn,
                        display: chips,
                        fillColor: KarataColors.backdrop,
                        enabled: !_saving,
                      ),
                    ),
                    SettingRow(
                      title: t.adminCashoutEnabled,
                      description: t.adminCashoutEnabledHint,
                      trailing: KarataSwitch(
                        value: _cashout,
                        semanticLabel: t.adminCashoutEnabled,
                        onChanged: _saving
                            ? null
                            : (v) => setState(() => _cashout = v),
                      ),
                    ),
                    NoteWell(text: t.adminEditsReachNewTablesOnly),
                  ],
                ),
                if (_liveTables.isNotEmpty)
                  SectionCard(
                    title: t.adminTablesInThisRoom,
                    children: [
                      for (final table in _liveTables) _tableRow(table, t),
                    ],
                  ),
                SectionCard(
                  title: t.adminDangerZone,
                  children: [
                    SettingRow(
                      title: t.adminDisableRoom,
                      description: t.adminDisableRoomHint,
                      trailing: KarataButton(
                        label: entry.closed
                            ? t.adminEnableRoomAction
                            : t.adminDisableRoomAction,
                        style: entry.closed
                            ? KarataButtonStyle.surface
                            : KarataButtonStyle.danger,
                        height: 38,
                        fontSize: 13,
                        expand: false,
                        onPressed: _saving ? null : () => _toggleClosed(t),
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

  /// The room's tables, spare included so the operator can see the seat that is being held open.
  List<Map<String, dynamic>> get _liveTables =>
      ((_stats?['tables'] as List<dynamic>?) ?? const [])
          .cast<Map<String, dynamic>>();

  Widget _tableRow(Map<String, dynamic> table, AppLocalizations t) {
    final seated = (table['seated'] as num?)?.toInt() ?? 0;
    final free = (table['freeSeats'] as num?)?.toInt() ?? 0;
    final spare = table['spare'] == true;
    final gameId = table['gameId'] as String?;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                table['name'] as String? ?? '—',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: karataText(size: 15, weight: 700),
              ),
              const SizedBox(height: 2),
              Text(
                t.adminSeatedOf('$seated', '${seated + free}'),
                maxLines: 1,
                style: karataText(
                  size: 12,
                  weight: 600,
                  color: KarataColors.inkFaint,
                ),
              ),
            ],
          ),
        ),
        KarataTag(
          label: spare ? t.adminSpare : t.adminLive,
          tone: spare ? KarataTagTone.seated : KarataTagTone.cashout,
        ),
        const SizedBox(width: 10),
        KarataButton(
          label: t.adminEditTable,
          style: KarataButtonStyle.surface,
          height: 36,
          fontSize: 13,
          expand: false,
          horizontalPadding: 14,
          onPressed: gameId == null
              ? null
              : () => Navigator.of(context)
                    .pushNamed('/admin/tables/$gameId', arguments: _sessionArgs)
                    .then((_) => _load()),
        ),
      ],
    );
  }

  Widget _facts(AdminRoom entry, AppLocalizations t) {
    final rank = _all.indexWhere((r) => r.room.roomId == entry.room.roomId) + 1;
    return KarataCard(
      child: Row(
        children: [
          Expanded(
            child: _fact(t.adminTablesRunning, '${entry.room.tableCount}'),
          ),
          Expanded(
            child: _fact(t.adminPlayersSeated, '${entry.room.playerCount}'),
          ),
          Expanded(
            child: _fact(t.adminOrderedByBuyIn, '#$rank / ${_all.length}'),
          ),
        ],
      ),
    );
  }

  Widget _fact(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: karataText(size: 13, weight: 600, color: KarataColors.gold),
      ),
      const SizedBox(height: 2),
      Text(value, maxLines: 1, style: karataText(size: 22, weight: 800)),
    ],
  );
}
