import 'package:flutter/material.dart';

import '../../api/api_client.dart';
import '../../chip_display.dart';
import '../../session_summary.dart';
import '../../theme/karata_colors.dart';
import '../../theme/karata_text_styles.dart';
import '../common/karata_backdrop.dart';
import 'desktop_sidebar.dart';

/// The frame the wide layout's nine signed-in screens are built on: the sidebar on the left, and
/// on the right a 40/48 page area opened by a 38px title with its actions on the same line.
///
/// It is the wide counterpart of [KarataScreen], and differs from it in the one way that matters:
/// there is no back button, because the sidebar is always on screen and is how you leave. Nav
/// entries replace the current page rather than pushing onto it, so the stack stays one deep
/// however long someone clicks around - browser back still works, because the route names are
/// what the URL strategy writes.
class DesktopShell extends StatefulWidget {
  const DesktopShell({
    super.key,
    required this.current,
    required this.sessionArgs,
    required this.username,
    required this.title,
    required this.child,
    this.subtitle,
    this.actions = const [],
  });

  final DesktopNav? current;

  /// serverUrl / token / username, passed on to whatever the sidebar navigates to.
  final Map<String, dynamic> sessionArgs;

  final String username;
  final String title;
  final String? subtitle;

  /// The round buttons on the title's right - refresh, the settings shortcut - or the pill
  /// buttons the lobby puts there.
  final List<Widget> actions;

  /// The page itself, below the title. Scrolls when it is taller than the window, which the
  /// taller mockups are.
  final Widget child;

  @override
  State<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<DesktopShell> {
  @override
  void initState() {
    super.initState();
    // Fills in whatever the sidebar still needs - the balance, and whether this player runs the
    // house. A no-op once something else has already fetched them this session.
    SessionSummary.instance.ensure(
      ApiClient(
        baseUrl: widget.sessionArgs['serverUrl'] as String,
        token: widget.sessionArgs['token'] as String,
      ),
    );
  }

  void _go(DesktopNav nav) {
    if (nav == widget.current) return;
    // Clears the stack rather than just this page: the deposit and withdraw screens are pushed
    // on top of the wallet, so replacing only the top one would leave the wallet stranded
    // underneath. The sidebar is always on screen and is how you leave, so nothing behind it is
    // ever wanted - the same clean sweep login already does on its way to the lobby.
    Navigator.of(context).pushNamedAndRemoveUntil(
      nav.route,
      (route) => false,
      arguments: widget.sessionArgs,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: KarataBackdrop(
        child: SafeArea(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ValueListenableBuilder<SessionSummaryData>(
                valueListenable: SessionSummary.instance,
                builder: (context, summary, _) =>
                    ValueListenableBuilder<ChipDisplaySettings>(
                      valueListenable: ChipDisplay.instance,
                      builder: (context, chips, _) => DesktopSidebar(
                        current: widget.current,
                        username: widget.username,
                        balance: summary.balanceChips == null
                            ? null
                            : ChipDisplay.formatWith(
                                chips,
                                summary.balanceChips,
                              ),
                        showHouse: summary.isOperator,
                        pendingCount: summary.pendingCount,
                        onSelect: _go,
                      ),
                    ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(48, 40, 48, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DesktopPageHeader(
                        title: widget.title,
                        subtitle: widget.subtitle,
                        actions: widget.actions,
                      ),
                      const SizedBox(height: 28),
                      Expanded(
                        child: SingleChildScrollView(
                          // The 40px the page area would have had at its foot, handed to the
                          // scroll view so it survives being scrolled to.
                          padding: const EdgeInsets.only(bottom: 40),
                          child: widget.child,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A wide screen's opening line: the title, the sentence under it, and the actions on its right,
/// all sitting on one baseline.
class DesktopPageHeader extends StatelessWidget {
  const DesktopPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Row(
      // The design aligns the actions with the bottom of the subtitle rather than the top of the
      // title, so a screen with no subtitle keeps its buttons beside the heading itself.
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: karataText(
                  size: 38,
                  weight: 800,
                  height: 1.05,
                  letterSpacing: -0.02,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Text(
                    subtitle!,
                    style: karataText(
                      size: 15,
                      weight: 500,
                      color: KarataColors.inkMuted,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (actions.isNotEmpty) ...[
          const SizedBox(width: 24),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < actions.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                actions[i],
              ],
            ],
          ),
        ],
      ],
    );
  }
}

/// The two-column grid the wide screens lay their cards out on: a 24px gutter between the
/// columns and 16px between the cards stacked inside each one.
class DesktopColumns extends StatelessWidget {
  const DesktopColumns({
    super.key,
    required this.left,
    required this.right,
    this.leftFlex = 1,
    this.rightFlex = 1,
  });

  final List<Widget> left;
  final List<Widget> right;

  /// `grid-template-columns`. Even by default; the new-table and withdraw screens give their
  /// form column the design's `1.3fr` against the summary beside it.
  final int leftFlex;
  final int rightFlex;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: leftFlex, child: _column(left)),
        const SizedBox(width: 24),
        Expanded(flex: rightFlex, child: _column(right)),
      ],
    );
  }

  Widget _column(List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          children[i],
        ],
      ],
    );
  }
}
