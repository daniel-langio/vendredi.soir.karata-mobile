import 'seat_action_badge.dart';

/// Everything the table needs to draw one seat. Assembled by the screen from the game payload so
/// that the widgets stay free of the API's shape.
class SeatData {
  const SeatData({
    required this.username,
    required this.stack,
    this.action,
    this.actionLabel,
    this.dimmed = false,
    this.isDealer = false,
    this.revealedCards,
  });

  final String username;

  /// Already formatted for display.
  final String stack;

  final SeatAction? action;
  final String? actionLabel;

  /// Out of the hand - folded, or sitting out.
  final bool dimmed;

  final bool isDealer;

  /// The hand shown at showdown, if this player's cards were revealed.
  final List<String?>? revealedCards;
}
