/// Builds the route for the other auth form, carrying any redirect with it.
///
/// Someone sent to a form by `_RequireSession` is on their way somewhere specific - a table they
/// followed a link to, the deposit screen. The V2 design cross-links the two forms, and following
/// that link must not lose the errand: dropping it lands them on the lobby after authenticating
/// instead of where they were going.
String authRouteWithRedirect(String path, String? redirectTarget) {
  if (redirectTarget == null || redirectTarget.isEmpty) return path;
  return '$path?redirect=${Uri.encodeQueryComponent(redirectTarget)}';
}
