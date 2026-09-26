import '../common/karata_icon.dart';
import '../common/karata_icons.dart';

/// The pair of cards fanned across a lobby table card.
typedef Mascot = ((String, KarataIconData), (String, KarataIconData));

/// Picks a table's two decorative cards from its name.
///
/// Derived from the name rather than the row's position so a table keeps the same pair wherever
/// it appears - as the list reorders, as tables come and go, between the lobby and any other
/// place that draws one. Cycling by index meant the same table showed a different hand every
/// time something above it closed.
abstract final class TableMascot {
  static const _ranks = [
    'A',
    'K',
    'Q',
    'J',
    '10',
    '9',
    '8',
    '7',
    '6',
    '5',
    '4',
    '3',
    '2',
  ];

  static const _suits = [
    KarataSuits.spade,
    KarataSuits.heart,
    KarataSuits.diamond,
    KarataSuits.club,
  ];

  /// A stable hand for [tableName]. The two cards are always different, the way a real hole-card
  /// pair is - dealt from one deck, so the second draw skips whatever the first took.
  static Mascot forTable(String tableName) {
    final seed = _hash(tableName);

    // Index into the 52 cards, then into the 51 that are left.
    final first = seed % 52;
    var second = (seed ~/ 52) % 51;
    if (second >= first) second++;

    return (_cardAt(first), _cardAt(second));
  }

  static (String, KarataIconData) _cardAt(int index) =>
      (_ranks[index % _ranks.length], _suits[index ~/ _ranks.length]);

  /// FNV-1a, because it has to agree across runs and platforms - String.hashCode does not.
  static int _hash(String value) {
    var hash = 0x811C9DC5;
    for (final unit in value.codeUnits) {
      hash = (hash ^ unit) * 0x01000193;
      // Kept inside 32 bits, and positive, so the modulo below is well defined.
      hash &= 0x7FFFFFFF;
    }
    return hash;
  }
}
