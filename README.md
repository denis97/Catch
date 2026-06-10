# Catch

A Flutter transit companion for your daily commute. Catch shows the next departure from your current location to your Home or Work, with a live countdown to when you need to walk out the door.

---

## What it does

Open the app and you immediately see the next transit option — the line, the boarding stop, how far you need to walk, and exactly how many minutes until you have to leave. A "If you miss it" list shows the next few alternatives. Tap "Remind me" and you get a local notification (with a live countdown on Android) that fires 2 minutes before walk-out time.

**Favorites** let you add any address beyond Home and Work. The destination tab bar expands to a scrollable pill strip so you can fetch departures to the gym, a family member's place, or wherever else you commute to regularly.

The app auto-detects which direction you're heading: if you're within 400 m of home, it switches to showing work departures, and vice versa. You can override this any time by tapping a destination pill, which puts it into manual mode.

---

## Screens

### Home
The main screen. Shows a heading ("Heading home" / "Heading to work" / "Heading to [place]"), an AUTO/MANUAL chip, and a destination toggle.

- **AUTO** — auto-switches destination based on your proximity to Home/Work (400 m threshold). Re-evaluated on pull-to-refresh or tapping the AUTO chip.
- **MANUAL** — engaged whenever you tap a destination pill manually. AUTO chip re-enables auto-detection.
- **Destination pills** — if you have no favorites: a full-width Home/Work toggle. If you have favorites: a horizontally scrollable row of pills (Home · Work · Gym · …).
- **Departure hero card** — next departure with urgency colour (teal → amber → grey as time runs out), walk time, line badge, headsign, times, duration, and a "Remind me" button.
- **"If you miss it"** — remaining departures as a compact timeline below the hero.
- **Pull-to-refresh** — forces a fresh GPS fix and re-fetches live data.
- **Preview banner** — shown when live data is unavailable (location denied, address not set, API unreachable, already at destination). Mock departures are shown as a fallback.

### Places
Settings screen. Tap the gear icon on the home screen.

- **Home / Work anchors** — tap to search and set an address (required for live departures).
- **Favorites** — tap "Add a place" or the + button. Long-press a row or tap the trash icon to delete (requires confirmation).
- **Appearance** — dark/light mode toggle.

### Detail
Tap any departure card to see all upcoming options for that line.

- A horizontal strip of alternative lines with durations and transfer counts.
- Each upcoming departure in an expandable card — collapsed shows the essentials; expanded shows a leg-by-leg breakdown (walk → transit → walk) with a "Remind me" button per departure.

### Address Search
Used when setting Home, Work, or a new favorite. Type 3+ characters for live Google Places suggestions. If the API is unavailable, you can save a plain text address without coordinates (departures will use the address string for routing rather than coordinates).

### Onboarding
Three-step walkthrough shown on first launch: welcome, location permission request, and Home/Work address setup. Can be skipped.

---

## Architecture

### State and persistence
`PlacesRepository` extends `ChangeNotifier` and is the single source of truth for all saved places (Home, Work, and favorites). It persists to `SharedPreferences` under the key `places_v1` as a JSON array. `HomeScreen` listens to the repository so the departure feed refreshes automatically when places change.

### Location
`LocationService` wraps the `geolocator` package. The last fix is cached in memory for 60 seconds — destination switches reuse it rather than re-acquiring GPS (a high-accuracy fix can take up to 2 s). A fresh fix is forced on pull-to-refresh, when tapping AUTO, or when the cached fix is stale.

### Transit
`TransitService` calls the Google Directions API (`mode=transit`) and parses the routes into `Departure` objects. Results are cached in a static in-memory map for 2 minutes, keyed by origin (rounded to ~100 m), destination, and 2-minute time bucket — so rapid destination toggling and small GPS jitter reuse the same response.

When live data is unavailable the app falls back to hardcoded mock departures (`kHomeDeps` / `kWorkDeps`) and shows a preview banner.

### Data model
```
Place     kind(home|work|star)  name  address  lat  lng
Departure line  headsign  from  walk  depart  arrive  duration  legs  departMin
Leg       mode(bus|train|metro|tram|ferry|walk)  minutes  line?
```

`Departure.leaveIn` is computed at read time (`departMin − walk − currentMinutesInDay`) so countdowns stay accurate via a 1-minute `Timer` without re-fetching.

### Reminders
`ReminderService` uses `flutter_local_notifications`. On Android it posts an ongoing live-countdown notification immediately and schedules an exact alarm for 2 minutes before walk-out time. On iOS only the scheduled alert fires. Result values: `pinned`, `scheduled`, `firedNow`, `tooLate`, `denied`.

---

## Setup

### Prerequisites
- Flutter SDK (stable, version pinned in CI at **3.32.2**)
- Android SDK with NDK **27.0.12077973**
- A Google Maps Platform API key with **Directions API** and **Places API** enabled

### API key
The key lives in `lib/config.dart`, which is gitignored. Create it:
```dart
// lib/config.dart
const String kGoogleMapsApiKey = 'YOUR_KEY_HERE';
```

### Run
```bash
flutter pub get
flutter run
```

---

## Release builds

### Android signing
Release builds must be signed with a stable keystore — using the per-machine debug keystore means Android rejects in-place updates (`INSTALL_FAILED_UPDATE_INCOMPATIBLE`) and forces an uninstall first.

**Create a keystore once** (keep it safe; losing it means you can never update existing installs):
```bash
keytool -genkey -v -keystore catch-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias catch
```

On Windows, `keytool` ships with the JDK bundled in Android Studio at `C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe`.

**Create `android/key.properties`** (gitignored — never commit this):
```properties
storePassword=<password>
keyPassword=<password>
keyAlias=catch
storeFile=/path/to/catch-release.jks
```

Use forward slashes on Windows: `C:/Users/you/catch-release.jks`.

When `key.properties` is present, the Gradle build uses the release keystore. When it's absent (fresh clone, CI without secrets), it falls back to debug signing.

### CI/CD
GitHub Actions builds a signed release APK on every push to `main` and on manual trigger. Artifact: `catch-release` → `app-release.apk`, retained for 30 days.

**Required repository secrets** (Settings → Secrets and variables → Actions):

| Secret | Value |
|--------|-------|
| `GOOGLE_MAPS_API_KEY` | Your Maps Platform key |
| `ANDROID_KEYSTORE_BASE64` | Base64 of your `.jks` file |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore password |
| `ANDROID_KEY_PASSWORD` | Key password |
| `ANDROID_KEY_ALIAS` | Alias used in `keytool` (e.g. `catch`) |

To encode the keystore on Windows PowerShell:
```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("$env:USERPROFILE\catch-release.jks")) | Set-Clipboard
```

On Linux/macOS:
```bash
base64 -w0 catch-release.jks
```

If any signing secret is absent, the workflow falls back to debug signing — the build still succeeds but the APK won't install as an update over a release-signed one.

**Note:** The very first install of a properly signed build still requires uninstalling any existing debug-signed copy. After that, updates install in place.
