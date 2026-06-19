# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**KrishiMithra** — a cross-platform agricultural technology app connecting farmers, exporters, laborers, and vendors. Built with Flutter (frontend) and Node.js/Express (backend) in a monorepo.

## Commands

### Flutter Frontend

```bash
flutter pub get          # Install/update dependencies
flutter run              # Run on connected device/emulator
flutter analyze          # Static analysis (uses analysis_options.yaml)
flutter test             # Run all tests
flutter test test/foo_test.dart  # Run a single test file
flutter build apk        # Android APK
flutter build ios        # iOS
flutter build web        # Web
```

### Node.js Backend (`km_backend/`)

```bash
npm install              # Install dependencies
npm run dev              # Development server (nodemon, auto-reload)
npm start                # Production server (node server.js, port 5000)
```

### Environment Setup

- Frontend: copy `.env.example` to `.env`, fill in `GEMINI_API_KEY`
- Backend: copy `km_backend/.env.example` to `km_backend/.env`, fill in `MONGODB_URI`, `CLOUDINARY_*`, and `PORT`

## Architecture

### Frontend (`lib/`)

Feature-based modules, each typically containing a `*_page.dart` (UI) and `*_service.dart` (business logic/API calls):

| Module | Purpose |
|---|---|
| `chatbot/` | AI chatbot via Gemini API |
| `crop_disease/` | Crop disease detection |
| `weather/` | Weather forecasting |
| `export_hub/` / `exporter_hub/` | Trading/export listings and purchase orders |
| `rent/` | Farm equipment rental and booking |
| `labour_hub/` | Labour hiring and requests |
| `plant_vendor/` | Plant marketplace |
| `profile/` | User profile management |
| `providers/` | Provider state management (locale) |
| `services/` | Shared services: image upload, locale, Supabase storage, LibreTranslate |
| `l10n/` | Localization ARB files (en, hi, kn, ta, te, mr) |

**Entry point:** `lib/main.dart` — initializes Firebase, Supabase, dotenv, and sets up routing and the `LocaleProvider`.

**State management:** Provider pattern via `LocaleProvider` for locale; individual services hold their own state.

**Theme:** Defined in `lib/theme.dart`, supports light/dark modes.

### Backend (`km_backend/`)

Minimal Express API following MVC-ish structure:

```
server.js         ← Express entry, CORS, route mounting
config/
  db.js           ← MongoDB Atlas connection (Mongoose)
  cloudinary.js   ← Cloudinary SDK configuration
routes/
  uploadRoutes.js ← POST /api/upload
controllers/
  uploadController.js
middleware/
  uploadMiddleware.js  ← Multer (multipart/form-data)
models/
  imageModel.js   ← Mongoose schema for uploaded image metadata
```

The backend has a single primary responsibility: accept image uploads via Multer, store them in Cloudinary, and persist metadata to MongoDB.

**Deployed backend URL:** `https://km-backend-ug96.onrender.com` (Render.com). The Flutter app references this URL for image upload calls.

### External Services

| Service | Used For |
|---|---|
| Firebase Auth | User authentication |
| Cloud Firestore | Primary app database |
| Firebase Storage | User file storage |
| Supabase | Secondary storage (`supabase_storage_service.dart`) |
| Google Maps / Geolocator | Location features |
| Google ML Kit Translation | On-device translation |
| LibreTranslate | Server-side translation fallback |
| Gemini API | Chatbot (key in frontend `.env`) |
| OpenWeather API | Weather data |
| MongoDB Atlas | Backend database |
| Cloudinary | Image CDN (via backend) |

## Key Conventions

- Localization strings live in `lib/l10n/*.arb`; run `flutter gen-l10n` after adding new strings (configured in `pubspec.yaml` under `flutter/generate: true`).
- Image uploads from the Flutter app should go through the backend endpoint (`/api/upload`), not directly to Cloudinary.
- The backend's `km_backend/uploads/` directory is for temporary Multer staging only — files are moved to Cloudinary and the local temp file is deleted.
