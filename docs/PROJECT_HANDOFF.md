# ReAntenna project handoff and next-session runbook

Last verified: 2026-08-17

This is the durable pickup point for the project. It records what exists, what is
still a prototype, what information or accounts are needed from the owner, and the
checkpoint-by-checkpoint plan for Reddit access and personal iPhone installation.

The SideStore portion deliberately follows the current official **iLoader +
LocalDevVPN + stable SideStore** process. Do not substitute an old tutorial that
uses AltServer, JitterbugPair, WireGuard, or StosVPN unless the current SideStore
documentation explicitly redirects us there.

## Start here next session

Do these in this order:

1. Complete **Checkpoint 0: version inventory** below and send the results.
2. On the Mac, make full Xcode the active command-line developer directory:

   ```sh
   sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
   xcodebuild -version
   ```

   Xcode 26.6 is installed, but at handoff time `xcode-select` still points to
   `/Library/Developer/CommandLineTools`. The command above requires the Mac
   administrator password and therefore needs to be run by the owner.
3. Decide on the permanent bundle identifier. A reasonable default is
   `com.chocotonic.reantenna`; do not change it after installing the app if local
   data should survive updates.
4. Decide whether the currently private GitHub repository should actually become
   open source. It needs a license before it should be described as open source to
   Reddit. The code is currently in a private repository and has no `LICENSE` file.
5. Begin the Reddit Data API request in **Reddit access**. Never paste an Apple
   password, Reddit password, OAuth refresh token, signing certificate, or device
   pairing file into chat or the repository.

## What has been completed

### Repository and identity

- The application lives in its own repository at
  `/Users/asdf/repos/reantenna` with remote
  `https://github.com/ChocoTonic/reantenna`.
- The project, target, scheme, product, and user-facing name are **ReAntenna**.
- The code and assets are independently created. The README states that the app is
  an unofficial reimplementation inspired by Antenna/AMRC and is not affiliated
  with its original developer.
- `project.yml` is the source of truth for the generated Xcode project.
- The old iMazing backup was researched. It contains useful model and preference
  names but no executable, storyboards, or artwork, so it cannot provide the
  original implementation. It also contains historic credentials and must never
  be committed or distributed.

### Working application behavior

- Dense, thumbnail, and grid feed layouts over deterministic fixture data.
- Compact Antenna-inspired light and dark palettes, plus system appearance.
- Swipe-from-anywhere navigation, a compact right drawer, row actions, and back
  navigation.
- A unified post/media/comments screen.
- Tap-to-collapse individual comment branches.
- **Collapse Children** leaves every root comment visible and hides descendants;
  **Expand All** restores the tree.
- Previous/next root-comment navigation and local Best/Top/New/Controversial sort.
- Local post/comment actions for exercising the interface.
- Persistent theme, layout, text, preview, cellular, browser, pagination, history,
  and cache preferences.
- Viewed-item history persists and can be cleared; URL cache capacity and clearing
  work. Biometric hardware availability is reported honestly, but app lock is not
  implemented.
- A replaceable `RedditService` boundary, `FixtureRedditService`, and the beginning
  of an approval-gated `DataAPIRedditService`.

### Build and CI state

- The project builds and launches in the simulator and five unit tests pass.
- CI builds/tests every pull request and `main` push.
- Main-branch simulator snapshots keep only the newest three artifacts.
- Tags/commits preserve source for historical rebuilds; the snapshot workflow can
  rebuild any ref manually.
- A manual signed-device workflow exists for a future paid developer team, but it
  is not needed for this free SideStore plan and no signing secrets should be added
  to GitHub for a Personal Team.
- On 2026-08-17 an unsigned **arm64 iPhoneOS** Release build was successfully
  produced with Xcode 26.6 by explicitly setting `DEVELOPER_DIR`. This validates
  the core of the planned SideStore IPA packaging process.

## What still needs to be built

### Required for a real Reddit client

- Reddit approval for this exact noncommercial native-client use case.
- Installed-app OAuth login and callback handling using
  `ASWebAuthenticationSession`, unique `state` validation, token exchange, refresh,
  logout, and Keychain storage.
- Selection of least-privilege OAuth scopes; read-only behavior should land before
  write scopes.
- Connection of `DataAPIRedditService` to the app instead of fixtures.
- Complete listing/thread decoding, pagination, `more` comments, account switching,
  API errors, rate-limit handling, retries, cache expiry, and deletion handling.
