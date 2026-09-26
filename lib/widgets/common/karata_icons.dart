import 'karata_icon.dart';

/// Every icon the V2 mockups use, transcribed from their `d` attributes so that an icon can be
/// checked against the design by comparing strings.
abstract final class KarataIcons {
  // Navigation --------------------------------------------------------------
  static const back = KarataIconData([
    PathShape('M20 12 H5 M11 5 L4 12 L11 19'),
  ]);
  static const chevronRight = KarataIconData([PathShape('M9 6 L15 12 L9 18')]);
  static const chevronDown = KarataIconData([PathShape('M6 9 L12 15 L18 9')]);
  static const externalLink = KarataIconData([
    PathShape('M7 17 L17 7 M9 7 H17 V15'),
  ]);

  // Header actions ----------------------------------------------------------
  /// The brightness toggle in the top-right of the lobby and the table.
  static const brightness = KarataIconData([
    CircleShape(12, 12, 3),
    PathShape(
      'M12 2 V5 M12 19 V22 M2 12 H5 M19 12 H22 '
      'M4.9 4.9 L7 7 M17 17 L19.1 19.1 M4.9 19.1 L7 17 M17 7 L19.1 4.9',
    ),
  ]);

  static const refresh = KarataIconData([
    PathShape('M20 11 A8 8 0 1 0 18 17'),
    PathShape('M20 4 V11 H13'),
  ]);

  // Money -------------------------------------------------------------------
  /// Deposit: an arrow coming down onto a line.
  static const deposit = KarataIconData([
    PathShape('M12 4 V16 M7 11 L12 16 L17 11 M5 20 H19'),
  ]);

  /// Withdraw: an arrow leaving a line.
  static const withdraw = KarataIconData([
    PathShape('M12 20 V8 M7 13 L12 8 L17 13 M5 4 H19'),
  ]);

  static const copy = KarataIconData([
    RectShape(8, 8, 12, 12, radius: 2),
    PathShape(
      'M16 8 V5 A1 1 0 0 0 15 4 H5 A1 1 0 0 0 4 5 V15 A1 1 0 0 0 5 16 H8',
    ),
  ]);

  static const clock = KarataIconData([
    CircleShape(12, 12, 9),
    PathShape('M12 7 V12 L15 14'),
  ]);

  // Lobby -------------------------------------------------------------------
  static const plus = KarataIconData([PathShape('M12 5 V19 M5 12 H19')]);

  /// Join with link.
  static const link = KarataIconData([
    PathShape('M10 14 A4 4 0 0 0 16 14 L19 11 A4 4 0 0 0 13 5 L12 6'),
    PathShape('M14 10 A4 4 0 0 0 8 10 L5 13 A4 4 0 0 0 11 19 L12 18'),
  ]);

  /// Shuffle, used by the "pick another table name" button.
  static const shuffle = KarataIconData([
    PathShape(
      'M16 4 H20 V8 M4 20 L20 4 M20 16 V20 H16 M15 15 L20 20 M4 4 L9 9',
    ),
  ]);

  // Settings ----------------------------------------------------------------
  static const globe = KarataIconData([
    CircleShape(12, 12, 9),
    PathShape('M3 12 H21 M12 3 C15 6 15 18 12 21 C9 18 9 6 12 3'),
  ]);

  static const speaker = KarataIconData([
    PathShape('M4 9 H8 L13 5 V19 L8 15 H4 Z'),
    PathShape('M16.5 9 A4 4 0 0 1 16.5 15 M19 6.5 A8 8 0 0 1 19 17.5'),
  ]);

  static const money = KarataIconData([
    RectShape(3, 6, 18, 12, radius: 2),
    CircleShape(12, 12, 2.5),
  ]);

  static const sliders = KarataIconData([
    PathShape('M4 7 H14 M18 7 H20 M4 17 H6 M10 17 H20'),
    CircleShape(16, 7, 2),
    CircleShape(8, 17, 2),
  ]);

  static const logout = KarataIconData([
    PathShape('M10 4 H5 V20 H10 M14 8 L18 12 L14 16 M18 12 H9'),
  ]);

  static const eye = KarataIconData([
    PathShape('M2 12 C5 6 19 6 22 12 C19 18 5 18 2 12 Z'),
    CircleShape(12, 12, 3),
  ]);

  // Table -------------------------------------------------------------------
  /// The bet-sizing toggle, drawn as three descending bars.
  static const betBars = KarataIconData([
    PathShape('M3 4 H13 M3 8 H10 M3 12 H7'),
    // Drawn on a 16-unit box in the mockup rather than the usual 24.
  ], viewBox: 16);

  /// The emote button.
  static const emote = KarataIconData([
    CircleShape(9, 9, 7),
    PathShape('M6 10.5 Q9 13.5 12 10.5'),
  ], viewBox: 18);
}

/// The four suits, drawn filled. Colour is supplied by the caller because the same shape appears
/// in ink on a card face, in gold on a chip, and in muted grey on a folded hand.
abstract final class KarataSuits {
  static const spade = KarataIconData([
    PathShape(
      'M12 2 C8 7 3 10 3 14 C3 17 5.5 19 8 19 C9.5 19 10.7 18.3 11.3 17.5 '
      'L10 22 H14 L12.7 17.5 C13.3 18.3 14.5 19 16 19 C18.5 19 21 17 21 14 '
      'C21 10 16 7 12 2 Z',
    ),
  ], filled: true);

  static const heart = KarataIconData([
    PathShape(
      'M12 21 C5 15 2 11.5 2 8 C2 5 4.5 3 7 3 C9 3 11 4.3 12 6 '
      'C13 4.3 15 3 17 3 C19.5 3 22 5 22 8 C22 11.5 19 15 12 21 Z',
    ),
  ], filled: true);

  static const diamond = KarataIconData([
    PathShape('M12 2 L21 12 L12 22 L3 12 Z'),
  ], filled: true);

  static const club = KarataIconData([
    CircleShape(12, 7, 4.5),
    CircleShape(7, 13.5, 4.5),
    CircleShape(17, 13.5, 4.5),
    PathShape('M11 12 L9.5 22 H14.5 L13 12 Z'),
  ], filled: true);
}
