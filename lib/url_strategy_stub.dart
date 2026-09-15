/// Non-web builds have no URL bar to tidy up, and `flutter_web_plugins` does not compile for
/// them - so the web implementation lives in url_strategy_web.dart and is swapped in by the
/// conditional import in main.dart.
void configureUrlStrategy() {}
