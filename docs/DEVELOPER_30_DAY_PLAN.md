# Developer 30-Day Onboarding Plan — KrishiMithra

*This plan assumes the developer starts after NDA and IP Agreement are signed, and after a development Firebase project is provided.*

---

## WEEK 1 — Codebase Understanding + Environment Setup

### Objectives
- Developer can run the app locally on a real Android device
- Developer has read and understood all module architectures
- Developer has no unanswered questions about the stack

### Tasks

| Task | Notes |
|---|---|
| Clone repository, run `flutter pub get`, run `flutter analyze` | Zero errors or warnings required before any new work begins |
| Run the app on a real Android device (not just emulator) | Emulator is acceptable for day 1; real device by day 3 |
| Read `CLAUDE.md` (project instructions) fully | The CLAUDE.md is the architecture reference document |
| Read `docs/CLAUDE_DEVELOPER_WORKFLOW.md` | Understand the 3-party workflow |
| Read `docs/DEVELOPER_SECURITY_ONBOARDING.md` | Understand access boundaries before asking for anything |
| Read `firestore.rules` and understand each collection's rules | Must be able to explain the admin/farmer role check without prompting |
| Review `lib/main.dart`, `lib/home/home_page.dart`, `lib/exporter_hub/exporter_home_page.dart` | Core navigation and the most complex module |
| Review `km_backend/server.js`, all routes, all middleware | Backend is simple — should take 2 hours maximum |
| Set up Firebase Emulator for local Auth + Firestore testing | Reference: Firebase Emulator Suite documentation |
| Write a brief (1-page) codebase map document for personal reference | Evidence they understood it, not just skimmed it |

### Deliverables
- App running on real Android device (screenshot provided to founder)
- Personal codebase notes document shared with founder
- List of questions/concerns raised (good sign — silence is suspicious)

### Acceptance Criteria
- `flutter analyze` returns 0 errors on the current branch
- Developer can explain the role-based access system (admin vs farmer) verbally
- Developer can explain the image upload pipeline without looking it up
- Developer can locate and explain any module's service + page + model files

---

## WEEK 2 — Critical Bugs + Security Hardening

### Objectives
- All Play Store blockers fixed
- Backend hardened against basic abuse
- No unresolved critical dependency issues

### Tasks

**Priority 1 — Play Store Blockers**

| Task | File(s) | Notes |
|---|---|---|
| Rename Android applicationId from `com.example.temp_fix` to final production ID | `android/app/build.gradle.kts`, `AndroidManifest.xml` (3 files), Firebase console | Discuss and agree the production package name with founder BEFORE making this change |
| Set up Android release keystore | `android/app/build.gradle.kts`, new `key.properties` file | Keystore file and `key.properties` must NEVER be committed to git — add to `.gitignore` immediately |
| Verify `signingConfig` for release uses production keystore, not debug | `android/app/build.gradle.kts` | |
| Test a release APK builds without errors | Run `flutter build apk --release` | |

**Priority 2 — Dependency Fixes**

| Task | File(s) | Notes |
|---|---|---|
| Pin `geolocator` to a specific version | `pubspec.yaml` | Check latest stable version, test location features still work |
| Evaluate `translator: ^1.0.3+1` — document risk and propose replacement | `pubspec.yaml`, `lib/services/` | See `THIRD_PARTY_LICENSE_AUDIT.md` for context |

**Priority 3 — Backend Hardening**

| Task | Notes |
|---|---|
| Add `express-rate-limit` to backend (`km_backend/`) | Separate limits for auth routes (5 req/min) and upload routes (20 req/min); /health exempt |
| Add basic input sanitization for string fields (trim, max length) | Apply to POST routes that accept user-generated content |
| Set `ALLOWED_ORIGINS` in Render environment variables | Add the production web URL; remove the "allow all" dev fallback |

### Deliverables
- PR #1: Android package rename + release signing setup (with updated `build.gradle.kts`)
- PR #2: Backend rate limiting + input validation
- PR #3: `geolocator` version pinned, `translator` evaluation documented

### Acceptance Criteria
- `flutter build apk --release` produces a valid APK signed with the production keystore
- Backend returns HTTP 429 after exceeding rate limit
- `/health` route is not rate limited
- `flutter analyze` still returns 0 errors after all changes

---

## WEEK 3 — Module Testing + Performance

### Objectives
- Critical user flows have automated tests
- No obvious Firestore inefficiencies that will cause cost or performance issues
- FCM push notifications planned and implementation started

### Tasks

**Testing**

| Task | Notes |
|---|---|
| Write widget tests for login flows (email, phone OTP) | `test/auth_test.dart` |
| Write widget tests for the product listing in F2B Mart | `test/f2b_listing_test.dart` |
| Write unit tests for `ExporterService.updatePOStatus()` | Most critical business logic method in the app |
| Write unit test for distance calculation in nearby-farmer sort | `test/distance_test.dart` |
| Total: minimum 15 tests passing | Run `flutter test` — 0 failures required |

