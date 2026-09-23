# Developer Requirements — KrishiMithra Private Limited

*Based on full codebase audit of 2026-09-23*

---

## ROLE

**Flutter + Full Stack Developer**  
KrishiMithra Private Limited

---

## EXPERIENCE

**Mid-level: 2–4 years of production Flutter development**

Not junior. Not necessarily senior. The distinction is clear: this developer must have shipped at least one Flutter app to the Google Play Store. They must be able to debug unfamiliar code, understand Firebase security, and reason about production risks without hand-holding.

### Why not junior?

- Must rename the Android package, set up release signing, and handle ProGuard — these steps are opaque to developers who have only worked in emulators.
- Must read existing Firestore security rules and understand their implications.
- Must assess whether a Firestore query will hit an index or cause a full scan.
- Must reason about API authentication and what happens when a token expires.
- Must make independent decisions without a senior reviewer in the office.

### Why not senior?

- The architecture is complete — no system design required.
- Claude handles complex code analysis and refactoring guidance.
- The primary work is execution: fix specific known issues, harden the backend, write tests, deploy.
- Senior developers command significantly higher salaries and often leave early-stage startups.
- A strong mid-level developer with 2–4 years of relevant experience outperforms an expensive senior who has never worked with this stack.

---

## TECHNICAL SKILLS

| Skill | Rating | Justification from codebase |
|---|---|---|
| Flutter / Dart | MUST HAVE | Entire frontend is Flutter |
| Firebase Auth | MUST HAVE | Email, phone OTP, Google Sign-In all in use |
| Cloud Firestore | MUST HAVE | Primary database with 25+ collections |
| Firebase security rules | MUST HAVE | Rules are deployed and enforced — must understand them |
| Google Play Store release | MUST HAVE | Package rename + signing is first blocker |
| Android build system (Gradle/KTS) | MUST HAVE | `build.gradle.kts` needs signing config changes |
| Node.js / Express | MUST HAVE | Existing backend has 4 route groups + middleware |
| REST API integration | MUST HAVE | App talks to Render-hosted backend |
| Git / GitHub (branch, PR, review) | MUST HAVE | Company will use branch-protected workflow |
| Image upload (Cloudinary) | IMPORTANT | Existing pipeline, may need extension |
| Supabase (storage) | IMPORTANT | Profile photos use Supabase, not Firebase Storage |
| Location services / Geolocator | IMPORTANT | Nearby-farmer sorting, location-based queries |
| Google Maps / flutter_map | IMPORTANT | Map views in Labour Hub and Exporter Hub |
| Debugging release builds | MUST HAVE | ProGuard/R8, release-mode crashes are common |
| Multilingual Flutter (l10n, ARB) | IMPORTANT | All strings must go into 6 ARB files |
| MongoDB (basic) | IMPORTANT | Backend syncs Firebase users to MongoDB Atlas |
| Performance optimisation | IMPORTANT | Firestore queries, list pagination, image caching |
| Security fundamentals | MUST HAVE | Token handling, credential hygiene |

### Nice to Have (not required)

| Skill | Notes |
|---|---|
| iOS Flutter (Xcode, provisioning) | Needed if iOS launch is in scope |
| FCM push notifications | Currently missing from app |
| Firebase Storage | Used by exporter_hub, basic operations |
| Flutter testing (unit + widget + integration) | App has almost no tests — strong plus |
| CI/CD (GitHub Actions) | Not currently set up — valuable for future |
| Docker | Not required for Render deployment |
| HuggingFace API | Crop disease detection uses it |
| Google ML Kit (on-device translation) | In pubspec but verify if actively used |

---

## RESPONSIBILITIES

### Day 1–30 (Onboarding & Critical Fixes)

- Understand codebase architecture, all modules, and deployment pipeline
- Rename Android package from `com.example.temp_fix` to final production ID
- Set up Android release keystore and signing configuration
- Fix `geolocator: any` to a pinned version
- Evaluate and replace `translator: ^1.0.3+1` (unofficial Google Translate API)
- Configure production CORS whitelist (`ALLOWED_ORIGINS`) in backend environment
- Add rate limiting middleware to Node.js backend
- Add basic input validation/sanitization to backend routes

### Month 2–3 (Production Hardening)

- Implement FCM push notifications (new booking alerts, PO status updates, order notifications)
- Write widget tests for critical user flows (login, product listing, PO creation)
- Coordinate Play Store asset preparation (screenshots, listing, privacy policy URL)
- Submit app to Google Play Store (internal testing track first)
- Fix any crash reports from internal testing

### Ongoing

- Respond to bug reports within agreed SLA
- Review and merge feature PRs following branch protection rules
- Update dependencies responsibly (test before updating)
- Keep Firestore security rules updated when new collections are added
- Maintain backend: update packages when CVEs are disclosed

---

## EXPECTED DELIVERABLES

| Deliverable | Acceptance Criteria |
|---|---|
| Production APK | Signed with production keystore, correct package ID, passes Play Store pre-launch checks |
| Rate-limited backend | No route accepts >100 req/min from a single IP without rate limit response |
| Test suite | At least 15 widget/unit tests covering login, product listing, PO workflow |
| iOS build (if in scope) | App boots on iOS 16+ without crashes, all Firebase features working |
| FCM integration | Notifications delivered within 60 seconds of triggering event |
| Play Store submission | App live on internal testing track |

---

## EXPECTED WORKLOAD

**Full-time (40 hours/week)** for the first 3 months to clear the production blockers.

After launch, **part-time (20 hours/week)** is acceptable if the developer has other clients, provided they commit to a 24-hour response SLA for critical bugs.

---

## WHY THIS ROLE IS REQUIRED

1. **No code runs without a human**: Claude cannot sign APKs, submit to the Play Store, run `flutter build apk --release`, or respond to 3am production incidents.
2. **Security decisions require judgment**: Rotating credentials, setting Firestore rules for new features, and deciding when a backend change needs a security review.
3. **Testing requires implementation**: Claude can write test code but cannot run it, observe crashes, or iterate on a real device.
4. **Play Store requires a human account and physical submissions**.
5. **Production debugging requires live access**: Firebase Console, Crashlytics, Render logs — a human must read and act on these.
