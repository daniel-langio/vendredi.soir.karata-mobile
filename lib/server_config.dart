/// Where the deployed backend lives, written down once.
///
/// Everything that needs to reach it derives from here - the app's own default server, and the
/// debug backend picker's built-in entry - so moving the service (region, project or host) is a
/// one-line change rather than a hunt through screens and assets.
const kKarataHost = 'https://preprod-karata-210977503792.africa-south1.run.app';

/// The poker API's base, which is what an ApiClient is actually constructed with.
const kDefaultServerUrl = '$kKarataHost/poker';
