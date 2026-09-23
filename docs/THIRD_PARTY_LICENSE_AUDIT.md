# Third-Party License Audit — KrishiMithra

**IMPORTANT:** This audit identifies licenses and commercial use restrictions. It does NOT constitute legal advice. Items flagged for review should be assessed by a qualified lawyer before commercial deployment.

*Sources: `pubspec.yaml` (Flutter), `km_backend/package.json` (Node.js backend)*

---

## FLUTTER / DART DEPENDENCIES

### HIGH ATTENTION — Review Required

| Package | Version | Purpose | License | Commercial Use | Risk | Action |
|---|---|---|---|---|---|---|
| `translator` | ^1.0.3+1 | Language translation | MIT | **Likely violates Google ToS** | **HIGH** | This package uses an undocumented Google Translate endpoint not intended for programmatic access. Google has blocked similar packages before. Commercial use is high risk. Replace with Google Cloud Translation API (paid, proper ToS) or DeepL API. |
| `google_mlkit_translation` | ^0.13.0 | On-device ML translation | MIT | **Review Google ML Kit ToS** | MEDIUM | Google ML Kit is free for mobile apps but has usage policy terms. Verify commercial use is permitted under current Google ML Kit terms. |
| `google_maps_flutter` | ^2.5.0 | Map display | Apache 2.0 | **Requires Google Maps Platform billing** | MEDIUM | Google Maps Platform requires a billing account and has free tier limits ($200/month credit). Exceeding the free tier incurs charges. Must have a billing account configured. |
| `google_fonts` | ^6.2.1 | Typography (Nunito font) | Apache 2.0 | Fonts have individual licenses | MEDIUM | Google Fonts serves open-source fonts. Nunito is licensed under OFL (Open Font License), which permits commercial use. Verify each font used is confirmed OFL. |
| `geolocator` | any (UNPINNED) | GPS/location | MIT | Yes | MEDIUM | Not a license issue — this is a dependency management risk. `any` version means any future breaking version can install. Pin to a specific version immediately (e.g., `^13.0.0`). |

### STANDARD — Permissive Licenses (Low Risk)

| Package | Version | Purpose | License | Commercial Use | Notes |
|---|---|---|---|---|---|
| `firebase_core` | ^3.0.0 | Firebase initialization | Apache 2.0 | Yes — check Firebase pricing | Firebase free tier (Spark plan) has limits. Blaze plan (pay-as-you-go) required for production scale. |
| `firebase_auth` | ^5.0.0 | Authentication | Apache 2.0 | Yes | |
| `cloud_firestore` | ^5.6.12 | Database | Apache 2.0 | Yes — check Firestore pricing | |
| `firebase_storage` | ^12.0.0 | File storage | Apache 2.0 | Yes | |
| `google_sign_in` | ^6.2.2 | OAuth sign-in | Apache 2.0 | Yes | Google sign-in is free |
| `flutter_localizations` | SDK | Localization | BSD-3-Clause | Yes | Part of Flutter SDK |
| `intl` | ^0.20.2 | Internationalization | BSD-3-Clause | Yes | |
| `provider` | ^6.0.5 | State management | MIT | Yes | |
| `http` | ^1.6.0 | HTTP client | BSD-3-Clause | Yes | |
| `http_parser` | ^4.0.0 | HTTP parsing | BSD-3-Clause | Yes | |
| `supabase_flutter` | ^2.0.6 | Supabase client | MIT | Yes — check Supabase pricing | Supabase free tier has limits |
| `image_picker` | ^1.0.4 | Camera/gallery access | Apache 2.0 | Yes | |
| `image_picker_for_web` | ^3.0.1 | Web file picker | BSD-3-Clause | Yes | |
| `file_picker` | ^10.2.0 | File selection | MIT | Yes | |
| `shared_preferences` | ^2.2.2 | Local key-value storage | BSD-3-Clause | Yes | |
| `uuid` | ^4.0.0 | UUID generation | MIT | Yes | |
| `flutter_svg` | ^2.0.7 | SVG rendering | MIT | Yes | |
| `oktoast` | ^3.3.1 | Toast notifications | MIT | Yes | |
| `flutter_typeahead` | ^5.2.0 | Search autocomplete | MIT | Yes | |
| `flutter_keyboard_visibility` | ^6.0.0 | Keyboard state | MIT | Yes | |
| `intl_phone_field` | ^3.1.0 | Phone number input | MIT | Yes | |
| `geocoding` | ^4.0.0 | Address → coordinates | MIT | Yes — uses platform geocoding APIs | Uses device's native geocoding, no additional cost |
| `url_launcher` | ^6.2.6 | Open URLs | BSD-3-Clause | Yes | |
| `flutter_map` | ^8.1.1 | Alternative map display | BSD-2-Clause | Yes | Uses OpenStreetMap tiles by default; OSM tile usage policy requires attribution |
| `latlong2` | ^0.9.0 | Lat/lon math | MIT | Yes | |
| `mime` | ^1.0.4 | MIME type detection | BSD-3-Clause | Yes | |
| `path` | ^1.8.3 | File path utilities | BSD-3-Clause | Yes | |
| `logging` | ^1.2.0 | Logging | BSD-3-Clause | Yes | |
| `cupertino_icons` | ^1.0.8 | iOS-style icons | MIT | Yes | |

