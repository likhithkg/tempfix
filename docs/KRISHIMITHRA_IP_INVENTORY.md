# KrishiMithra IP Inventory

**IMPORTANT LEGAL NOTICE:**  
This document is a technical inventory prepared from codebase inspection. It is NOT a legal determination of ownership. Every item marked "LEGAL/FOUNDER VERIFICATION REQUIRED" must be verified by a qualified Indian lawyer or Company Secretary before relying on this inventory for legal purposes.

*Prepared from codebase audit on 2026-09-23*

---

## A. SOURCE CODE

| Asset | Location | Created By | Original/Third-Party | License | Current Account Owner | Ownership Evidence | Risk | Action Required |
|---|---|---|---|---|---|---|---|---|
| Flutter frontend app | `lib/` (all .dart files) | NOT DETERMINED FROM CODEBASE — LEGAL/FOUNDER VERIFICATION REQUIRED | Claimed original | Proprietary (assumed) | NOT DETERMINED — LEGAL/FOUNDER VERIFICATION REQUIRED | Source code in git repository; git blame/log shows commit history | HIGH if created by previous developers without IP assignment | IP Assignment Agreement required from all contributors |
| Node.js backend | `km_backend/server.js`, routes, config, middleware | NOT DETERMINED FROM CODEBASE — LEGAL/FOUNDER VERIFICATION REQUIRED | Claimed original | Proprietary (assumed) | NOT DETERMINED — LEGAL/FOUNDER VERIFICATION REQUIRED | Git history | HIGH — same as above | IP Assignment Agreement required |
| Chatbot backend | `km_chatbot_backend/` | NOT DETERMINED FROM CODEBASE — LEGAL/FOUNDER VERIFICATION REQUIRED | Claimed original | Proprietary (assumed) | NOT DETERMINED — LEGAL/FOUNDER VERIFICATION REQUIRED | Git history | HIGH | IP Assignment Agreement required |
| Firebase security rules | `firestore.rules` | NOT DETERMINED FROM CODEBASE — LEGAL/FOUNDER VERIFICATION REQUIRED | Claimed original | Proprietary (assumed) | NOT DETERMINED — LEGAL/FOUNDER VERIFICATION REQUIRED | Git history | MEDIUM | Verify contributor list |
| Firestore indexes | `firestore.indexes.json` | NOT DETERMINED FROM CODEBASE — LEGAL/FOUNDER VERIFICATION REQUIRED | Claimed original | Proprietary (assumed) | NOT DETERMINED — LEGAL/FOUNDER VERIFICATION REQUIRED | Git history | LOW | Verify contributor list |
| L10n translations (ARB files) | `lib/l10n/*.arb` | NOT DETERMINED FROM CODEBASE — LEGAL/FOUNDER VERIFICATION REQUIRED | Claimed original (content), framework is third-party | Content proprietary; Flutter l10n framework: BSD-3 | NOT DETERMINED — LEGAL/FOUNDER VERIFICATION REQUIRED | Git history | MEDIUM | Verify who created the translations |
| Theme and design constants | `lib/theme.dart` | NOT DETERMINED FROM CODEBASE — LEGAL/FOUNDER VERIFICATION REQUIRED | Claimed original | Proprietary (assumed) | NOT DETERMINED — LEGAL/FOUNDER VERIFICATION REQUIRED | Git history | LOW | Verify contributor list |

---

## B. UI / DESIGN

| Asset | Location | Created By | Original/Third-Party | Risk | Action Required |
|---|---|---|---|---|---|
| App UI design (screen layouts, flows) | All `*_page.dart` files | NOT DETERMINED FROM CODEBASE — LEGAL/FOUNDER VERIFICATION REQUIRED | Claimed original | MEDIUM | Verify no licensed design template was used |
| KrishiMithra brand name | App name in `pubspec.yaml`, AndroidManifest | NOT DETERMINED FROM CODEBASE | Claimed original | HIGH if not registered | LEGAL/FOUNDER VERIFICATION REQUIRED — Consider trademark registration |

---

## C. LOGOS / ASSETS

| Asset | Location | Created By | Original/Third-Party | License | Risk | Action Required |
|---|---|---|---|---|---|---|
| `assets/km.png.png` (App icon) | `assets/km.png.png` | NOT DETERMINED FROM CODEBASE — LEGAL/FOUNDER VERIFICATION REQUIRED | Unknown | Unknown | HIGH | Verify ownership/license; obtain written record |
| `assets/log.png` (Login logo) | `assets/log.png` | NOT DETERMINED FROM CODEBASE — LEGAL/FOUNDER VERIFICATION REQUIRED | Unknown | Unknown | HIGH | Verify ownership/license |
| `assets/login_bg.png` | `assets/login_bg.png` | NOT DETERMINED FROM CODEBASE — LEGAL/FOUNDER VERIFICATION REQUIRED | Unknown | Unknown | HIGH | If from stock photo site, verify commercial license |
| `assets/leaves.png` | `assets/leaves.png` | NOT DETERMINED FROM CODEBASE — LEGAL/FOUNDER VERIFICATION REQUIRED | Unknown | Unknown | MEDIUM | Verify license |
| `assets/farmer_logo.png` | `assets/farmer_logo.png` | NOT DETERMINED FROM CODEBASE — LEGAL/FOUNDER VERIFICATION REQUIRED | Unknown | Unknown | MEDIUM | Verify license |
| Feature icons | `assets/icons/*.png` | NOT DETERMINED FROM CODEBASE — LEGAL/FOUNDER VERIFICATION REQUIRED | Unknown | Unknown | MEDIUM | If from icon library, verify commercial use license |
| `intl_phone_field` flag assets | `assets/packages/intl_phone_field/assets/flags/` | Third-party (intl_phone_field package) | Third-party | MIT (package license) | LOW | Covered by package license |

