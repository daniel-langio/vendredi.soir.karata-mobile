import 'package:flutter/material.dart';

import '../../chip_display.dart';
import '../../l10n/app_localizations.dart';
import '../../models/room_summary.dart';
import '../../theme/karata_colors.dart';
import '../../theme/karata_text_styles.dart';
import '../common/amount_field.dart';
import '../common/choice_chips_row.dart';
import '../common/dashed_border.dart';
import '../common/karata_button.dart';
import '../common/labeled_field.dart';
import '../common/karata_tag.dart';

/// What the player decided in the buy-in sheet.
sealed class RoomSitChoice {
  const RoomSitChoice();
}

/// Sit down, buying in for [chips].
class SitDownFor extends RoomSitChoice {
  const SitDownFor(this.chips);
  final int chips;
}

/// Go and top the balance up first; nothing has been bought in.
class AddChipsFirst extends RoomSitChoice {
  const AddChipsFirst();
}

/// The sheet between tapping "Sit down" and actually being seated.
///
/// It exists because the buy-in is the one decision the player still has - the table they land at
/// is the server's to pick - and because a balance too small for the room has to be said here
/// rather than discovered as a rejected request.
///
/// Returns null if the sheet is dismissed without choosing.
Future<RoomSitChoice?> showRoomSitSheet(
  BuildContext context, {
  required RoomSummary room,
  required int? balanceChips,
}) {
  return showModalBottomSheet<RoomSitChoice>(
    context: context,
    backgroundColor: KarataColors.surface,
    // The buy-in field summons the keyboard, which would otherwise cover the button under it.
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (sheetContext) =>
        _RoomSitSheet(room: room, balanceChips: balanceChips),
  );
}

class _RoomSitSheet extends StatefulWidget {
  const _RoomSitSheet({required this.room, required this.balanceChips});

  final RoomSummary room;

  /// Null when the wallet could not be read - the sheet then trusts the player over its own
  /// missing figure and lets them try, rather than barring them on a number it does not have.
  final int? balanceChips;

  @override
  State<_RoomSitSheet> createState() => _RoomSitSheetState();
}

class _RoomSitSheetState extends State<_RoomSitSheet> {
  late final TextEditingController _amount;
  late ChipDisplaySettings _display;