- Real search, subreddit/user feeds, saved/hidden items, profile, inbox, voting,
  saving, replying, submission, edit/delete, and moderation operations.

### Product work after live read-only data

- Real image, album, GIF/video, Reddit-video, YouTube, link-preview, and external
  browser pipelines.
- Enforcement of the browser, manual/automatic pagination, and cellular-limit
  settings in those pipelines. The settings currently persist but these network
  pipelines do not exist yet.
- Offline/error/empty states and safe handling of deleted or quarantined content.
- Passcode/Face ID application lock.
- Original app icon and finished visual assets.
- Accessibility audit, UI tests, performance profiling, and physical iOS 18
  gesture testing.
- A repeatable `scripts/build-sidestore-ipa.sh` command and, only after the manual
  process works, an unsigned-IPA GitHub workflow.

## What is needed from the owner

- The exact iOS 18 point release, Mac model/architecture, macOS version, Xcode
  version, and the installed SideStore/iLoader/LocalDevVPN versions as they become
  available.
- Permission to switch the repository from private to public, if desired, and a
  license choice. MIT is a straightforward default for this kind of sample app.
- A permanent reverse-DNS bundle identifier.
- A Reddit username to place in the required descriptive User-Agent.
- The result of Reddit's Data API review and the newly issued **installed-app client
  ID**. The client ID is not a native-app secret, but it should still be supplied
  through local configuration rather than hard-coded into tracked source.
- Confirmation at each `STOP` checkpoint below. We should not skip ahead because a
  bad pairing or first refresh is easier to diagnose before an app IPA is involved.

## Reddit access: owner steps and integration plan

