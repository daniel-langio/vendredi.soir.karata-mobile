import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../chip_display.dart';
import '../l10n/app_localizations.dart';
import '../table_name_generator.dart';
import '../theme/karata_colors.dart';
import '../theme/karata_text_styles.dart';
import '../widgets/common/amount_field.dart';
import '../widgets/common/choice_chips_row.dart';
import '../widgets/common/circle_icon_button.dart';
import '../widgets/common/karata_button.dart';
import '../widgets/common/karata_card.dart';
import '../widgets/common/karata_dropdown.dart';
import '../widgets/common/karata_icons.dart';
import '../widgets/common/karata_screen.dart';
import '../widgets/common/karata_switch.dart';
import '../widgets/common/karata_text_field.dart';
import '../widgets/common/labeled_field.dart';
import '../widgets/common/section_card.dart';
import '../widgets/common/setting_row.dart';

class NewTableScreen extends StatefulWidget {
  final String serverUrl;
  final String token;
  final String username;

  const NewTableScreen({
    super.key,
    required this.serverUrl,
    required this.token,
    required this.username,
  });

  @override
  State<NewTableScreen> createState() => _NewTableScreenState();
}

class _NewTableScreenState extends State<NewTableScreen> {
  final _nameController = TextEditingController(text: generateTableName());
  // Blinds and buy-in are asked for in whatever unit the player reads the rest of the app in, so
  // the defaults are seeded through the same conversion the entries are read back with.
  final _display = ChipDisplay.instance.value;
  late final _smallBlindController = TextEditingController(
    text: AmountField.entryText(_display, 1),
  );
  late final _bigBlindController = TextEditingController(
    text: AmountField.entryText(_display, 2),
  );
  late final _buyInController = TextEditingController(
    text: AmountField.entryText(_display, 200),
  );
  String _variant = 'TEXAS_HOLDEM';
  bool _isLoading = false;
  bool _isOperator = false;
  bool _makePublic = false;
  bool _cashoutEnabled = true;
  bool _enforceMinimumBuyIn = true;
  bool _autoRebuyEnabled = false;
  int? _walletChips;

  /// The multiples of the big blind the design offers as one-tap buy-ins.
  static const _presetBigBlinds = [50, 100, 200];

  @override
  void initState() {
    super.initState();
    _checkOperator();
    _loadWallet();
  }

  /// Whether to offer the public-table switch is the server's answer, not a username the client
  /// recognises - a player who flipped it anyway would just be refused by POST /games/public.
  Future<void> _checkOperator() async {
    try {
      final isOperator = await ApiClient(
        baseUrl: widget.serverUrl,
        token: widget.token,
      ).isOperator();
      if (!mounted) return;
      setState(() => _isOperator = isOperator);
    } catch (_) {
      // Non-critical - the switch just stays hidden if we can't reach the server.
    }
  }

