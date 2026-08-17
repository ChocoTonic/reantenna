# Building and release retention

## Policy

- Git tags preserve every released source version indefinitely.
- CI validates every pull request and `main` push without signing.
- Each `main` push stores a simulator snapshot for 30 days; the workflow also
  deletes all but the newest three Threadline snapshots.
- A historical tag, branch, or commit can be rebuilt at any time by manually
  running **Simulator snapshot** and entering that ref.
- Failed XCTest result bundles are diagnostic-only and expire after three days.

Keeping three recent binaries is a rollback convenience, not the reproducibility
mechanism. The source tag, committed Xcode project, recorded Xcode/SDK metadata,
and deterministic dependencies are the rebuild mechanism. GitHub's retention
setting is time-based, so `snapshot.yml` adds count-based cleanup through the
Actions API.

## Free personal-device installation

Use Xcode on the Mac and select the Apple Account's Personal Team. A free Personal
Team profile expires after seven days, so the app must periodically be rebuilt and
reinstalled. Those short-lived credentials should not be exported to GitHub.

The simulator snapshot is unsigned and cannot be installed on an iPhone.

## Optional signed CI build

`signed-build.yml` is manual-only. It becomes usable with an Apple Developer
Program team and these GitHub Actions secrets:

| Secret | Value |
|---|---|
| `APPLE_CERTIFICATE_BASE64` | Base64-encoded signing `.p12` |
| `APPLE_CERTIFICATE_PASSWORD` | Password for the `.p12` |
| `APPLE_PROVISIONING_PROFILE_BASE64` | Base64-encoded matching profile |
| `APPLE_KEYCHAIN_PASSWORD` | Random temporary CI keychain password |
| `APPLE_TEAM_ID` | Apple developer team identifier |
| `APPLE_BUNDLE_ID` | Registered Threadline bundle identifier |

Run **Signed device build**, select a source ref, and choose the export method that
matches the profile. Debugging and release-testing IPAs only install on devices
included in the profile. App Store submission additionally requires App Store Connect
credentials and is intentionally not automated until an enrolled account exists.

Never commit certificates, profiles, API keys, Reddit tokens, or the old Antenna
iMazing backup.
