# Developer Security Onboarding Architecture — KrishiMithra Private Limited

*This document defines exactly what access a developer receives, what the company retains, and how to revoke access cleanly when the engagement ends.*

---

## PRINCIPLE: MINIMUM NECESSARY ACCESS

A developer should receive only what is required to do their assigned work. They should never receive:
- Production credentials
- Owner-level access to any account
- The Firebase Admin SDK service account JSON
- The MongoDB Atlas master credentials
- Payment or billing account access

---

## ACCESS CONTROL TABLE

| System | Company Owner | Developer Access | Notes |
|---|---|---|---|
| **GitHub Repository** | Organisation Owner | Contributor (write to feature branches, cannot delete branches, cannot change settings) | Branch protection prevents direct push to main |
| **Firebase Console** | Founder account (Editor or Owner) | Editor on DEVELOPMENT project only | Production project: Viewer access maximum; never give service account JSON |
| **Firebase Authentication** | Founder | View only via console (no programmatic access) | Developer uses Firebase Emulator for local testing |
| **Firestore (Production)** | Founder | No direct access needed — rules are in code (deploy via Firebase CLI) | Developer submits rule changes via PR; founder deploys |
| **Firestore (Development)** | Founder | Read/Write on dev project | For testing only |
| **Firebase Admin SDK** | Stored in Render environment variables only | **NEVER** | The private key must never leave the hosting platform |
| **MongoDB Atlas** | Founder (Atlas owner) | Read access to a development database only | Production Atlas cluster: never share connection string |
| **Cloudinary** | Founder account | Access to development account only (separate from production) | If separate dev account is not feasible: read-only API key scoped to a dev folder |
| **Render (backend hosting)** | Founder account | Collaborator access to the specific service | Cannot access environment variables (where secrets live) |
| **Google Play Console** | Company account | Release Manager role (can submit builds, cannot manage billing or account settings) | Owner access is never shared |
| **Apple Developer** (if applicable) | Company account | Developer role | App Store Connect: Developer (not Admin) |
| **Supabase** | Founder account | Access to development project | Production Supabase project: Viewer only |
| **Domain registrar** | Founder account | No access | Not needed for development work |
| **Company email** | Founder | No access | Developer uses personal or KM-issued email |
| **Firebase Hosting** | Founder | Can deploy via Firebase CLI (dev environment only) | Production deploys reviewed and triggered by founder |
| **Gemini API Key** | In root `.env` (not in git) | **NEVER** | API is proxied through the backend; frontend should not hold the key |
| **HuggingFace API Key** | In backend `.env` (not in git) | **NEVER** | Same as above |

---

## GITHUB ORGANISATION STRUCTURE

```
KrishiMithra (GitHub Organisation)
├── krishimithra-app (private repository)
│   ├── main (branch-protected: require PR, require 1 approval)
│   ├── develop (integration branch)
│   ├── feature/android-package-rename
│   ├── feature/rate-limiting
│   └── release/v1.0.0
└── krishimithra-backend (optional: split if backend grows)
```

### Branch Protection Rules for `main`

- Require pull request before merging
- Require at least 1 approval (founder or technical reviewer)
- Dismiss stale reviews when new commits are pushed
- Do not allow force pushes
- Do not allow deletions
- Require status checks to pass before merging (add Flutter analyze at minimum)

### Developer GitHub Permissions

- Role: **Contributor** (can push to feature branches, create PRs, cannot change repository settings)
- Cannot: delete branches, change branch protection, transfer repository, add other collaborators
- Can: push to their assigned branches, create and update PRs, comment on code

---

## FIREBASE ACCESS ARCHITECTURE

### Development vs Production

The developer never touches the production Firebase project directly.

**Development Firebase Project** (create a separate one named e.g., `krishimithra-dev`):
- Developer has Editor access
- Developer uses Firebase Emulator Suite for local Auth + Firestore testing
- Firestore rules can be tested locally without deploying to production

