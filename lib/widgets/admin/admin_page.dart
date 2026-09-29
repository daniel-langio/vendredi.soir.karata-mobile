import 'package:flutter/material.dart';

import '../../theme/karata_colors.dart';
import '../../theme/karata_text_styles.dart';
import '../common/breakpoints.dart';
import '../common/karata_button.dart';
import '../common/karata_screen.dart';
import '../common/segmented_tabs.dart';
import '../desktop/desktop_shell.dart';
import '../desktop/desktop_sidebar.dart';
import '../rooms/rooms_error_state.dart';

/// The frame the six admin screens share: the wide layout's sidebar and title, or the phone's own
/// page header, plus the three states every one of them has - loading, unreachable, and loaded.
///
/// Worth existing because those three states are the whole difference between an admin screen
/// that is trustworthy and one that is not: an operator acting on a list has to be able to tell
/// "nobody is here" from "we could not find out", and that distinction is too easy to drop when
/// it is retyped six times.
class AdminPage extends StatelessWidget {
  const AdminPage({
    super.key,
    required this.nav,
    required this.sessionArgs,
    required this.username,
    required this.title,
    required this.subtitle,
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.children,
    this.actions = const [],
    this.onBack,
    this.wideRight = const [],
    this.leftFlex = 1,
    this.rightFlex = 1,
  });

  final DesktopNav nav;
  final Map<String, dynamic> sessionArgs;
  final String username;
  final String title;
  final String subtitle;

  /// True only while there is nothing to show yet - a refresh over existing rows leaves them up,
  /// because blanking a list an operator is reading is worse than a moment of staleness.
  final bool loading;

  final String? error;
  final VoidCallback onRetry;

  final List<Widget> children;

  /// The page's own buttons - "New room" and the like. The wide layout puts them on the title's
  /// line; the phone puts them in the header row opposite the back button, which is the only
  /// place it has for them.
  final List<Widget> actions;

  /// The phone's back button. The wide layout has the sidebar instead and ignores this.
  final VoidCallback? onBack;

  /// A second wide-only column, for the one screen (so far) whose content the design splits in
  /// two rather than stacking - the table editor's roster and stats beside its settings. Empty
  /// for every other admin screen, which keeps them on the plain single column they've always had.
  /// On the phone there is only ever one column, so this simply appears after [children].
  final List<Widget> wideRight;

  /// `grid-template-columns`, wide layout only - meaningless while [wideRight] is empty.
  final int leftFlex;
  final int rightFlex;

  @override
  Widget build(BuildContext context) {
    final loadingOrError = loading || error != null;
    final left = loadingOrError
        ? [
            if (loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(
                  child: CircularProgressIndicator(color: KarataColors.gold),
                ),
              )
            else
              _error(context),
          ]
        : children;

    if (KarataLayout.isWide(context)) {
      return DesktopShell(
        current: nav,
        sessionArgs: sessionArgs,
        username: username,
        title: title,
        subtitle: subtitle,
        actions: actions,
        child: !loadingOrError && wideRight.isNotEmpty
            ? DesktopColumns(
                leftFlex: leftFlex,
                rightFlex: rightFlex,
                left: left,
                right: wideRight,
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < left.length; i++) ...[
                    if (i > 0) const SizedBox(height: 20),
                    left[i],
                  ],
                ],
              ),
      );
    }

    return KarataScreen(
      onBack: onBack ?? () => Navigator.of(context).maybePop(),
      actions: actions,
      title: title,
      subtitle: subtitle,
      gap: 14,
      children: loadingOrError ? left : [...left, ...wideRight],
    );
  }

  Widget _error(BuildContext context) => RoomsErrorState(
    title: title,
    message: error!,
    retryLabel: MaterialLocalizations.of(context).refreshIndicatorSemanticLabel,
    onRetry: onRetry,
  );
}

/// The "New room" / "New table" pill an admin list carries beside its title.
class AdminPrimaryAction extends StatelessWidget {
  const AdminPrimaryAction({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => KarataButton(
    label: label,
    onPressed: onPressed,
    height: 46,
    expand: false,
    horizontalPadding: 20,
  );
}

/// The row of figures across the top of an admin list, which becomes a column on a phone.
class AdminStatRow extends StatelessWidget {
  const AdminStatRow({super.key, required this.tiles});

  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    if (!KarataLayout.isWide(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            tiles[i],
          ],
        ],
      );
    }
    // IntrinsicHeight so the tiles match each other rather than each sizing to its own caption -
    // a bare stretch cannot, because the row sits in a scrolling column and has no height of its
    // own to stretch them to.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            if (i > 0) const SizedBox(width: 16),
            Expanded(child: tiles[i]),
          ],
        ],
      ),
    );
  }
}

/// An admin list's filter chips.
///
/// The row scrolls sideways rather than shrinking its labels: four chips do not fit a phone in
/// every language, and a filter whose name has been cut in half is not one an operator can use.
class AdminFilterRow extends StatelessWidget {
  const AdminFilterRow({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final tabs = SegmentedTabs(
      labels: labels,
      selectedIndex: selectedIndex,
      onChanged: onChanged,
    );
    if (KarataLayout.isWide(context)) {
      return Align(alignment: Alignment.centerLeft, child: tabs);
    }
    return SingleChildScrollView(scrollDirection: Axis.horizontal, child: tabs);
  }
}

/// A short muted line, used where a list has nothing in it.
class AdminNote extends StatelessWidget {
  const AdminNote(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
    child: Text(
      message,
      textAlign: TextAlign.center,
      style: karataText(
        size: 14,
        weight: 500,
        color: KarataColors.inkMuted,
        height: 1.45,
      ),
    ),
  );
}
