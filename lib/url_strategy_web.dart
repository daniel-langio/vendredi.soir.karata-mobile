import 'package:flutter_web_plugins/flutter_web_plugins.dart';

/// Drops the "#" from URLs (`karata.example.com/table/abc` rather than
/// `karata.example.com/#/table/abc`) so paths look like normal web app paths.
void configureUrlStrategy() => usePathUrlStrategy();