---

## D. KNOWLEDGE BASE / CONTENT

| Asset | Location | Created By | Original/Third-Party | Risk | Action Required |
|---|---|---|---|---|---|
| Crop knowledge base | `assets/knowledge_base/crops.json` | NOT DETERMINED FROM CODEBASE — LEGAL/FOUNDER VERIFICATION REQUIRED | Unknown | HIGH if copied from a licensed agricultural database | Verify original authorship or source |
| Crop disease knowledge base | `assets/knowledge_base/crop_diseases.json` | NOT DETERMINED FROM CODEBASE — LEGAL/FOUNDER VERIFICATION REQUIRED | Unknown | HIGH if copied from government or licensed source | Verify original authorship or source |

---

## E. DATABASE SCHEMAS

| Asset | Location | Defined By | Risk | Action Required |
|---|---|---|---|---|
| Firestore collection schemas | Implicit in `*_model.dart` files and security rules | NOT DETERMINED FROM CODEBASE — LEGAL/FOUNDER VERIFICATION REQUIRED | MEDIUM | Document schema design as original work in IP Agreement |
| MongoDB user schema | `km_backend/models/` (file path inferred) | NOT DETERMINED FROM CODEBASE — LEGAL/FOUNDER VERIFICATION REQUIRED | LOW | Include in IP Assignment Agreement scope |

---

## F. APIS AND BACKEND

| Asset | Location | Type | License / Terms | Risk | Action Required |
|---|---|---|---|---|---|
| KM Backend API (`km-backend-ug96.onrender.com`) | `km_backend/` | Original code deployed on Render | Proprietary | LOW — original code, well-structured | Include in IP Agreement |
| Backend URL | Hardcoded in Flutter source | NOT DETERMINED — URL may change | N/A | LOW | Document as company asset |

---

## G. INFRASTRUCTURE / ACCOUNTS

| Asset | Account Owner | Access Control | Risk | Action Required |
|---|---|---|---|---|
| Firebase project (`krishimithra-650c2`) | NOT DETERMINED — LEGAL/FOUNDER VERIFICATION REQUIRED | Firebase Console | HIGH if not under company control | Verify account is under company email, not personal email |
| MongoDB Atlas cluster (`krishimithra06`) | NOT DETERMINED — LEGAL/FOUNDER VERIFICATION REQUIRED | Atlas Console | HIGH | Verify account ownership |
| Cloudinary account (`dkifcgbho`) | NOT DETERMINED — LEGAL/FOUNDER VERIFICATION REQUIRED | Cloudinary Console | HIGH | Verify account ownership |
| Render account (backend hosting) | NOT DETERMINED — LEGAL/FOUNDER VERIFICATION REQUIRED | Render Console | MEDIUM | Verify account ownership |
| Supabase project (`ticpdepakqlizhdwgxtz`) | NOT DETERMINED — LEGAL/FOUNDER VERIFICATION REQUIRED | Supabase Console | MEDIUM | Verify account ownership |
| GitHub repository | NOT DETERMINED — LEGAL/FOUNDER VERIFICATION REQUIRED | GitHub | HIGH | Transfer to company GitHub Organisation if on personal account |
| Google Play Console | NOT DETERMINED — LEGAL/FOUNDER VERIFICATION REQUIRED | Google Console | HIGH | Must be under company account |
| Apple Developer (if applicable) | NOT DETERMINED — LEGAL/FOUNDER VERIFICATION REQUIRED | Apple Console | HIGH | Must be under company account |
| Domain / website | NOT DETERMINED FROM CODEBASE | Registrar | HIGH | Must be under company control |

---

## H. THIRD-PARTY LIBRARIES (See also THIRD_PARTY_LICENSE_AUDIT.md)

All third-party libraries in `pubspec.yaml` and `km_backend/package.json` are open-source with permissive licenses (MIT, Apache 2.0, BSD). The code built on top of them is separate from the libraries themselves.

**Risk:** Using the libraries does not transfer ownership of the application code. The application code is KrishiMithra's IP (subject to IP Assignment Agreements with contributors).

**One noted risk:** `translator: ^1.0.3+1` is an unofficial Google Translate API wrapper that may violate Google's Terms of Service. Legal review recommended.

---

## I. OVERALL RISK SUMMARY

| Risk Area | Level | Priority |
|---|---|---|
| Source code ownership (who wrote it) | HIGH | Immediate — IP Assignment Agreements |
| Logo and image assets (rights unclear) | HIGH | Immediate — establish or obtain license records |
| Knowledge base content origin | HIGH | Immediate — verify source |
| Firebase/MongoDB/Cloudinary account under company entity | HIGH | Immediate — verify and transfer if needed |
| Brand name (trademark) | HIGH | Consult trademark attorney |
| GitHub repository under company Organisation | HIGH | Transfer from personal to organisation account |
| Third-party library licenses | LOW-MEDIUM | Standard due diligence — see separate audit |

---

*REMINDER: This inventory is based on technical inspection of the codebase only. It is NOT a legal opinion. All HIGH-risk items require verification by a qualified Indian lawyer or Company Secretary.*
