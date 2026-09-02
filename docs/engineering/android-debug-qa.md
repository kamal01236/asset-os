# Android debug QA checklist

Manual on-device verification for Hando debug APK sideload ([ADR-008](../architecture/decisions/ADR-008-android-packaging.md)). Run after a successful `.\scripts\build-apk-debug.ps1` build and install on a physical device or AVD (API 24+, ideally API 33+ for notification/gallery permissions).

## Prerequisites

- [ ] Flutter on PATH; `flutter doctor -v` shows Android toolchain OK
- [ ] `.\scripts\setup-android.ps1` completed (generates `gradlew.bat`, runs `pub get` + `build_runner`)
- [ ] Device or emulator connected (`flutter devices`)
- [ ] Debug APK installed: `apps/web/build/app/outputs/flutter-apk/app-debug.apk`

## Checklist

### Onboarding

- [ ] Fresh install opens onboarding / template selection
- [ ] Complete onboarding; app reaches Home with empty or seeded state
- [ ] Force-stop and reopen — data persists (native SQLite)

### Order + verification photo

- [ ] Create a new order from FAB → New Order
- [ ] Attach a verification photo from **gallery** (not camera — QR scan is manual text entry)
- [ ] Complete order; photo visible on rental detail
- [ ] Force-stop and reopen — order and photo still present

### Return + photo

- [ ] Start return flow for an active rental
- [ ] Attach return photo from gallery if prompted
- [ ] Complete return; rental status updates correctly
- [ ] Photo retained on completed rental / audit trail as expected

### Backup export / import

- [ ] More → Backup → export backup via share sheet
- [ ] Save file locally (Downloads or similar)
- [ ] Clear app data or use second install; import the same backup via file picker
- [ ] Data restores (customers, inventory, orders)

### Reminders + notifications

- [ ] More → Settings → Reminders: enable reminders
- [ ] On API 33+: system **POST_NOTIFICATIONS** permission prompt appears and is granted
- [ ] Schedule a digest time a few minutes ahead; notification fires with correct Hando icon (not broken/default)
- [ ] Overdue ping (if applicable) shows high-priority notification
- [ ] After reboot: reminders do **not** fire until app is opened once (known limitation — no `BOOT_COMPLETED` receiver)

### App lock (biometrics)

- [ ] Enable app lock in settings
- [ ] Background app; reopen — biometric prompt appears
- [ ] Successful unlock returns to last screen; cancel/deny blocks access

### Report export

- [ ] Generate a report (CSV, XLSX, or PDF) from Reports
- [ ] Share sheet opens with exported file
- [ ] Open shared file in another app — content is valid

## Known limitations (not bugs)

| Area | Expected behavior |
|------|-------------------|
| Reminders after reboot | Refresh when app opens; not persisted across reboot until launch |
| Backup | Manual share + file pick; no “save to Downloads” SAF UX |
| QR scan | Manual code entry only; no camera scanner |
| Release signing | Debug signing in release block — fine for sideload only |

## If something fails

| Symptom | Check |
|---------|--------|
| Gallery picker empty / denied | Manifest `READ_MEDIA_IMAGES` (API 33+) or `READ_EXTERNAL_STORAGE` (≤32); grant in system settings |
| No notification permission prompt | API 33+ device; Reminders screen requests permission |
| Broken notification icon | `drawable/ic_notification.xml` (monochrome); rebuild APK |
| Wrong launcher icon | Manifest `android:icon="@mipmap/ic_launcher"`; legacy PNGs under `mipmap-*dpi/` |