Reddit currently says Data API access is for approved developers, requires OAuth,
and requires a descriptive User-Agent. Its help page also warns that legacy API
documentation can be stale. Use the current official application path from
[Developer Platform & Accessing Reddit Data](https://support.reddithelp.com/hc/en-us/articles/14945211791892-Developer-Platform-Accessing-Reddit-Data)
and the rules in the
[Reddit Data API Wiki](https://support.reddithelp.com/hc/en-us/articles/16160319875092-Reddit-Data-API-Wiki).

### R1 — settle identity before applying

**Do:** Choose the bundle ID, Reddit contact username, repository visibility, and
license. Keep the project noncommercial: no ads, payment, subscriptions, resale,
or model training. A truthful application description is:

> ReAntenna is a personal, noncommercial native iOS Reddit reader and interaction
> client, independently implemented as an unofficial spiritual successor to the
> discontinued Antenna/AMRC interface. It is for one developer's personal device,
> stores account tokens only in the iOS Keychain, does not sell or train on Reddit
> data, and will use OAuth plus a descriptive User-Agent. Source URL: [public URL
> only if the repository has actually been made public].

**Success looks like:** We have one stable bundle ID and can truthfully describe the
repository as either private personal source or public open source.

**Important choice:** Do not claim the current private, unlicensed repository is
open source. Do not call the app official Antenna or imply endorsement.

**Common failure:** A name or callback changes after OAuth registration. Fix it by
settling the bundle ID and callback first. Proposed callback:
`reantenna://oauth`.

**STOP:** Send the chosen bundle ID, Reddit username, visibility, and license.

### R2 — request Data API access and register the client

**Do:** Sign into Reddit, follow the noncommercial Data API signup link from the
official access page, and answer the review form with the exact personal use case.
If the approved flow directs you to `https://www.reddit.com/prefs/apps`, create an
**installed app**, not a script or web app, and register the exact callback
`reantenna://oauth`.

**Success looks like:** Reddit confirms approval and an installed-app entry has a
client ID. An installed app has no client secret because a phone cannot keep one.

**Important choices:** Request only the capabilities we implement. Start with
identity/read/subreddit/history-related access; add vote/save/submit/private-message
scopes only when those features are real. Use a User-Agent shaped like:

```text
ios:com.chocotonic.reantenna:0.1.0 (by /u/YOUR_USERNAME)
```

Replace the identifier and username with the final values. The redirect URI must
match Reddit's registration exactly, including case and punctuation.

**Common failure:** Creating a client at the legacy preferences page without API
approval may fail or yield access that Reddit later blocks. Complete the current
review path first and retain the approval email/reference.

**STOP:** Confirm approval and provide only the client ID and registered callback.
Do not provide passwords, authorization codes, access tokens, or refresh tokens.

### R3 — implementation after approval

The next coding session will:

1. Add an untracked local configuration file and a committed example template.
2. Register the callback URL scheme in `project.yml` and regenerate the project.
3. Implement `ASWebAuthenticationSession`, cryptographically random `state`, exact
   callback validation, code exchange, refresh, and revocation/logout.
4. Store refresh/access tokens in Keychain, isolated per Reddit account.
5. Start with read-only feeds and comments, then add write operations one family at
   a time.
6. Respect `x-ratelimit-*` headers and Reddit's current caching/deletion rules.

The old Antenna client ID, cookies, bearer tokens, and refresh tokens are forbidden.

## SideStore + free Apple Account runbook for iOS 18

This process intentionally pauses after every major step. When resuming, report the
checkpoint result before continuing.

### Limits and expectations

- Apple documents a free Personal Team limit of three installed apps per device,
  ten App IDs, and seven-day provisioning profiles. SideStore itself consumes one
  of the three active app slots, leaving two for ordinary sideloaded apps.
- SideStore says it periodically refreshes apps in the background, but iOS decides
  when background work runs. Treat it as best-effort, verify it on this exact phone,
  and retain a reminder fallback at least 48 hours before expiry.
- Wi-Fi and LocalDevVPN are required while SideStore installs, updates, or refreshes
  an app. LocalDevVPN is a loopback/device VPN, not a replacement for normal internet
  access.
- The Mac is needed for the initial SideStore install and to repair an expired or
  invalid pairing. A successful normal refresh does not require weekly Xcode or USB.
- A pairing file is sensitive device material. Keep it private, do not sync it to a
  public location, and never commit it.

Official references:

- [SideStore prerequisites](https://docs.sidestore.io/docs/installation/prerequisites)
- [Current SideStore installation](https://docs.sidestore.io/docs/installation/install)
- [SideStore FAQ](https://docs.sidestore.io/docs/faq)
- [Replace a pairing file](https://docs.sidestore.io/docs/advanced/pairing-file)
- [SideStore common issues](https://docs.sidestore.io/docs/troubleshooting/common-issues)
- [Apple Personal Team limits](https://developer.apple.com/help/account/basics/about-your-developer-account)
- [Apple Developer Mode](https://developer.apple.com/documentation/Xcode/enabling-developer-mode-on-a-device)

### Checkpoint 0 — inventory exact versions

**Do:** Record the following before downloading or changing anything:

1. iPhone: **Settings > General > About > iOS Version**.
2. Mac: Apple menu > **About This Mac**; record macOS version and whether the chip
   says Apple M-series or Intel.
3. Xcode: **Xcode > About Xcode**. In Terminal also run:

   ```sh
   xcodebuild -version
   xcode-select -p
   ```

4. If already installed, SideStore: open its Settings/About or view it in
   **Settings > General > iPhone Storage > SideStore**; do the same for LocalDevVPN.
5. iLoader: record the version from its About menu or downloaded release name.

**Success looks like:** We have exact version strings rather than “latest” or
“iOS 18.” `xcode-select -p` should eventually print
`/Applications/Xcode.app/Contents/Developer`.

**Important settings:** Install stable SideStore first. Do not start with nightly.

**Common failure:** Terminal reports that `xcodebuild` requires Xcode because the
active directory is CommandLineTools. Run the `sudo xcode-select --switch` command
from **Start here next session**, then accept any Xcode license/setup prompts.

**STOP:** Send the inventory and wait for compatibility confirmation.

### Checkpoint 1 — prepare the phone and Mac

**Do:**

1. Make a normal encrypted Finder backup of the iPhone if practical.
2. Confirm the phone has a passcode and is on Wi-Fi, not cellular-only.
3. Install **LocalDevVPN** from the link in the current official SideStore
   prerequisites page. Open it, tap **Connect**, approve **Allow VPN
   Configurations**, and enter the device passcode.
4. Download the current macOS **iLoader** only through the link in the official
   SideStore prerequisites/install pages. Move it to Applications if instructed.
5. If macOS blocks first launch, use **System Settings > Privacy & Security > Open
   Anyway** only after verifying it came from the official link.

**Success looks like:** LocalDevVPN shows connected and iOS displays its VPN
indicator/settings entry. iLoader opens on the Mac.

**Important settings:** Disable DNS blockers/content-filter VPNs temporarily during
setup. Keep the Mac and iPhone on the same ordinary Wi-Fi network.

**Common failure:** LocalDevVPN cannot add or connect its configuration. Remove only
the failed LocalDevVPN profile in **Settings > General > VPN & Device Management**,
restart the phone, reinstall from the official link, and retry with other VPN/DNS
filters disabled.

**STOP:** Confirm LocalDevVPN says connected and iLoader opens.

### Checkpoint 2 — install stable SideStore with iLoader

**Do:**

1. Connect the unlocked iPhone to the Mac with a data-capable USB cable.
2. Tap **Trust This Computer** on the iPhone and enter its passcode if asked.
3. Open iLoader and sign in with the Apple Account to be used for free signing.
   The account is case-sensitive and need not match the iCloud account on the phone.
4. Select the exact iPhone, then choose **Install SideStore (Stable)**.
5. Complete Apple two-factor authentication if prompted.

**Success looks like:** SideStore appears on the Home Screen and iLoader reports a
successful installation.

**Important settings:** Use one Apple Account consistently in iLoader and SideStore.
The account may have an existing development certificate revoked when a new one is
created; read prompts before accepting if the account signs other development apps.

**Common failure:** iLoader cannot see the phone. Unlock it, reconnect with a known
data cable/port, accept Trust again, confirm Finder sees it, quit/reopen iLoader,
and restart both devices if necessary. If authentication fails, verify exact account
case and complete 2FA; do not send credentials to anyone.

**STOP:** Confirm SideStore is visible; do not install ReAntenna yet.

### Checkpoint 3 — trust the developer and enable Developer Mode

**Do on iOS 18:**

1. Open **Settings > General > VPN & Device Management**.
2. Under **Developer App**, select the Apple Account entry.
3. Tap **Trust [account]**, then **Allow & Restart**, and enter the passcode.
4. After restart, open **Settings > Privacy & Security**, scroll to the bottom, and
   turn on **Developer Mode**.
5. Tap **Restart**. After the second restart, unlock, tap **Enable** on the
   confirmation alert, and enter the passcode.

**Success looks like:** Developer Mode remains on and SideStore opens rather than
showing an untrusted-developer warning.

**Important settings:** Developer Mode reduces some platform protections; leave it
enabled only while running locally installed development-signed apps.

**Common failure:** Developer Mode is absent. Reconnect the unlocked phone to Xcode
or iLoader, ensure the Mac is trusted, open Xcode's device window once, then check
Privacy & Security again. Apple notes that the switch appears after pairing with a
Mac has been initiated.

**STOP:** Confirm Developer Mode is on and SideStore launches.

### Checkpoint 4 — complete SideStore's first self-refresh

**Do:**

1. Confirm Wi-Fi is connected.
2. Open LocalDevVPN and tap **Connect**.
3. Open SideStore and sign in with the exact Apple Account used by iLoader.
4. Open **My Apps**.
5. Tap the **7 DAYS** counter beside SideStore to refresh it.
6. If prompted to create or revoke a signing certificate, read the prompt and tap
   **Yes** or **Refresh Now** if this account is dedicated to this setup.
7. Do not sideload another app until this refresh has completed.

**Success looks like:** SideStore sends the phone to the Home Screen with a
notification, reopens after a few seconds, and its counter shows close to seven
days with a recent refresh date.

**Important settings:** This first self-refresh changes SideStore to the app group
it expects. Skipping it can make subsequently installed apps disappear from its
list.

**Common failure:** For Wi-Fi/VPN/AFC errors, confirm both Wi-Fi and LocalDevVPN,
disable DNS blockers, retry, restart SideStore, then restart LocalDevVPN. If it
continues, replace the pairing file using Checkpoint 9 rather than following an old
WireGuard guide.

**STOP:** Confirm the counter and notification. SideStore is not considered set up
until this passes.

### Checkpoint 5 — establish a manual refresh baseline

**Do:** Wait until the displayed time has decreased, then connect Wi-Fi and
LocalDevVPN and tap **Refresh All** in SideStore. Record the before/after remaining
time and refresh timestamp.

**Success looks like:** The counter returns to approximately seven days without USB,
Xcode, or iLoader.

**Important settings:** Leave SideStore alone for a minute if it temporarily closes
or shows a spinner; it is reinstalling itself.

**Common failure:** Check SideStore's error log, then follow the official common
issues order: stable update/restart, clear cache, retry, sign out/in if appropriate,
restart phone, replace pairing file, and finally reinstall with iLoader.

**STOP:** Report the before/after values. This proves untethered refresh works before
automation is introduced.

### Checkpoint 6 — configure and verify best-effort automatic refresh

**Do:**

1. In **Settings > General > Background App Refresh**, enable Background App
   Refresh globally and for SideStore. Do not force-quit SideStore routinely.
2. Keep Wi-Fi available and LocalDevVPN connected during the test window. SideStore
   states that it periodically refreshes apps in the background.
3. If the installed stable build exposes a SideStore **Refresh All Apps** action in
   Apple's Shortcuts app, create a personal **Time of Day** automation that:
   - connects LocalDevVPN if the installed LocalDevVPN exposes a supported action;
   - waits long enough for the VPN to connect;
   - runs SideStore's own **Refresh All Apps** action;
   - runs immediately without confirmation.
4. Do not add an immediate “disconnect VPN” action. Leave LocalDevVPN running while
   the refresh finishes.
5. Add a separate Reminder for day 5 as a safety net until unattended refresh has
   succeeded repeatedly.

**Success looks like:** On the following day, My Apps shows a new last-refresh time
and a renewed remaining-days counter even though no cable or manual SideStore
refresh was used. Check both SideStore and ReAntenna once ReAntenna is installed.

**Important settings:** The exact Shortcuts actions are version-dependent. We will
inspect the actions supplied by the installed stable versions rather than importing
an untrusted shortcut. Background execution is controlled by iOS and is not a hard
guarantee.

**Common failure:** If the automation reports success but the counter does not move,
run the exact shortcut manually while watching LocalDevVPN, allow at least a minute,
and inspect SideStore's attempted-refresh/error logs. Keep the day-5 reminder and
use manual Refresh All while the SideStore project tracks the version-specific bug.

**STOP:** Wait for one genuinely unattended renewal and report the timestamps. Do
not declare automation verified merely because the shortcut ran.

## Build and install ReAntenna after SideStore works

### Checkpoint 7 — finalize Xcode identity and test the phone build

**Do:**

1. Activate full Xcode with the `xcode-select` command at the top of this file.
2. Open `ReAntenna.xcodeproj`.
3. In Xcode **Settings > Accounts**, add the same free Apple Account and confirm a
   **Personal Team** appears.
4. Select the ReAntenna target > **Signing & Capabilities**, enable automatic
   signing, choose the Personal Team, and set the permanent unique bundle ID.
5. Connect the iPhone, select it as the run destination, and press Run once.

**Success looks like:** The fixture app launches on the physical iPhone and the
collapse-children workflow, swipes, settings, and dark mode work there.

**Important settings:** Use the same bundle ID for every later version. Do not add
entitlements a Personal Team cannot provision. Xcode direct install is only this
one-time physical-device validation; SideStore will handle ongoing signing.

**Common failure:** “Failed to register bundle identifier” means the identifier is
not unique or cannot be used by the Personal Team. Choose a new reverse-DNS ID once,
update `project.yml`, regenerate with `xcodegen generate`, and keep that final ID.

**STOP:** Confirm the app launched on the iPhone and report any device-only defects.

### Checkpoint 8 — produce an unsigned device IPA

SideStore will apply the free development signature. The input must still be an
**iPhoneOS arm64 build**, never the simulator snapshot from GitHub Actions.

**Do from the repository root:**

```sh
cd /Users/asdf/repos/reantenna
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcodebuild \
  -project ReAntenna.xcodeproj \
  -scheme ReAntenna \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -derivedDataPath build/DerivedData \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  build
mkdir -p build/ipa/Payload
ditto build/DerivedData/Build/Products/Release-iphoneos/ReAntenna.app \
  build/ipa/Payload/ReAntenna.app
ditto -c -k --sequesterRsrc --keepParent build/ipa/Payload \
  build/ReAntenna-unsigned.ipa
file build/ipa/Payload/ReAntenna.app/ReAntenna
unzip -t build/ReAntenna-unsigned.ipa
```

**Success looks like:** `file` reports an arm64 Mach-O executable, `unzip -t`
reports no errors, and `build/ReAntenna-unsigned.ipa` exists.

**Important settings:** The `.ipa` is unsigned and should be treated as a build
artifact, not committed. Increment `MARKETING_VERSION` and
`CURRENT_PROJECT_VERSION` before distributing a new personal build once versioning
is added to `project.yml`.

**Common failure:** If the path contains `Release-iphonesimulator`, stop—the wrong
binary was built. If command-line tools are selected, fix `xcode-select`. If the app
build fails only with Release, reproduce in Xcode and resolve the compiler error
before packaging.

**STOP:** Confirm the `file` and `unzip -t` results before transferring the IPA.

### Checkpoint 9 — install the IPA through SideStore

**Do:**

1. Transfer `build/ReAntenna-unsigned.ipa` to the iPhone using AirDrop, iCloud Drive,
   or another private file transfer.
2. Confirm Wi-Fi and LocalDevVPN are connected.
3. In SideStore, use the **+**/My Apps import control and select the IPA from Files;
   alternatively use the iOS share sheet's SideStore action if supplied by the
   installed version.
4. Approve signing/install prompts and wait for SideStore to finish.

**Success looks like:** ReAntenna appears in My Apps and on the Home Screen, opens,
and has a remaining-days counter near seven. SideStore plus ReAntenna should consume
two of the three free active-app slots.

**Important settings:** Do not ask SideStore to randomize/change the bundle ID if
the option appears. Stable identity is required for in-place updates and local data.

**Common failure:** If installation reports an App ID/app-limit error, inspect My
Apps and deactivate/remove an unneeded sideloaded app; remember SideStore counts as
one. For Wi-Fi/VPN errors, repeat the official common-issues sequence from
Checkpoint 4.

**STOP:** Confirm ReAntenna launches and both counters are visible.

### Checkpoint 10 — prove ReAntenna refreshes without the Mac

**Do:** After its counter decreases, leave the Mac disconnected, connect Wi-Fi and
LocalDevVPN, and manually Refresh All once. Then allow the automatic-refresh test
from Checkpoint 6 to run on a later day. Record before/after counters and timestamps.

**Success looks like:** Both SideStore and ReAntenna renew without USB/Xcode. The
second test must be unattended to count as automatic-refresh verification.

**Important settings:** Check daily during the first week. A missed refresh that
reaches expiry can make SideStore itself unlaunchable and require iLoader recovery.

**Common failure:** If ReAntenna refreshes but SideStore does not, manually refresh
SideStore while it still opens, inspect prompts/logs, and keep the day-5 reminder.
Do not wait until day 7 to troubleshoot.

**STOP:** Record the first verified unattended refresh date here in a future commit.

### Checkpoint 11 — update later without losing local data

**Do:** Build a newer IPA with a higher version/build number and the **same bundle
identifier**. With the existing app still installed, connect Wi-Fi and LocalDevVPN,
then import/sideload the new IPA through SideStore over the old one.

**Success looks like:** The icon opens the new build and persisted ReAntenna settings
and viewed history remain. SideStore's FAQ says sideloading the same or updated IPA
without removing the original should retain its data.

**Important settings:** Never delete the installed app first. Do not choose a changed
or randomized bundle ID. Schema migrations must be backward-safe once persistence
grows beyond UserDefaults.

**Common failure:** A duplicate app appears, which indicates a bundle-ID mismatch.
Stop before deleting either copy, inspect each Info.plist/build setting, and decide
which identity owns the desired data. iOS does not normally merge two app containers.

**STOP:** Confirm version number and retained settings after the first update test.

### Pairing repair — use when SideStore loses device communication

This is a repair checkpoint, not routine weekly work.

**Do:** Connect the unlocked phone to the Mac by USB and trust it. In current iLoader,
choose **Delete Stored Pairing**, select the device and trust again, then choose
**Manage Pairing File** and **Place** beside SideStore/the affected app.

**Success looks like:** iLoader shows a green **Pairing file placed successfully!**
message and SideStore refreshes again with Wi-Fi + LocalDevVPN.

**Important settings:** Pairing can expire after an iOS update/reset or sometimes
unexpectedly. Keep the generated pairing data private.

**Common failure:** Restart phone and Mac, reconnect with a reliable data cable, and
repeat. If SideStore has already expired and cannot open, reinstall stable SideStore
with iLoader, complete its self-refresh, then re-import ReAntenna without deleting
the existing ReAntenna app if SideStore permits the in-place recovery.

## Definition of the next milestone

The next milestone is complete only when all of these are true:

- SideStore stable is installed through current iLoader on the iOS 18 phone.
- Developer Mode, LocalDevVPN, and pairing are confirmed.
- SideStore manually self-refreshes without the Mac.
- ReAntenna has a permanent bundle ID and launches on the physical phone.
- An unsigned arm64 IPA installs through SideStore.
- A later build updates in place while retaining local settings/history.
- At least one unattended refresh renews both SideStore and ReAntenna, with a day-5
  reminder retained as protection against iOS skipping background work.
- Reddit has either approved the Data API request, or the project has a recorded
  approval blocker and continues safely on fixtures.