**Performance Audit**

| Task | Notes |
|---|---|
| Review all Firestore `getExportProducts()` / `getF2BProducts()` queries for pagination | Large collections should use `limit(20)` + cursor pagination |
| Check all `StreamBuilder` widgets — are there any listening to entire collections? | Full-collection streams are expensive at scale |
| Audit `google_maps_flutter` usage — confirm API key is restricted in Google Cloud Console | Unrestricted Maps API key is a cost and security risk |

**FCM Push Notifications (Planning + Implementation Start)**

| Task | Notes |
|---|---|
| Add `firebase_messaging` dependency | Review FCM setup for Flutter documentation |
| Add FCM permission request to app startup | Android 13+ requires explicit permission |
| Design notification payload schema for key events (new order, PO status change, hire request) | Write a brief spec document, share with founder for approval before implementing |
| Implement basic foreground notification handler | Background handler in Week 4 |

### Deliverables
- PR #4: Test suite (minimum 15 passing tests)
- PR #5: Firestore query pagination (at least F2B products and export products)
- FCM spec document approved by founder
- PR #6: FCM setup (dependency, permissions, foreground handler)

### Acceptance Criteria
- `flutter test` passes with 0 failures
- At least 15 tests covering login, product listing, PO status update, distance sort
- No `StreamBuilder` listening to an entire collection without a `limit()`
- FCM permission dialog appears on Android 13+ devices

---

## WEEK 4 — Production Readiness + Play Store Preparation

### Objectives
- App is ready for Play Store internal testing track submission
- All critical pre-launch items resolved
- Founder has a clear picture of what is and is not ready

### Tasks

**FCM Completion**

| Task | Notes |
|---|---|
| Implement background notification handling | Use Firebase Cloud Messaging background handler |
| Implement notification tap navigation (deep link to relevant screen) | When user taps a notification, navigate to the correct module/page |
| Test notifications on multiple Android versions (minimum 10, 12, 13) | |

**Play Store Preparation**

| Task | Notes |
|---|---|
| Build production AAB (Android App Bundle — Play Store requires AAB not APK) | `flutter build appbundle --release` |
| Verify app passes Play Store pre-launch report checks | Submit to internal testing track, review results |
| Verify app icon looks correct at all sizes (including adaptive icon) | Check `flutter_launcher_icons` configuration |
| Verify all 6 locales display correctly on a real device | Especially Indic scripts (Kannada, Telugu, Tamil, Marathi) |
| Verify app works without internet (graceful degradation, not crash) | Firestore has offline support — verify it works |
| Write `data safety` section for Play Store listing | Required: what data is collected, why, is it shared |

**Known Issues Clearance**

| Task | Notes |
|---|---|
| Remove or document `lib/dashboard_page.dart` (broken legacy file) | Either delete it or add a clear deprecation comment |
| Document `export_hub/` as deprecated (do not extend, use `exporter_hub/`) | Comment in the directory or README |
| Resolve any remaining `flutter analyze` warnings | Target: 0 warnings, 0 errors |

### Deliverables
- Production AAB file (provided to founder for Play Store submission)
- PR #7: FCM background + deep link navigation
- PR #8: Cleanup (legacy file documentation, analyzer warnings)
- Play Store pre-launch report from internal testing track (shared with founder)
- Written summary: what is production-ready, what is deferred to post-launch

### Acceptance Criteria
- `flutter build appbundle --release` produces a valid AAB
- App passes internal testing track pre-launch checks with no blocking issues
- `flutter analyze` returns 0 errors, 0 warnings
- All 6 languages display correctly on a real device
- Push notifications delivered successfully on Android 10, 12, and 13

---

## POST-DAY-30 MILESTONES

| Milestone | Target |
|---|---|
| Play Store internal testing track live | Day 32–35 |
| Play Store open testing track | Day 40–45 |
| Play Store production launch | Day 50–60 |
| iOS configuration (if in scope) | Separate sprint, 2–3 weeks |
| Crash rate < 1% after launch | Monitor via Firebase Crashlytics post-launch |
| Average app startup time < 3 seconds | Measure and optimise if needed |

---

## MONTHLY PERFORMANCE REVIEW (AFTER DAY 30)

| Metric | How to Measure |
|---|---|
| Bugs reported vs bugs resolved (within SLA) | GitHub Issues |
| Test coverage trend | `flutter test --coverage` |
| `flutter analyze` errors/warnings | Run in CI |
| Crash-free user rate | Firebase Crashlytics |
| API error rate | Render logs / error monitoring |
| PR review turnaround | GitHub PR timestamps |
| Communication responsiveness | Team's subjective assessment |
| Deliverables committed vs delivered | Sprint tracker |
