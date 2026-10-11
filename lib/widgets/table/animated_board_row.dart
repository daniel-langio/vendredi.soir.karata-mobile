import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../theme/karata_colors.dart';
import '../../theme/karata_text_styles.dart';
import 'card_back.dart';
import 'card_code.dart';
import 'empty_card_slot.dart';
import 'flip_card.dart';
import 'playing_card.dart';

/// The community cards, laid out in a row at the centre of the felt - a slot that goes from empty
/// to dealt flips face-up in place rather than simply appearing, and briefly names the street
/// that just landed, the way a flop, turn or river does at the table.
///
/// The reference board flies all five cards in from a deck at the top; the product deals a street
/// at a time from server state that is already settled, so there is nothing to fly from - only
/// the flip and the street's name are reproduced here.
class AnimatedBoardRow extends StatefulWidget {
  const AnimatedBoardRow({
    super.key,
    required this.cards,
    this.winningCards = const {},
    this.cardWidth = 52,
    this.gap = 5,
  });

  final List<String?> cards;
  final Set<String> winningCards;
  final double cardWidth;
  final double gap;

  @override
  State<AnimatedBoardRow> createState() => _AnimatedBoardRowState();
}

class _AnimatedBoardRowState extends State<AnimatedBoardRow>
    with TickerProviderStateMixin {
  final Map<int, AnimationController> _flips = {};
  String? _label;
  Timer? _labelTimer;

  bool get _reduceMotion =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  @override
  void didUpdateWidget(AnimatedBoardRow old) {
    super.didUpdateWidget(old);
    if (!listEquals(old.cards, widget.cards)) {
      _reactToChange(old.cards, widget.cards);
    }
  }

  void _reactToChange(List<String?> was, List<String?> now) {
    final newlyRevealed = <int>[];
    for (var i = 0; i < now.length; i++) {
      final had = i < was.length ? was[i] : null;
      if (had == null && now[i] != null) newlyRevealed.add(i);
    }
    if (newlyRevealed.isEmpty) return;

    for (var k = 0; k < newlyRevealed.length; k++) {
      final i = newlyRevealed[k];
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 450),
      )..addStatusListener((status) {
        // A completed flip renders identically whether its controller is still in the map (at
        // value 1) or gone, so cleanup is deferred rather than forcing a rebuild to drop it.
        if (status != AnimationStatus.completed) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _flips.remove(i)?.dispose();
        });
      });
      _flips[i] = controller;
      if (_reduceMotion) {
        controller.value = 1;
      } else {
        Future.delayed(Duration(milliseconds: k * 110), () {
          if (mounted && _flips[i] == controller) controller.forward();
        });
      }
    }

    final label = switch (now.where((c) => c != null).length) {
      3 => 'Flop',
      4 => 'Turn',
      5 => 'River',
      _ => null,
    };
    if (label != null) _showLabel(label);
  }

  void _showLabel(String text) {
    _labelTimer?.cancel();
    setState(() => _label = text);
    _labelTimer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _label = null);
    });
  }

  @override
  void dispose() {
    for (final c in _flips.values) {
      c.dispose();
    }
    _labelTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showdown = widget.winningCards.isNotEmpty;
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < widget.cards.length; i++) ...[
              if (i > 0) SizedBox(width: widget.gap),
              _slot(i, showdown),
            ],
          ],
        ),
        if (_label != null)
          Positioned(
            bottom: -24,
            child: _StreetLabel(key: ValueKey(_label), label: _label!),
          ),
      ],
    );
  }

  Widget _slot(int i, bool showdown) {
    final card = widget.cards[i];
    if (card == null) return EmptyCardSlot(width: widget.cardWidth);

    final front = PlayingCard(
      code: CardCode(card),
      width: widget.cardWidth,
      highlighted: widget.winningCards.contains(card),
      muted: showdown && !widget.winningCards.contains(card),
    );
    final controller = _flips[i];
    if (controller == null) return front;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => CardFlip(
        t: controller.value,
        front: front,
        back: CardBack(width: widget.cardWidth),
      ),
    );
  }
}

/// "Flop", "Turn" or "River", fading in with a small rise and out again on its own.
class _StreetLabel extends StatefulWidget {
  const _StreetLabel({super.key, required this.label});

  final String label;

  @override
  State<_StreetLabel> createState() => _StreetLabelState();
}

class _StreetLabelState extends State<_StreetLabel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );

  @override
  void initState() {
    super.initState();
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    return FadeTransition(
      opacity: curved,
      child: AnimatedBuilder(
        animation: curved,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, (1 - curved.value) * 6),
          child: child,
        ),
        child: Text(
          widget.label,
          style: karataText(size: 18, weight: 800, color: KarataColors.gold),
        ),
      ),
    );
  }
}
