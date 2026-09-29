import 'package:flutter/material.dart';

import '../../api/api_client.dart';
import '../../chip_display.dart';
import '../../l10n/app_localizations.dart';
import '../../models/admin_table.dart';
import '../../theme/karata_colors.dart';
import '../../theme/karata_text_styles.dart';
import '../../widgets/admin/admin_page.dart';
import '../../widgets/common/amount_field.dart';
import '../../widgets/common/avatar.dart';
import '../../widgets/common/dashed_ring.dart';
import '../../widgets/common/karata_button.dart';
import '../../widgets/common/karata_card.dart';
import '../../widgets/common/karata_switch.dart';
import '../../widgets/common/karata_text_field.dart';
import '../../widgets/common/labeled_field.dart';
import '../../widgets/common/section_card.dart';
import '../../widgets/common/setting_row.dart';
import '../../widgets/desktop/desktop_sidebar.dart';

/// One table, its terms, and the people sitting at it.
///
/// Pausing, resuming and closing a table are deliberately not offered here, even though the
/// backend endpoints exist: they check GameService.requireInitiator/requireCanClose with no
/// operator bypass, so an operator who is not the table's own host would get a 403 from every one
/// of them. The note this screen shows instead of those controls states that plainly.
class AdminTableEditScreen extends StatefulWidget {
  final String serverUrl;
  final String token;
  final String username;
  final String gameId;

  const AdminTableEditScreen({
    super.key,
    required this.serverUrl,
    required this.token,
    required this.username,
    required this.gameId,
  });

  @override
  State<AdminTableEditScreen> createState() => _AdminTableEditScreenState();
}

class _AdminTableEditScreenState extends State<AdminTableEditScreen> {
  late final ApiClient _api;
  final _name = TextEditingController();
  final _small = TextEditingController();
  final _big = TextEditingController();

  AdminTable? _table;
  List<({String name, int chips})> _seats = [];
  int _pot = 0;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  bool _isPublic = false;

  @override
  void initState() {
    super.initState();
    _api = ApiClient(baseUrl: widget.serverUrl, token: widget.token);
    _load();
    ChipDisplay.instance.refreshRateFromServer(_api);
  }

  @override
  void dispose() {
    for (final c in [_name, _small, _big]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _table == null;
      _error = null;
    });
    try {
      final tables = (await _api.listAdminTables())
          .map(AdminTable.fromJson)
          .toList();
      final table = tables.where((x) => x.gameId == widget.gameId).firstOrNull;
      if (table == null) {
        throw ApiException(code: 'NOT_FOUND', message: 'Table not found');
      }
      // Neither the seat list nor the pot is in the admin table payload: stacks and the pot both
      // belong to the game itself, which is why this one screen pays for a replay that the rest of
      // the admin surface deliberately avoids (see AdminTable's own doc comment).
      final game = await _api.getGame(widget.gameId);
      if (!mounted) return;
      final display = ChipDisplay.instance.value;
      final currentDeal = game['currentDeal'] as Map<String, dynamic>?;
      setState(() {
        _table = table;
        _seats = [
          for (final p in (game['players'] as List<dynamic>? ?? const []))
            (
              name: (p as Map<String, dynamic>)['username'] as String? ?? '',
              chips: (p['chips'] as num?)?.toInt() ?? 0,
            ),
        ];
        _pot = (currentDeal?['pot'] as num?)?.toInt() ?? 0;
        _name.text = table.name;
        _small.text = AmountField.entryText(display, table.smallBlind ?? 0);
        _big.text = AmountField.entryText(display, table.bigBlind ?? 0);
        _isPublic = table.isPublic;
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

  void _say(String message, Color colour) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message), backgroundColor: colour));

