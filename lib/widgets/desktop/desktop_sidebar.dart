import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/karata_colors.dart';
import '../../theme/karata_text_styles.dart';
import '../common/avatar.dart';
import '../common/clickable.dart';
import '../common/karata_icon.dart';
import '../common/karata_icons.dart';
import '../common/karata_logo.dart';
import '../common/status_pill.dart';

/// The screens the wide layout's sidebar can reach, in the order it lists them.
///
/// [pending] and [economy] sit under a "House" heading, which is the phone's own arrangement too:
/// the wallet screen groups them in a House card rather than mixing them with a player's own
/// actions. The wide layout just promotes that group out of the wallet and into the nav.
///
/// The three admin entries sit under their own heading below it. They answer to the same operator
/// check, and are kept apart from House because House is the money the house handles day to day,
/// where these are the game's own records - the accounts, the tables and the rooms behind it.
enum DesktopNav {
  lobby('/menu'),
  newTable('/new-table'),
  joinTable('/join-table'),
  wallet('/economy'),
  settings('/settings'),
  pending('/economy/pending'),
  economy('/economy/config'),
  adminPlayers('/admin/players'),
  adminTables('/admin/tables'),
  adminRooms('/admin/rooms');

  const DesktopNav(this.route);

  final String route;
}

/// The 248px nav rail down the left of every wide screen: the mark, the five player entries, the
/// two House entries, and a card naming whoever is signed in.
class DesktopSidebar extends StatelessWidget {
  const DesktopSidebar({
    super.key,
    required this.current,
    required this.username,
    required this.balance,
    required this.onSelect,
    this.isOperator = false,
    this.pendingCount = 0,
  });

  /// The entry drawn as selected. Null on a screen the sidebar cannot reach - the deposit and
  /// withdraw screens, which are reached from the wallet and keep the wallet lit while open.
  final DesktopNav? current;

  final String username;

  /// The signed-in player's balance, already formatted with its unit, or null while it is still
  /// being fetched.
  final String? balance;

  final ValueChanged<DesktopNav> onSelect;

  /// Whether the House and Admin groups are listed. Every screen behind them is operator-only
  /// server-side, so only an operator is offered them - the same gate the wallet screen puts on
  /// its own House card.
  final bool isOperator;

  /// How many payouts the house still owes, shown as a gold badge on the pending entry. Hidden
  /// at zero, exactly as the wallet's own House card hides it.
  final int pendingCount;

  static const width = 248.0;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Container(
      width: width,
      color: KarataColors.sidebar,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 18),
            child: Row(
              children: [
                // Artboard 00 sizes the sidebar lockup's mark at 40. The die this replaced
                // filled its 34px box edge to edge; the card mark is a PNG with transparent
                // margin, so at 34 it read a quarter smaller than what it replaced.
                const KarataLogo(size: 40),
                const SizedBox(width: 10),
                // The wordmark takes what the mark leaves and shrinks if it has to, the same way
                // the nav labels below do. At the design's own sizes it does not have to - but
                // 40 + 10 + "Karata" at 26px is within a few pixels of the 200 this row gets, so
                // a wider rendering of the face has nowhere to go.
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Karata',
                      maxLines: 1,
                      style: karataText(
                        size: 26,
                        weight: 800,
                        letterSpacing: -0.02,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _item(DesktopNav.lobby, KarataIcons.lobby, t.navLobby),
          _item(DesktopNav.newTable, KarataIcons.plus, t.createTable),
          _item(DesktopNav.joinTable, KarataIcons.link, t.joinTableTitle),
          _item(DesktopNav.wallet, KarataIcons.wallet, t.economyTitle),
          _item(DesktopNav.settings, KarataIcons.brightness, t.settings),
          if (isOperator) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 20, 14, 6),
              child: Text(
                t.house,
                style: karataText(
                  size: 12,
                  weight: 600,
                  color: KarataColors.inkFaint,
                ),
              ),
            ),
            _item(
              DesktopNav.pending,
              KarataIcons.clock,
              t.pendingRedemptions,
              badge: pendingCount > 0
                  ? StatusPill(
                      label: '$pendingCount',
                      foreground: KarataColors.onGoldBadge,
                      background: KarataColors.gold,
                      ringColor: KarataColors.goldWash,
                      height: 20,
                      ringDiameter: 14,
                      fontSize: 11,
                      fontWeight: 800,
                    )
                  : null,
            ),
            _item(DesktopNav.economy, KarataIcons.sliders, t.economySettings),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 20, 14, 6),
              child: Text(
                t.adminGroup,
                style: karataText(
                  size: 12,
                  weight: 600,
                  color: KarataColors.inkFaint,
                ),
              ),
            ),
            _item(DesktopNav.adminPlayers, KarataIcons.person, t.adminPlayers),
            _item(DesktopNav.adminTables, KarataIcons.lobby, t.adminTables),
            _item(DesktopNav.adminRooms, KarataIcons.sliders, t.adminRooms),
          ],
          const Spacer(),
          _UserCard(username: username, balance: balance),
        ],
      ),
    );
  }

  Widget _item(
    DesktopNav nav,
    KarataIconData icon,
    String label, {
    Widget? badge,
  }) {
    return Padding(
      // The design's `gap: 6` between every child of the rail. Carried on the item rather than
      // interleaved as spacers so the House heading, which brings its own padding, stacks with it
      // the way the CSS does.
      padding: const EdgeInsets.only(bottom: 6),
      child: _NavItem(
        icon: icon,
        label: label,
        selected: nav == current,
        badge: badge,
        onPressed: () => onSelect(nav),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onPressed,
    this.badge,
  });

  final KarataIconData icon;
  final String label;
  final bool selected;
  final VoidCallback onPressed;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? KarataColors.ink : KarataColors.inkMuted;
    return Semantics(
      button: true,
      selected: selected,
      child: Clickable(
        onTap: onPressed,
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected ? KarataColors.surfaceRaised : null,
            borderRadius: BorderRadius.circular(21),
          ),
          child: Row(
            children: [
              KarataIcon(
                icon,
                size: 18,
                // The lit entry's glyph goes gold while its label goes white: the design marks
                // the current screen twice over, with the pill behind it and the accent on it.
                color: selected ? KarataColors.gold : KarataColors.inkMuted,
              ),
              const SizedBox(width: 12),
              Expanded(
                // "Pending withdrawals" and its badge do not both fit across 248px at Flutter's
                // metrics, and an ellipsis would leave "Pending with..." - which says nothing.
                // Shrinking the one label that overruns keeps every entry readable and leaves the
                // rest at the design's 15px.
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: karataText(size: 15, weight: 700, color: foreground),
                  ),
                ),
              ),
              if (badge != null) ...[const SizedBox(width: 6), badge!],
            ],
          ),
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.username, required this.balance});

  final String username;
  final String? balance;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: KarataColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Avatar(name: username, diameter: 40),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: karataText(size: 15, weight: 700),
                ),
                Text(
                  balance ?? '—',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: karataText(
                    size: 13,
                    weight: 600,
                    color: KarataColors.gold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
