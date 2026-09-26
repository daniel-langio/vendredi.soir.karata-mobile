import 'package:flutter/material.dart';

import 'karata_backdrop.dart';
import 'kente_ribbon.dart';
import 'screen_header.dart';
import 'screen_title.dart';

/// The page frame every Karata screen is built on: the navy radial backdrop, the round-button
/// header, the heading block, and a scrolling body on the design's 16px gutter.
///
/// The mockups are fixed-height canvases, so they show no scrolling; several of them are already
/// taller than a phone (the new-table screen is 1120px against an 844px viewport), which is what
/// the body scrolls to accommodate.
class KarataScreen extends StatelessWidget {
  const KarataScreen({
    super.key,
    this.onBack,
    this.backLabel = 'Back',
    this.actions = const [],
    this.title,
    this.subtitle,
    this.children = const [],
    this.gap = 16,
    this.footer,
    this.topRibbon = false,
    this.body,
  });

  final VoidCallback? onBack;
  final String backLabel;
  final List<Widget> actions;
  final String? title;
  final String? subtitle;

  /// The body's rows, separated by [gap]. Ignored when [body] is given.
  final List<Widget> children;
  final double gap;

  /// Content pinned below the scroll area, as on the welcome screen.
  final Widget? footer;

  /// The kente stripe across the very top of the page, which only the welcome screen wears.
  final bool topRibbon;

  /// An escape hatch for a screen that lays its body out itself rather than as a gapped column.
  final Widget? body;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (final child in children) {
      if (rows.isNotEmpty) rows.add(SizedBox(height: gap));
      rows.add(child);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: KarataBackdrop(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (topRibbon) const KenteRibbon(),
              if (onBack != null || actions.isNotEmpty)
                ScreenHeader(
                  onBack: onBack,
                  backLabel: backLabel,
                  actions: actions,
                ),
              if (title != null) ScreenTitle(title: title!, subtitle: subtitle),
              Expanded(
                child:
                    body ??
                    SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: rows,
                      ),
                    ),
              ),
              ?footer,
            ],
          ),
        ),
      ),
    );
  }
}
