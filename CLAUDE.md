# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**KrishiMithra** — a cross-platform agricultural app connecting farmers, exporters, labourers, and vendors. Flutter frontend + Node.js/Express backend in a monorepo.

## Commands

### Flutter Frontend

```bash
flutter pub get          # Install/update dependencies
flutter run              # Run on connected device/emulator
flutter analyze          # Static analysis
flutter analyze lib/some/module/   # Analyze a single module
flutter test             # Run all tests
flutter test test/foo_test.dart    # Run a single test
flutter gen-l10n         # Regenerate l10n after editing *.arb files
flutter build apk        # Android APK
flutter build web        # Web
```

### Node.js Backend (`km_backend/`)

```bash
npm install              # Install dependencies
npm run dev              # Dev server (nodemon, auto-reload, port 5000)
npm start                # Production (node server.js)
```

### Environment Setup

- Frontend: copy `.env.example` → `.env`, set `GEMINI_API_KEY`
- Backend: copy `km_backend/.env.example` → `km_backend/.env`, set `MONGODB_URI`, `CLOUDINARY_*`, `PORT`
- Supabase URL and anon key are hardcoded in `lib/main.dart` (not in `.env`)

## Architecture

### Entry Point & Routing

`lib/main.dart` — initializes Firebase, Supabase, dotenv, and `LocaleService`. The real `DashboardPage` (the old home, now superseded) and the login flow live here. The active home is `lib/home/home_page.dart` (`KrishiMithraHome` widget with a 5-tab `NavigationBar`).

### Module Layout (`lib/`)

Each feature module typically has: `*_page.dart` (UI), `*_service.dart` (Firestore/API), `*_model.dart` (data class).

| Module | Purpose | Key files |
|---|---|---|
| `home/` | Main tab host + home feed | `home_page.dart`, `home_search_page.dart` |
| `chatbot/` | RAG chatbot (KB → Gemini fallback) | `chatbot_page.dart`, `chatbot_service.dart`, `chat_repository.dart`, `search_engine.dart`, `chat_models.dart` |
| `exporter_hub/` | B2B export platform (primary) | `exporter_home_page.dart`, `exporter_service.dart`, `exporter_model.dart`, `po_detail_page.dart` |
| `export_hub/` | Legacy export module (do not extend) | `export_hub_page.dart` |
| `f2b_mart/` | Farm-to-buyer marketplace (GreenBazaar) | `f2b_home_page.dart`, `f2b_search_page.dart` |
| `plant_vendor/` | Plant/nursery marketplace | `plant_vendor_home.dart` |
| `rent/` | Farm equipment rental (Rapido-style) | `rent_home_page.dart` |
| `labour_hub/` | Labour hiring (UrbanCompany-style) | `labour_hub_home_page.dart` |
| `crop_disease/` | Disease detection via HuggingFace | `crop_disease_page.dart` |
| `weather/` | Weather forecast | `weather_page.dart` |
| `profile/` | User profile + settings | `profile_page.dart`, `profile_service.dart` |
| `exporter_hub/` | Also contains admin modules: | `warehouse_*.dart`, `shipment_*.dart`, `finance_dashboard.dart`, `ai_insights_page.dart`, `buyers_page.dart` |
| `services/` | Shared: image upload, locale, Supabase, translation | `image_upload_service.dart`, `locale_service.dart`, `content_translation_service.dart` |
| `l10n/` | Localization ARB files | `en`, `hi`, `kn`, `ta`, `te`, `mr` |
| `providers/` | `LocaleProvider` (Provider pattern) | `locale_provider.dart` |

### Design System (`lib/theme.dart`)

All new UI must use constants from `theme.dart`. Key exports:
- `KMColors` — `primary`, `primaryDark`, `textPrimary`, `textSecondary`, `backgroundDark`, `cardDark`, `textOnPrimary`
- `KMSpacing`, `KMRadius`, `KMShadow` — spacing, border radii, box shadows
- Reusable widgets in `lib/widgets/km_widgets.dart`: `KMSearchBar`, `KMNetworkImage`, `KMCard`, `KMCategoryChip`, `KMEmptyState`
- Use `.withValues(alpha:)` **not** `.withOpacity()` (deprecated)
- Font: Nunito (light theme) — do not add Montserrat

