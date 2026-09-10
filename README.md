# poker_client

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Testing distribution (Firebase App Distribution)

Every push to `main`, `preprod`, or `master` builds a release APK and distributes it to the
`testers` group via Firebase App Distribution (`.github/workflows/build_apk.yml`) - testers get
notified and can install/auto-update without needing to manually download and sideload an APK
each time. Pull request builds skip this (still build + upload as a plain workflow artifact, just
not distributed) - a PR isn't necessarily meant for testers yet.

**Adding a tester**: open the [App Distribution tester console](https://console.firebase.google.com/project/karata0/appdistribution/app/android:com.vendredi.poker.poker_client/testers)
and add their email to the `testers` group (Testers & groups → `testers` → add testers). They'll
get an email invite.

**As a tester, one-time setup**:
1. Accept the email invite (or open the link Firebase sends).
2. Install the **Firebase App Tester** app when prompted (Android only needs this once).
3. From then on, new distributed builds show up as an update inside the App Tester app - no
   need to re-download an APK by hand each time.

**How this is wired up** (for reference / if it ever needs touching):
- Firebase project: `karata0` (same GCP project karata's backend already deploys to).
- Android app registered as `com.vendredi.poker.poker_client`, Firebase app id
  `1:210977503792:android:c89d272d5d925f5c4dcbf5`.
- CI authenticates via Workload Identity Federation (no downloadable service account key - this
  org has `iam.disableServiceAccountKeyCreation` enforced), as a dedicated service account
  `github-actions-distributor@karata0.iam.gserviceaccount.com` holding only
  `roles/firebaseappdistro.admin`. The existing `github-actions-pool`/`github-provider` WIF
  provider (originally scoped to the karata backend repo only) had its trust condition widened to
  also allow `daniel-langio/vendredi.soir.karata-mobile`.

## Release versioning

Every push to `main`, `preprod`, or `master` auto-bumps `pubspec.yaml`'s version and publishes a
tagged GitHub Release with the built APK attached (`.github/workflows/build_apk.yml`, after the
Firebase distribution step) - no manual version bumping needed for routine changes:

- A `feat:`/`feat(scope):` commit message bumps **minor** (resets patch to 0).
- Anything else bumps **patch**.
- **Major** is never bumped automatically - see below.

The build number (Android's `versionCode`) keeps auto-incrementing via commit count as before,
independent of this. Pull request / manual (`workflow_dispatch`) builds don't bump or tag
anything - they just build with whatever version is already committed.

**Publishing a major version**: run the **Release Major Version** workflow manually (Actions tab
→ "Release Major Version" → Run workflow). This bumps to `X+1.0.0`, builds, distributes to
testers, and tags/publishes a release exactly like the automatic path - kept as an explicit,
separate action rather than something that falls out of a commit message convention, since a
major version is a real product decision.

## License

Copyright Daniel Langio. Licensed under the [PolyForm Noncommercial License 1.0.0](LICENSE),
plus additional terms in the same file (no use to train/fine-tune AI models). Free for
noncommercial use; contact langio.tehiniavo@gmail.com for a commercial license.