  /// The balance behind the "Max" preset and the line under the buy-in field.
  Future<void> _loadWallet() async {
    try {
      final chips = await ApiClient(
        baseUrl: widget.serverUrl,
        token: widget.token,
      ).getWallet();
      if (!mounted) return;
      setState(() => _walletChips = chips);
    } catch (_) {
      // Non-critical - "Max" is simply left out if we can't reach the server.
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _smallBlindController.dispose();
    _bigBlindController.dispose();
    _buyInController.dispose();
    super.dispose();
  }

  /// Reads one amount field as chips. Null (rather than zero) for anything unparseable, so the
  /// "fill in valid values" guard below still catches an empty or junk entry.
  int? _chipsFrom(TextEditingController controller) {
    final entered = int.tryParse(
      controller.text.trim().replaceAll(RegExp(r'[\s ]'), ''),
    );
    return entered == null ? null : _display.chipsFromEntry(entered);
  }

  int? get _bigBlindChips {
    final bb = _chipsFrom(_bigBlindController);
    return bb == null || bb <= 0 ? null : bb;
  }

  /// Which preset, if any, the buy-in currently sits on - so the chips reflect a value the player
  /// typed by hand as well as one they tapped.
  int? get _selectedPreset {
    final bb = _bigBlindChips;
    final buyIn = _chipsFrom(_buyInController);
    if (bb == null || buyIn == null) return null;
    for (var i = 0; i < _presetBigBlinds.length; i++) {
      if (buyIn == bb * _presetBigBlinds[i]) return i;
    }
    if (_walletChips != null && buyIn == _walletChips) {
      return _presetBigBlinds.length;
    }
    return null;
  }

  void _applyPreset(int index) {
    final chips = index < _presetBigBlinds.length
        ? (_bigBlindChips ?? 0) * _presetBigBlinds[index]
        : (_walletChips ?? 0);
    if (chips <= 0) return;
    setState(() {
      _buyInController.text = AmountField.entryText(_display, chips);
    });
  }

  Future<void> _create() async {
    final name = _nameController.text.trim();
    // The API only ever speaks chips, whatever unit the fields were filled in.
    final sb = _chipsFrom(_smallBlindController);
    final bb = _chipsFrom(_bigBlindController);
    final buyIn = _chipsFrom(_buyInController);

    if (name.isEmpty ||
        sb == null ||
        sb <= 0 ||
        bb == null ||
        bb <= 0 ||
        buyIn == null ||
        buyIn <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).fillValidValues),
          backgroundColor: KarataColors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final client = ApiClient(baseUrl: widget.serverUrl, token: widget.token);
      final publicTable = _isOperator && _makePublic;
      final game = publicTable
          ? await client.createPublicGame(
              name,
              sb,
              bb,
              defaultBuyIn: buyIn,
              variant: _variant,
              cashoutEnabled: _cashoutEnabled,
              enforceMinimumBuyIn: _enforceMinimumBuyIn,
              autoRebuyEnabled: _autoRebuyEnabled,
            )
          : await client.createGame(
              name,
              sb,
              bb,
              defaultBuyIn: buyIn,
              variant: _variant,
            );
      final gameId = game['gameId'] as String;
      // A public table is the house's and the operator is not one of its players, so the buy-in
      // here is the tier everyone else will pay rather than a seat being taken.
      if (!publicTable) {
        await client.buyIn(gameId, buyIn);
      }
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(
          '/table/$gameId',
          arguments: {
            'serverUrl': widget.serverUrl,
            'token': widget.token,
            'username': widget.username,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).couldNotCreateTable('$e'),
            ),
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

    return KarataScreen(
      onBack: () => Navigator.of(context).pop(),
      backLabel: t.back,
      title: t.newTableTitle,
      subtitle: t.newTableSubtitle,
      children: [
        SectionCard(
          title: t.table,
          ribbon: true,
          children: [
            LabeledField(
              label: t.name,
              child: KarataTextField(
                controller: _nameController,
                fillColor: KarataColors.backdrop,
                trailing: CircleIconButton(
                  icon: KarataIcons.shuffle,
                  iconSize: 20,
                  background: const Color(0x00000000),
                  color: KarataColors.inkMuted,
                  onPressed: () => setState(
                    () => _nameController.text = generateTableName(),
                  ),
                  semanticLabel: t.generateTableName,
                ),
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
                  (
                    'SEVEN_CARD_STUD',
                    '${t.variantSevenCardStudShort} (${t.comingSoon})',
                  ),
                ],
                // SEVEN_CARD_STUD is listed but not playable yet - DropdownMenuItem has no
                // per-item `enabled` flag, so this rejects the pick and leaves _variant as-is.
                onChanged: (value) {
                  if (value == 'SEVEN_CARD_STUD') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${t.variantSevenCardStudShort} - ${t.comingSoon}',
                        ),
                      ),
                    );
                    return;
                  }
                  setState(() => _variant = value ?? _variant);
                },
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: LabeledField(
                    label: t.smallBlind,
                    child: AmountField(
                      controller: _smallBlindController,
                      display: _display,
                      fillColor: KarataColors.backdrop,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: LabeledField(
                    label: t.bigBlind,
                    child: AmountField(
                      controller: _bigBlindController,
                      display: _display,
                      fillColor: KarataColors.backdrop,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        SectionCard(
          title: t.yourBuyIn,
          children: [
            LabeledField(
              label: t.amount,
              child: AmountField(
                controller: _buyInController,
                display: _display,
                fillColor: KarataColors.backdrop,
                onChanged: (_) => setState(() {}),
              ),
            ),
            ChoiceChipsRow(
              labels: [
                for (final bb in _presetBigBlinds) t.bigBlindsPreset('$bb'),
                t.maxPreset,
              ],
              selectedIndex: _selectedPreset,
              onSelected: _applyPreset,
            ),
            Text(_buyInSummary(t), style: KarataText.label),
          ],
        ),
        if (_isOperator)
          KarataCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SettingRow(
                  title: t.makePublic,
                  description: t.makePublicHint,
                  trailing: KarataSwitch(
                    value: _makePublic,
                    semanticLabel: t.makePublic,
                    onChanged: _isLoading
                        ? null
                        : (value) => setState(() => _makePublic = value),
                  ),
                ),
                if (_makePublic) ...[
                  const SizedBox(height: 16),
                  const CardDivider(),
                  const SizedBox(height: 16),
                  SettingRow(
                    title: t.virtualChips,
                    description: t.virtualChipsHint,
                    trailing: KarataSwitch(
                      value: !_cashoutEnabled,
                      semanticLabel: t.virtualChips,
                      onChanged: _isLoading
                          ? null
                          : (value) => setState(() => _cashoutEnabled = !value),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SettingRow(
                    title: t.strictMinimumBuyIn,
                    description: t.strictMinimumBuyInHint,
                    trailing: KarataSwitch(
                      value: _enforceMinimumBuyIn,
                      semanticLabel: t.strictMinimumBuyIn,
                      onChanged: _isLoading
                          ? null
                          : (value) =>
                                setState(() => _enforceMinimumBuyIn = value),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SettingRow(
                    title: t.autoRebuy,
                    description: t.autoRebuyHint,
                    trailing: KarataSwitch(
                      value: _autoRebuyEnabled,
                      semanticLabel: t.autoRebuy,
                      onChanged: _isLoading
                          ? null
                          : (value) =>
                                setState(() => _autoRebuyEnabled = value),
                    ),
                  ),
                ],
              ],
            ),
          ),
        Text(t.newTableFooter, style: KarataText.subtitle),
        KarataButton(
          label: _isOperator && _makePublic
              ? t.createTable
              : t.createAndSitDown,
          onPressed: _isLoading ? null : _create,
        ),
      ],
    );
  }

  /// "That's 100 big blinds. Balance: 2 450 000 Ar" - both halves are only shown once they can be
  /// stated truthfully, so an unparseable blind or an unreachable server drops its half rather
  /// than printing a zero.
  String _buyInSummary(AppLocalizations t) {
    final bb = _bigBlindChips;
    final buyIn = _chipsFrom(_buyInController);
    final parts = <String>[
      if (bb != null && buyIn != null && buyIn > 0)
        t.thatsNBigBlinds('${(buyIn / bb).floor()}'),
      if (_walletChips != null)
        t.balanceOf(ChipDisplay.formatWith(_display, _walletChips)),
    ];
    return parts.join(' ');
  }
}