  @override
  void initState() {
    super.initState();
    _display = ChipDisplay.instance.value;
    _amount = TextEditingController(
      text: AmountField.entryText(_display, widget.room.defaultBuyIn),
    );
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  /// Whether the room expects the player to already own the chips they sit down with. A
  /// play-chips room and an auto-rebuy room both hand out their own stake for free server-side
  /// (see `GameService.joinGame`/`applyAutoRebuys`), so neither has anything to check the wallet
  /// for - the wallet only matters where cashing out makes the buy-in real money leaving it.
  bool get _walletRequired =>
      widget.room.cashoutEnabled && !widget.room.autoRebuyEnabled;

  /// The most the player could put on the table, which is simply what they hold: the API caps a
  /// buy-in from below, never from above. A room that does not draw the buy-in from the wallet
  /// has nothing to cap against, so it falls back to its own default the same way a missing
  /// wallet reading already does.
  int get _maxChips =>
      _walletRequired
          ? widget.balanceChips ?? widget.room.defaultBuyIn
          : widget.room.defaultBuyIn;

  int? get _entered => AmountField.chipsFrom(_display, _amount.text);

  bool get _cannotAfford =>
      _walletRequired &&
      widget.balanceChips != null &&
      widget.balanceChips! < widget.room.minimumBuyIn;

  bool get _isValid {
    final chips = _entered;
    if (chips == null) return false;
    if (!_walletRequired) return chips >= widget.room.minimumBuyIn;
    return chips >= widget.room.minimumBuyIn && chips <= _maxChips;
  }

  void _setChips(int chips) {
    _amount.text = AmountField.entryText(_display, chips);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return ValueListenableBuilder<ChipDisplaySettings>(
      valueListenable: ChipDisplay.instance,
      builder: (context, display, _) {
        _display = display;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0x2EFFFFFF),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  _header(t, display),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 26),
                    child: _cannotAfford
                        ? _shortOfChips(t, display)
                        : _buyIn(t, display),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _header(AppLocalizations t, ChipDisplaySettings display) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  widget.room.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: karataText(size: 24, weight: 800),
                ),
              ),
              const SizedBox(width: 12),
              KarataTag(label: t.roomVariant(widget.room.variant)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            t.roomBlinds(
              ChipDisplay.amountOnly(display, widget.room.smallBlind),
              ChipDisplay.formatWith(display, widget.room.bigBlind),
            ),
            style: karataText(
              size: 13,
              weight: 500,
              color: KarataColors.inkMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buyIn(AppLocalizations t, ChipDisplaySettings display) {
    final min = widget.room.minimumBuyIn;
    final minText = ChipDisplay.formatWith(display, min);
    final maxText = ChipDisplay.formatWith(display, _maxChips);
    // The presets carry the bare number: the unit is already on the field above them and on the
    // balance below, and three of these have to share the width of one.
    final presets = <(String, int)>[
      // The minimum is only worth a preset when the room actually enforces one; where it does
      // not, the smallest legal buy-in is a single chip and no one wants that button.
      if (widget.room.enforceMinimumBuyIn)
        (t.roomBuyInMin(ChipDisplay.amountOnly(display, min)), min),
      (
        t.roomBuyInDefault(
          ChipDisplay.amountOnly(display, widget.room.defaultBuyIn),
        ),
        widget.room.defaultBuyIn,
      ),
      (t.roomBuyInMax(ChipDisplay.amountOnly(display, _maxChips)), _maxChips),
    ];
    final entered = _entered;
    // A room that enforces its minimum puts Min and Default on the same number, and "Default" is
    // the one the player meant - so it wins the tie rather than whichever comes first.
    final defaultPreset = widget.room.enforceMinimumBuyIn ? 1 : 0;
    final selected = entered == null
        ? null
        : entered == widget.room.defaultBuyIn
        ? defaultPreset
        : switch (presets.indexWhere((p) => p.$2 == entered)) {
            -1 => null,
            final i => i,
          };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LabeledField(
          label: t.roomBuyInAmount,
          child: AmountField(
            controller: _amount,
            display: display,
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: 16),
        ChoiceChipsRow(
          labels: [for (final preset in presets) preset.$1],
          selectedIndex: selected,
          onSelected: (i) => _setChips(presets[i].$2),
        ),
        const SizedBox(height: 16),
        _balanceRow(t, display, KarataColors.ink),
        const SizedBox(height: 16),
        Text(
          widget.room.enforceMinimumBuyIn
              ? t.roomBuyInBounds(minText, maxText)
              : t.roomBuyInBoundsMaxOnly(maxText),
          style: karataText(
            size: 12,
            weight: 500,
            color: KarataColors.inkFaint,
          ),
        ),
        const SizedBox(height: 16),
        KarataButton(
          label: t.roomSitDownFor(
            ChipDisplay.formatWith(
              display,
              entered ?? widget.room.defaultBuyIn,
            ),
          ),
          onPressed: _isValid
              ? () => Navigator.of(context).pop(SitDownFor(entered!))
              : null,
        ),
      ],
    );
  }

  Widget _shortOfChips(AppLocalizations t, ChipDisplaySettings display) {
    final (before, after) = t.roomNeedChipsAround();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _balanceRow(t, display, KarataColors.orangeLight),
        const SizedBox(height: 16),
        DashedBorder(
          color: const Color(0x66C4502A),
          background: const Color(0x1AC4502A),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: before),
                  TextSpan(
                    text: ChipDisplay.formatWith(
                      display,
                      widget.room.minimumBuyIn,
                    ),
                    style: karataText(
                      size: 14,
                      weight: 700,
                      color: KarataColors.white,
                      height: 1.5,
                    ),
                  ),
                  TextSpan(text: after),
                ],
              ),
              style: karataText(
                size: 14,
                weight: 500,
                color: KarataColors.orangePale,
                height: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        KarataButton(
          label: t.roomAddChips,
          height: 52,
          onPressed: () => Navigator.of(context).pop(const AddChipsFirst()),
        ),
        const SizedBox(height: 16),
        Center(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
              child: Text(
                t.roomNotNow,
                style: karataText(
                  size: 14,
                  weight: 700,
                  color: KarataColors.inkMuted,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _balanceRow(
    AppLocalizations t,
    ChipDisplaySettings display,
    Color valueColor,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          t.roomYourBalance,
          style: karataText(
            size: 13,
            weight: 500,
            color: KarataColors.inkMuted,
          ),
        ),
        Text(
          widget.balanceChips == null
              ? '—'
              : ChipDisplay.formatWith(display, widget.balanceChips),
          style: karataText(size: 15, weight: 800, color: valueColor),
        ),
      ],
    );
  }
}
