import 'package:flutter/foundation.dart';

/// Whether the currently active screen wants more than the app's default phone-width cap on web
/// (see MyApp's builder in main.dart). Only TableScreen sets this true while it's mounted, so
/// every other screen keeps today's phone-width behavior regardless of window size.
class WideLayout {
  WideLayout._();
  static final instance = ValueNotifier<bool>(false);
}
