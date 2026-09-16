import 'dart:async';

import 'package:just_audio/just_audio.dart';

import 'sound_settings.dart';

/// Small, failure-tolerant sound layer. Audio is enhancement only: a browser/device that cannot
/// initialise it must never prevent a poker table from working.
class GameSounds {
  final _click = AudioPlayer();
  final _deal = AudioPlayer();
  final _chips = AudioPlayer();
  bool _ready = false;

  Future<void> prepare() async {
    try {
      await Future.wait([
        _click.setAsset('assets/sounds/click.ogg'),
        _deal.setAsset('assets/sounds/deal.ogg'),
        _chips.setAsset('assets/sounds/chips.ogg'),
      ]);
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  void click() => _play(_click);
  void deal() => _play(_deal);
  void chips() => _play(_chips);

  void _play(AudioPlayer player) {
    if (!_ready || !SoundSettings.instance.value) return;
    unawaited(player.seek(Duration.zero));
    unawaited(player.play());
  }

  Future<void> dispose() async {
    await Future.wait([_click.dispose(), _deal.dispose(), _chips.dispose()]);
  }
}
