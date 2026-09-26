import 'package:flutter_test/flutter_test.dart';
import 'package:poker_client/widgets/lobby/table_mascot.dart';

void main() {
  test('a table keeps the same hand however the list is ordered', () {
    expect(
      TableMascot.forTable('Analakely Nights'),
      TableMascot.forTable('Analakely Nights'),
    );
  });

  test('different tables get different hands', () {
    final names = [
      'Analakely Nights',
      'Débutants',
      'Vendredi Soir',
      'Tsena Kely',
      'Salty Ante',
      'Wild Ante',
      'Neon Deal',
    ];
    final hands = {for (final n in names) TableMascot.forTable(n)};
    expect(
      hands.length,
      names.length,
      reason: 'two tables in one list showing the same pair looks like a bug',
    );
  });

  test('the two cards are never the same card', () {
    for (final name in [
      '',
      'a',
      'Analakely Nights',
      'Débutants',
      'x' * 200,
      '777',
    ]) {
      final (first, second) = TableMascot.forTable(name);
      expect(first, isNot(second), reason: 'both cards matched for "$name"');
    }
  });

  test('every name lands on a real card', () {
    // A hash that ran off the end of either list would throw rather than draw a wrong card, so
    // this is really asserting the indexing stays inside one 52-card deck.
    for (var i = 0; i < 500; i++) {
      final (first, second) = TableMascot.forTable('table-$i');
      for (final (rank, _) in [first, second]) {
        expect(rank, isNotEmpty);
      }
    }
  });
}