  Future<void> _run(Future<void> Function() call) async {
    setState(() => _saving = true);
    try {
      await call();
      if (!mounted) return;
      await _load();
    } catch (e) {
      if (!mounted) return;
      _say(e is ApiException ? e.message : '$e', KarataColors.red);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _save(AppLocalizations t) async {
    final display = ChipDisplay.instance.value;
    final small = AmountField.chipsFrom(display, _small.text);
    final big = AmountField.chipsFrom(display, _big.text);
    if (_name.text.trim().isEmpty || small == null || big == null) {
      _say(t.enterValidBuyIn, KarataColors.red);
      return;
    }
    await _run(() async {
      await _api.updateAdminTable(
        widget.gameId,
        name: _name.text.trim(),
        smallBlind: small,
        bigBlind: big,
        isPublic: _table!.belongsToRoom ? null : _isPublic,
      );
      if (mounted) _say(t.adminSaved(_name.text.trim()), KarataColors.green);
    });
  }

  Future<void> _remove(String username, AppLocalizations t) => _run(() async {
    await _api.removeAdminTablePlayer(widget.gameId, username);
    if (mounted) _say(t.adminRemovedFromTable(username), KarataColors.green);
  });

  // No strategy picker, unlike the host's own add-bot dialog on the table screen: this is a
  // one-button operator action, and a null strategy is already "let the server choose" there.
  Future<void> _addBot() => _run(() => _api.addBot(widget.gameId));

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final table = _table;
    return ValueListenableBuilder<ChipDisplaySettings>(
      valueListenable: ChipDisplay.instance,
      builder: (context, chips, _) => AdminPage(
        nav: DesktopNav.adminTables,
        sessionArgs: _sessionArgs,
        username: widget.username,
        title: table?.name ?? t.adminEditTable,
        subtitle: t.adminEditTableSubtitle,
        loading: _loading,
        error: _error,
        onRetry: _load,
        // The design's own ratio: the settings column carries more content than the roster does.
        leftFlex: 7,
        rightFlex: 5,
        wideRight: table == null
            ? const []
            : [
                _seatedPlayersCard(table, t, chips),
                _statsCard(table, t, chips),
              ],
        children: table == null
            ? const []
            : [
                _tableCard(table, t, chips),
                if (table.isPublic) _botsCard(t),
                _noOperatorRouteNote(t),
                KarataButton(
                  label: t.adminSaveChanges,
                  onPressed: _saving ? null : () => _save(t),
                ),
              ],
      ),
    );
  }

  Widget _tableCard(
    AdminTable table,
    AppLocalizations t,
    ChipDisplaySettings chips,
  ) {
    return SectionCard(
      ribbon: true,
      title: t.adminTableSection,
      children: [
        LabeledField(
          label: t.name,
          child: KarataTextField(
            controller: _name,
            fillColor: KarataColors.backdrop,
            enabled: !_saving,
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
        SettingRow(
          title: t.adminTableIsPublic,
          // A room's table is not the operator's to publish - it is reached by sitting down in
          // the room, and the server refuses the change anyway.
          description: table.belongsToRoom
              ? t.adminRoomTableCannotBePublic
              : t.adminTableIsPublicHint,
          trailing: KarataSwitch(
            value: _isPublic,
            semanticLabel: t.adminTableIsPublic,
            onChanged: _saving || table.belongsToRoom
                ? null
                : (v) => setState(() => _isPublic = v),
          ),
        ),
      ],
    );
  }

  Widget _botsCard(AppLocalizations t) {
    return SectionCard(
      title: t.adminBotsSection,
      children: [
        SettingRow(
          title: t.addBot,
          description: t.adminAddBotHint,
          trailing: KarataButton(
            label: t.adminAddBotButton,
            style: KarataButtonStyle.surface,
            height: 36,
            fontSize: 13,
            expand: false,
            horizontalPadding: 16,
            onPressed: _saving ? null : _addBot,
          ),
        ),
      ],
    );
  }

  Widget _noOperatorRouteNote(AppLocalizations t) => KarataCard(
    child: Text(
      t.adminNoOperatorRouteNote,
      style: karataText(
        size: 13,
        weight: 500,
        color: KarataColors.inkMuted,
        height: 1.5,
      ),
    ),
  );

  Widget _seatedPlayersCard(
    AdminTable table,
    AppLocalizations t,
    ChipDisplaySettings chips,
  ) {
    final openSeats = (table.capacity - _seats.length).clamp(0, table.capacity);
    return SectionCard(
      title: t.adminSeatedPlayers,
      children: [
        for (final seat in _seats) _seatRow(seat, t, chips),
        for (var i = 0; i < openSeats; i++) _openSeatRow(t),
      ],
    );
  }

  Widget _statsCard(
    AdminTable table,
    AppLocalizations t,
    ChipDisplaySettings chips,
  ) {
    return KarataCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _statRow(
            t.adminPotSize,
            ChipDisplay.formatWith(chips, _pot),
            valueStyle: karataText(
              size: 22,
              weight: 800,
              color: KarataColors.gold,
            ),
          ),
          const SizedBox(height: 8),
          _statRow(
            t.adminColumnBuyIn,
            ChipDisplay.formatWith(chips, table.defaultBuyIn ?? 0),
          ),
          const SizedBox(height: 8),
          _statRow(t.adminColumnSeated, '${table.seated} / ${table.capacity}'),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value, {TextStyle? valueStyle}) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Text(
        label,
        style: karataText(size: 14, weight: 500, color: KarataColors.inkMuted),
      ),
      Text(value, style: valueStyle ?? karataText(size: 15, weight: 800)),
    ],
  );

  Widget _seatRow(
    ({String name, int chips}) seat,
    AppLocalizations t,
    ChipDisplaySettings chips,
  ) {
    return Row(
      children: [
        Avatar(name: seat.name, diameter: 30),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            seat.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: karataText(size: 15, weight: 700),
          ),
        ),
        Text(
          ChipDisplay.formatWith(chips, seat.chips),
          maxLines: 1,
          style: karataText(size: 14, weight: 800),
        ),
        const SizedBox(width: 12),
        KarataButton(
          label: t.adminRemove,
          style: KarataButtonStyle.danger,
          height: 34,
          fontSize: 13,
          expand: false,
          horizontalPadding: 14,
          onPressed: _saving ? null : () => _remove(seat.name, t),
        ),
      ],
    );
  }

  Widget _openSeatRow(AppLocalizations t) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        const DashedRing(
          diameter: 32,
          color: KarataColors.lineStrong,
          strokeWidth: 2,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            t.adminOpenSeat,
            style: karataText(
              size: 14,
              weight: 600,
              color: KarataColors.inkFaint,
            ),
          ),
        ),
      ],
    ),
  );
}