**Production Firebase Project** (`krishimithra-650c2`):
- Developer has Viewer access maximum
- Firestore rule deployments: developer submits the rule changes via PR → founder reviews → founder deploys using `firebase deploy --only firestore:rules`
- The developer never has the admin credentials to deploy to production

### Firebase CLI Workflow for Developers

The developer uses Firebase CLI with **their own Firebase account** authenticated against the development project only:
```bash
firebase use krishimithra-dev
firebase emulators:start
```

They never need to run `firebase use krishimithra-650c2` (production) or `firebase deploy` to production.

---

## WHAT HAPPENS WHEN A DEVELOPER LEAVES

Execute the following in order, within the same day:

1. **GitHub:** Remove developer from organisation. All code already in the repository stays (it belongs to the company per IP Assignment Agreement).
2. **Firebase Console (Dev):** Remove developer's email from the development project.
3. **Firebase Console (Production):** Remove any Viewer access granted.
4. **MongoDB Atlas:** Remove any database user created for the developer.
5. **Render:** Remove developer's Collaborator access.
6. **Google Play Console:** Remove Release Manager role.
7. **Rotate credentials** if you have any reason to believe the developer stored any of the following: MongoDB connection string, Cloudinary API key/secret, Firebase Admin SDK key, Gemini API key, HuggingFace API key.
8. **Revoke GitHub personal access tokens** if the developer used any PAT.
9. **Audit recent git commits** for any committed secrets.
10. **Review recent Firestore rule changes** deployed to production.

---

## DEVELOPER ONBOARDING CHECKLIST

Before developer's first day:

- [ ] NDA signed and filed
- [ ] IP Assignment Agreement signed and filed
- [ ] GitHub organisation created (if not already)
- [ ] Repository transferred to organisation
- [ ] Developer added as Contributor (not Owner)
- [ ] Branch protection rules set on `main`
- [ ] Development Firebase project created
- [ ] Developer email added to development Firebase project with Editor role
- [ ] Development database credentials prepared (NOT production)

Day 1 handover (in a screen-share session):

- [ ] Walk through `docs/DEVELOPER_30_DAY_PLAN.md`
- [ ] Walk through `docs/CLAUDE_DEVELOPER_WORKFLOW.md`
- [ ] Confirm developer can clone the repository and run `flutter pub get`
- [ ] Confirm developer can run `flutter run` against development Firebase
- [ ] Confirm developer understands they must NEVER ask for production `.env` values
- [ ] Confirm developer understands the PR-only workflow

Never provide at onboarding (or at any time):

- [ ] Root `.env` (contains Gemini/HuggingFace keys)
- [ ] `km_backend/.env` (contains Firebase Admin SDK private key, MongoDB URI, Cloudinary secrets)
- [ ] Firebase Admin SDK service account JSON
- [ ] Production MongoDB Atlas connection string
- [ ] Google Play Console owner access
- [ ] Cloudinary production API key/secret

---

## CREDENTIAL ROTATION SCHEDULE

Rotate these credentials if: (a) a developer offboards, (b) a `.env` file was shared by accident, (c) you suspect a breach.

| Credential | Where to rotate | Impact of rotation |
|---|---|---|
| MongoDB Atlas password | Atlas → Database Access → Edit user | Update `MONGO_URI` in Render environment variables |
| Cloudinary API Secret | Cloudinary → Settings → Access Keys | Update `CLOUDINARY_API_SECRET` in Render |
| Firebase Admin SDK key | Firebase Console → Project Settings → Service Accounts → Generate new key | Update all Firebase Admin vars in Render, delete old key |
| Gemini API Key | Google AI Studio or Google Cloud Console | Update in root `.env` and Render if proxied |
| HuggingFace API Key | HuggingFace → Settings → Access Tokens | Update in `km_backend/.env` and Render |
| Supabase JWT secret | Supabase → Project Settings → API | Requires re-initializing the Supabase client in Flutter |

*Note: Rotating the Firebase Admin SDK key does NOT affect end users. It only affects the backend. The Flutter app uses the Firebase client SDK (firebase_options.dart), which is unaffected.*
