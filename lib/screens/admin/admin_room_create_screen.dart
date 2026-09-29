import 'package:flutter/material.dart';

import '../../api/api_client.dart';
import '../../chip_display.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/karata_colors.dart';
import '../../widgets/admin/admin_page.dart';
import '../../widgets/common/amount_field.dart';
import '../../widgets/common/karata_button.dart';
import '../../widgets/common/karata_dropdown.dart';
import '../../widgets/common/karata_switch.dart';
import '../../widgets/common/karata_text_field.dart';
import '../../widgets/common/labeled_field.dart';
import '../../widgets/common/note_well.dart';
import '../../widgets/common/section_card.dart';
import '../../widgets/common/setting_row.dart';
import '../../widgets/desktop/desktop_sidebar.dart';

/// Opening a new stake tier.
///
/// Carries every table setting a room can be stamped from except its table cap: that one is a
/// thing you reach for once a room is running and misbehaving, not a decision to guess at before
/// anyone has sat down. It takes the server's default here and can be changed afterwards.
///
/// Not offered here at all: making the table public. That switch belongs to a single table (see
/// NewTableScreen), not to a room - a room is a stake tier players sit down at directly, and is
/// never itself listed as a public table.
class AdminRoomCreateScreen extends StatefulWidget {
  final String serverUrl;
  final String token;
  final String username;

  const AdminRoomCreateScreen({
    super.key,
    required this.serverUrl,
    required this.token,
    required this.username,
  });

  @override
  State<AdminRoomCreateScreen> createState() => _AdminRoomCreateScreenState();
}

class _AdminRoomCreateScreenState extends State<AdminRoomCreateScreen> {
  late final ApiClient _api;
  final _name = TextEditingController();
  final _small = TextEditingController();
  final _big = TextEditingController();
  final _buyIn = TextEditingController();

  String _variant = 'TEXAS_HOLDEM';
  bool _cashout = true;
  bool _enforceMinimumBuyIn = true;
  bool _autoRebuyEnabled = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _api = ApiClient(baseUrl: widget.serverUrl, token: widget.token);
    ChipDisplay.instance.refreshRateFromServer(_api);
  }

  @override
  void dispose() {
    for (final c in [_name, _small, _big, _buyIn]) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, dynamic> get _sessionArgs => {
    'serverUrl': widget.serverUrl,
    'token': widget.token,
    'username': widget.username,
  };

  void _say(String message, Color colour) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message), backgroundColor: colour));

  Future<void> _create(AppLocalizations t) async {
    final display = ChipDisplay.instance.value;
    final small = AmountField.chipsFrom(display, _small.text);
    final big = AmountField.chipsFrom(display, _big.text);
    final buyIn = AmountField.chipsFrom(display, _buyIn.text);
    final name = _name.text.trim();
    // The same checks the server makes, so the common mistakes are caught without a round trip -
    // the server still has the final say on all of them.
    if (name.isEmpty || small == null || big == null || buyIn == null) {
      _say(t.enterValidBuyIn, KarataColors.red);
      return;
    }
    if (small <= 0 || big <= 0 || big < small || buyIn <= 0) {
      _say(t.adminInvalidStakes, KarataColors.red);
      return;
    }

    setState(() => _saving = true);
    try {
      await _api.saveRoom(
        name: name,
        smallBlind: small,
        bigBlind: big,
        defaultBuyIn: buyIn,
        variant: _variant,
        cashoutEnabled: _cashout,
        enforceMinimumBuyIn: _enforceMinimumBuyIn,
        autoRebuyEnabled: _autoRebuyEnabled,
        // The one setting this form does not ask for. Sent explicitly because this is a PUT-shaped
        // body where an omission is a default rather than "unchanged" - null is the server's own
        // "no cap", not a stand-in for a value the form left out.
        maxTables: null,
      );
      if (!mounted) return;
      _say(t.adminSaved(name), KarataColors.green);
      Navigator.of(context).pop();
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
    return ValueListenableBuilder<ChipDisplaySettings>(
      valueListenable: ChipDisplay.instance,
      builder: (context, chips, _) => AdminPage(
        nav: DesktopNav.adminRooms,
        sessionArgs: _sessionArgs,
        username: widget.username,
        title: t.adminNewRoom,
        subtitle: t.adminNewRoomSubtitle,
        loading: false,
        error: null,
        onRetry: () {},
        children: [
          SectionCard(
            title: t.adminRoomSection,
            children: [
              LabeledField(
                label: t.name,
                child: KarataTextField(
                  controller: _name,
                  fillColor: KarataColors.backdrop,
                  enabled: !_saving,
                  autofocus: true,
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
              SettingRow(
                title: t.strictMinimumBuyIn,
                description: t.strictMinimumBuyInHint,
                trailing: KarataSwitch(
                  value: _enforceMinimumBuyIn,
                  semanticLabel: t.strictMinimumBuyIn,
                  onChanged: _saving
                      ? null
                      : (v) => setState(() => _enforceMinimumBuyIn = v),
                ),
              ),
              SettingRow(
                title: t.autoRebuy,
                description: t.autoRebuyHint,
                trailing: KarataSwitch(
                  value: _autoRebuyEnabled,
                  semanticLabel: t.autoRebuy,
                  onChanged: _saving
                      ? null
                      : (v) => setState(() => _autoRebuyEnabled = v),
                ),
              ),
              NoteWell(text: t.adminNewRoomNote),
            ],
          ),
          KarataButton(
            label: t.adminCreateRoom,
            onPressed: _saving ? null : () => _create(t),
          ),
        ],
      ),
    );
  }
}
