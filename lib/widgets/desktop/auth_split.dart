import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/karata_colors.dart';
import '../../theme/karata_text_styles.dart';
import '../common/css_gradient.dart';
import '../common/karata_backdrop.dart';
import '../common/karata_icon.dart';
import '../common/karata_icons.dart';
import '../common/karata_logo.dart';
import '../common/kente_ribbon.dart';
import '../lobby/mascot_card_face.dart';
import '../lobby/mascot_palette.dart';

/// The frame behind the three wide screens you can reach signed out: a felt panel carrying the
/// mark and the tagline, and the form itself in a 400px column beside it.
///
/// The mockups draw the panel at a flat 640px on their 1280px canvas. A real window is not always
/// 1280px, and a fixed 640 would squeeze the form off the right of a 1000px one, so the panel
/// yields: it takes whatever is left once the form has the 400px column and the 48px gutter the
/// design gives it, up to the 640 it is drawn at. At 1280 and wider that arithmetic lands back on
/// exactly 640.
class AuthSplitLayout extends StatelessWidget {
  const AuthSplitLayout({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
  });

  /// The 38px heading the column opens with - "Log in", "Create account", "Welcome to Karata".
  final String title;
  final String? subtitle;

  /// The form column's rows, separated by the design's 18px.
  final List<Widget> children;

  static const _panelWidth = 640.0;
  static const _formWidth = 400.0;
  static const _formPadding = 48.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      // The page's navy radial gradient, exactly as on the phone: the felt panel paints over its
      // left half, and the form column sits on it.
      body: KarataBackdrop(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final formPane = _formWidth + _formPadding * 2;
            final panel = (constraints.maxWidth - formPane).clamp(
              0.0,
              _panelWidth,
            );
            final rows = <Widget>[
              Text(
                title,
                style: karataText(size: 38, weight: 800, letterSpacing: -0.02),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: karataText(
                    size: 15,
                    weight: 500,
                    color: KarataColors.inkMuted,
                    height: 1.45,
                  ),
                ),
              ...children,
            ];
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (panel > 0)
                  SizedBox(width: panel, child: const _FeltPanel()),
                Expanded(
                  child: SafeArea(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(_formPadding),
                        child: SizedBox(
                          width: math.min(
                            _formWidth,
                            constraints.maxWidth - panel - _formPadding * 2,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (var i = 0; i < rows.length; i++) ...[
                                if (i > 0) const SizedBox(height: 18),
                                rows[i],
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The teal half: the kente stripe, a dashed arc sweeping out of the bottom-left, two oversized
/// cards lying across it, and the lockup on top.
class _FeltPanel extends StatelessWidget {
  const _FeltPanel();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return ClipRect(
      child: CustomPaint(
        painter: const _FeltPainter(),
        child: Stack(
          children: [
            const Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: KenteRibbon(height: 8),
            ),
            // The design's own offsets, measured from the panel's top-left corner, which is what
            // `position: absolute` inside it means. They sit where they are drawn whatever the
            // panel's height turns out to be, and the ClipRect above takes whatever hangs off.
            Positioned(
              left: -120,
              top: 120,
              child: Container(
                width: 880,
                height: 620,
                decoration: BoxDecoration(
                  // `border-radius: 50%` on a box that is not square is an ellipse, not the
                  // circle BoxShape.circle would inscribe in its shorter side.
                  borderRadius: const BorderRadius.all(
                    Radius.elliptical(440, 310),
                  ),
                  border: Border.all(color: const Color(0x1AFFFFFF), width: 2),
                ),
              ),
            ),
            const Positioned(
              left: 70,
              top: 470,
              child: _HeroCard(rank: 'A', suit: KarataSuits.spade, turns: -12),
            ),
            const Positioned(
              left: 160,
              top: 455,
              child: _HeroCard(rank: 'K', suit: KarataSuits.heart, turns: 6),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 64,
                  vertical: 72,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const KarataLogo(size: 170),
                    const SizedBox(height: 22),
                    Text(
                      'Karata',
                      style: karataText(
                        size: 72,
                        weight: 800,
                        color: KarataColors.white,
                        height: 0.95,
                        letterSpacing: -0.03,
                      ),
                    ),
                    const SizedBox(height: 22),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 380),
                      child: Text(
                        t.welcomeTagline,
                        style: karataText(
                          size: 19,
                          weight: 500,
                          color: KarataColors.inkOnFelt,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeltPainter extends CustomPainter {
  const _FeltPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = cssRadialGradient(
          size: size,
          origin: const Offset(0.5, 0.42),
          colors: const [
            KarataColors.feltCenter,
            KarataColors.feltMid,
            KarataColors.feltEdge,
          ],
          stops: const [0, 0.55, 1],
        ),
    );
  }

  @override
  bool shouldRepaint(_FeltPainter oldDelegate) => false;
}

/// One of the two 110x152 gold cards lying across the panel.
class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.rank,
    required this.suit,
    required this.turns,
  });

  final String rank;
  final KarataIconData suit;

  /// The card's tilt in degrees, as the mockup's `rotate()` writes it.
  final double turns;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: turns * math.pi / 180,
      child: MascotCardFace(
        rank: rank,
        suit: suit,
        palette: MascotPalette.gold,
        width: 110,
        height: 152,
        radius: 13,
        rankSize: 29,
        cornerSuitSize: 18,
        pipSize: 55,
        cornerInset: const Offset(9, 9),
        centrePip: true,
      ),
    );
  }
}