### State Management

- **Locale:** `LocaleProvider` + `LocaleService.instance` (singleton)
- **Auth:** `FirebaseAuth.instance.currentUser` accessed directly in pages; no global auth state wrapper
- **Feature state:** each page/service is self-contained; no Riverpod/Bloc/GetX

### Firestore Collections

| Collection | Purpose |
|---|---|
| `export_products` | Export Hub product listings |
| `purchase_orders` | POs with 13-step status workflow |
| `export_demand` | Demand board posts (admin-created) |
| `farmers` / `farmer_listings` | Legacy farmer data |
| `users` | User profiles; `role` field: `'farmer'` \| `'admin'` |
| `qc_reports` | Quality control reports |
| `labours` | Labour hub profiles |
| `plant_vendors` | Plant marketplace listings |
| `rent_machines` | Equipment rental listings |
| `rent_bookings` | Equipment booking orders |
| `km_chatbot/{uid}/conversations/{id}` | Chatbot conversation history |
| `warehouse_stock` | Warehouse inventory |
| `shipments` | Shipment tracking |

**PO status workflow (13 steps, in `po_detail_page.dart`):**
`draft → listed → under_review → price_negotiation → po_issued → farmer_accepted → collection_scheduled → collected → qc_pending → qc_approved → ready_for_export → exported`  
Rejection branches: `qc_rejected`, `rejected`, `cancelled`

### Role System (`exporter_hub/role_service.dart`)

`users/{uid}.role` = `'farmer'` (default) or `'admin'`. Admins see extra Operations Hub tiles: warehouse, shipments, finance, buyers, documents, AI insights. `RoleService` caches roles in-memory per session.

### Chatbot RAG Architecture (`lib/chatbot/`)

1. `chatbot_page.dart` loads `assets/knowledge_base/crops.json` + `crop_diseases.json` at init
2. `SearchEngine.search()` scores the query against `KnowledgeEntry` keywords (min score 0.18)
3. KB match + English → answer directly; KB match + other language → `getBotReplyWithContext()` (Gemini with KB hint)
4. No KB match → `getBotReply()` (pure Gemini)
5. Conversations persisted to Firestore via `ChatRepository`

### Localization

Add strings to all 6 ARB files (`lib/l10n/*.arb`), then run `flutter gen-l10n`. The generated `AppLocalizations` is accessed via `AppLocalizations.of(context)!`. Content translation (crop names, locations) is handled by `ContentTranslationService` (static lookup maps, no network call).

### Image Uploads

- Profile photos → Supabase storage via `ProfileService.uploadProfileImage()`
- Export product images → backend endpoint `POST https://km-backend-ug96.onrender.com/api/upload` via `ImageUploadService`
- Do not upload directly to Cloudinary from Flutter

### Backend (`km_backend/`)

Single responsibility: Multer → Cloudinary → MongoDB metadata. One route: `POST /api/upload`. The `km_backend/uploads/` directory is temp-only; files are deleted after Cloudinary upload.

## Key Conventions

- `export_hub/` is legacy — new export work goes in `exporter_hub/`
- The real `DashboardPage` was in `lib/main.dart` (now replaced by `home/home_page.dart`); `lib/dashboard_page.dart` at root is a broken legacy file — ignore it
- `createdAt` is always a Firestore `Timestamp` server-side; parse with `(v is Timestamp) ? v.toDate() : DateTime.tryParse(v.toString())`
- `ExportProduct.fromMap()` and `toMap()` are the canonical serialisation path — do not access Firestore maps directly
- `ExporterService.updatePOStatus()` appends to the `history` array — always use this method to change PO status, never `update({'status': ...})` directly