### DEV DEPENDENCIES

| Package | Version | Purpose | License | Notes |
|---|---|---|---|---|
| `flutter_lints` | ^3.0.1 | Linting rules | BSD-3-Clause | Dev only, not in production |
| `flutter_launcher_icons` | ^0.14.3 | Icon generation | MIT | Dev only |

---

## NODE.JS BACKEND DEPENDENCIES (`km_backend/package.json`)

### Standard — Permissive Licenses

| Package | Version | Purpose | License | Commercial Use | Risk | Notes |
|---|---|---|---|---|---|---|
| `express` | ^5.2.1 | HTTP framework | MIT | Yes | LOW | Express 5.x is stable |
| `cors` | ^2.8.6 | CORS middleware | MIT | Yes | LOW | |
| `cloudinary` | ^2.10.0 | Image storage SDK | MIT | Yes — Cloudinary has pricing | LOW | Check Cloudinary plan limits |
| `mongoose` | ^9.6.1 | MongoDB ODM | MIT | Yes | LOW | |
| `multer` | ^2.1.1 | File upload middleware | MIT | Yes | LOW | |
| `firebase-admin` | ^14.3.0 | Firebase server-side SDK | Apache 2.0 | Yes | LOW | |
| `dotenv` | ^17.4.2 | Environment variables | BSD-2-Clause | Yes | LOW | |
| `nodemon` | ^3.1.14 | Dev auto-restart | MIT | Dev only | LOW | |

---

## THIRD-PARTY SERVICES (API USAGE)

| Service | Used For | License/ToS | Commercial Use | Risk | Action |
|---|---|---|---|---|---|
| **Firebase** (Google) | Auth, Firestore, Storage | Google ToS + Firebase Terms | Yes — with pricing limits | MEDIUM | Must be on Blaze plan (pay-as-you-go) for production; review data retention and deletion ToS |
| **Google Maps Platform** | Map display in app | Google Maps Platform ToS | Yes — with billing | MEDIUM | Enable billing account; $200/month free credit — monitor usage |
| **Cloudinary** | Image storage | Cloudinary ToS | Yes — with plan limits | LOW | Review storage and bandwidth limits on current plan |
| **Supabase** | Profile photo storage | Supabase ToS | Yes — with plan limits | LOW | Review storage limits |
| **Google Gemini API** | Chatbot (AI responses) | Google AI ToS | Review | MEDIUM | Verify commercial use terms for Gemini API; check whether API key is from Google AI Studio (free/limited) or Vertex AI (production-grade) |
| **HuggingFace API** | Crop disease detection | HuggingFace ToS | Review for commercial | MEDIUM | Verify the specific model's license (models have individual licenses) |
| **OpenStreetMap** | Map tiles via flutter_map | ODbL license | Yes — with attribution | LOW | Must display OSM attribution in any map view using OSM tiles |
| **Render** | Backend hosting | Render ToS | Yes | LOW | Review uptime guarantees for production use case |
| **MongoDB Atlas** | Secondary database | MongoDB Elastic License 2.0 (cloud service) | Yes — with plan limits | LOW | MongoDB Atlas cloud service is separate from the MongoDB database license |

---

## SUMMARY

| Risk Level | Count | Key Items |
|---|---|---|
| HIGH | 1 | `translator` package (unofficial Google API, ToS violation) |
| MEDIUM | 5 | `google_mlkit_translation` ToS, Google Maps billing, Gemini API commercial terms, HuggingFace model licenses, `geolocator: any` version pinning |
| LOW | 20+ | All other standard MIT/Apache/BSD packages |

**Immediate actions before production launch:**

1. Replace `translator` package with a properly licensed translation service
2. Confirm Google Maps billing account is configured
3. Pin `geolocator` to a specific version
4. Verify Gemini API key type (AI Studio vs Vertex AI) and commercial terms
5. Verify specific HuggingFace model licenses for commercial use
6. Ensure all map views using OpenStreetMap tiles include attribution

**Legal review recommended for:** Google ML Kit commercial use terms, Gemini API commercial terms, and the `translator` package replacement decision.
