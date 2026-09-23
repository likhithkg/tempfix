# Legal Review Checklist — KrishiMithra Private Limited

**⚠ LAWYER / COMPANY SECRETARY REVIEW REQUIRED**

This checklist identifies the legal documents and actions needed to protect KrishiMithra's intellectual property, control developer relationships, and ensure compliance. This document itself does NOT create any legal rights, ownership, or protection. Every item must be reviewed and implemented by a qualified Indian lawyer or Company Secretary.

*Prepared for founder reference — 2026-09-23*

---

## SECTION 1 — BEFORE HIRING ANY DEVELOPER

### 1.1 Non-Disclosure Agreement (NDA)

- [ ] Draft a mutual or one-sided NDA (as appropriate)
- [ ] Covers: source code, product design, user data, business plans, customer lists, financial information
- [ ] Includes: definition of confidential information, permitted use, return/deletion of materials on termination, survival clause (NDA obligation survives end of engagement)
- [ ] Duration: specify duration (2–5 years is typical in India)
- [ ] Jurisdiction: India, specify state for dispute resolution
- [ ] **Signed BEFORE any codebase access is granted**

### 1.2 IP Assignment Agreement

- [ ] All code, designs, documentation, and other work product created during the engagement are assigned to KrishiMithra Private Limited
- [ ] Covers work done using company resources AND work done on personal time if related to company business
- [ ] Includes inventions, improvements, and derivatives
- [ ] Developer waives moral rights to the extent permitted by Indian law
- [ ] Assignment takes effect immediately upon creation (not only at termination)
- [ ] **Signed BEFORE any codebase access is granted**

### 1.3 Employment Agreement OR Consultant Agreement

Determine engagement type with legal counsel before hiring:

**If Full-Time Employee:**
- [ ] Employment Agreement compliant with Indian labour law (applicable state)
- [ ] Probation period defined
- [ ] Notice period defined
- [ ] Work hours and leave policy
- [ ] Termination conditions
- [ ] IP and NDA clauses incorporated or referenced

**If Freelancer / Contractor:**
- [ ] Consultant Agreement (not employment — misclassification risk must be assessed by lawyer)
- [ ] Deliverables-based scope (not hours-based employment)
- [ ] IP ownership clearly stated as KrishiMithra's
- [ ] Invoicing and payment terms
- [ ] Either party's right to terminate with notice
- [ ] No employer-employee relationship clause

### 1.4 Source Code Ownership Clause

- [ ] Explicitly states that all source code produced, modified, or delivered during the engagement is the exclusive property of KrishiMithra Private Limited
- [ ] Covers code written with AI assistance (e.g., Claude, Copilot)
- [ ] Covers code based on open-source libraries (the application code is the company's; third-party libraries remain under their own licenses)
- [ ] Developer has no right to use, copy, or reference the code after termination

---

## SECTION 2 — DURING THE ENGAGEMENT

### 2.1 Data Protection and Confidentiality

- [ ] Developer may access user data only for debugging purposes, never for personal use
- [ ] Developer must not extract, copy, or store user PII (personally identifiable information)
- [ ] Specify compliance with Information Technology Act 2000 and IT (Amendment) Act 2008 (India)
- [ ] If app collects sensitive personal data (location, biometrics, financial), assess obligations under DPDP Act 2023 (India's Digital Personal Data Protection Act)
- [ ] Privacy Policy for the app must be reviewed by a lawyer before Play Store submission

### 2.2 Access Revocation Obligations

- [ ] Developer agrees to immediately cease using all access (GitHub, Firebase, etc.) upon termination
- [ ] Developer agrees to return or delete all company materials (code copies, documentation, credentials stored locally) within a specified period (e.g., 7 days)
- [ ] Agreement allows the company to audit compliance with this obligation

### 2.3 Non-Solicitation (Evaluate with Lawyer)

- [ ] Whether to include a clause preventing the developer from soliciting KrishiMithra's users, employees, or investors for a defined period after termination
- [ ] Indian courts have varying enforcement of non-compete clauses — lawyer to advise on what is enforceable

---

## SECTION 3 — EXISTING CODEBASE OWNERSHIP

### 3.1 Prior Contributors

- [ ] Identify all individuals who contributed code to the existing codebase (use `git log --all --author` to get the contributor list)
- [ ] For each contributor: obtain a signed IP Assignment Agreement or verify that their original agreement covered this work
- [ ] If any contributor refuses or cannot be located: legal risk assessment required
- [ ] **DO NOT assume code in a git repository is owned by the company without assignment agreements from all contributors**

### 3.2 Third-Party and Open Source Components

- [ ] All third-party libraries listed in `THIRD_PARTY_LICENSE_AUDIT.md` must be reviewed for commercial use compliance
- [ ] Specifically: `translator` package (unofficial Google API — likely ToS violation) must be replaced before commercial launch
- [ ] `google_maps_flutter` requires a billing account — verify account is configured and terms reviewed
- [ ] All asset images, icons, and graphics must have documented ownership or license records

---

## SECTION 4 — COMPANY ACCOUNTS AND INFRASTRUCTURE OWNERSHIP

### 4.1 Account Ownership Verification

Verify that each of the following is registered to or transferable to KrishiMithra Private Limited:

- [ ] Firebase project (`krishimithra-650c2`) — verify Google account is company-controlled
- [ ] MongoDB Atlas account — verify email ownership
- [ ] Cloudinary account — verify email ownership
- [ ] Render account (backend hosting) — verify email ownership
- [ ] Supabase account — verify email ownership
- [ ] GitHub organisation — create and verify company organisation
- [ ] Google Play Console — verify it is under the company entity (not personal developer account)
- [ ] Apple Developer account (if applicable) — verify company enrollment
- [ ] Domain name registrar account — verify company ownership and renewal control

### 4.2 What Happens if a Personal Account Holds Company Assets

If any of the above accounts are under a personal email and the relationship with that person ends, the company could lose access to its own infrastructure. A lawyer should advise on:
- Transfer of accounts to company entity
- Letter of authorization or assignment of accounts
- Risk mitigation if transfer is not immediately possible

---

## SECTION 5 — PLAY STORE AND APP STORE COMPLIANCE

- [ ] Google Play Developer Distribution Agreement — reviewed
- [ ] Google Play data safety section — accurate and reviewed (required before submission)
- [ ] Privacy Policy — publicly accessible URL required; reviewed by lawyer
- [ ] Terms of Service for the app — reviewed by lawyer
- [ ] Age rating / content rating — ensure appropriate rating for agricultural content
- [ ] DPDP Act 2023 compliance for data collected in the app (location data, farm data, user profiles)

---

## SECTION 6 — TERMINATION PROVISIONS

- [ ] What happens to code in progress at time of termination — company retains all work product regardless of completion state
- [ ] What happens to local copies on developer's machine — must be deleted and confirmed
- [ ] What happens to credentials the developer was given — immediately revoked (see `DEVELOPER_SECURITY_ONBOARDING.md`)
- [ ] What happens to GitHub access — immediately revoked
- [ ] Dispute resolution clause — specify arbitration vs litigation, jurisdiction

---

## SECTION 7 — INTELLECTUAL PROPERTY PROTECTIONS TO CONSIDER

These are not required for launch but are recommended for protection:

- [ ] **Trademark registration** for "KrishiMithra" name and/or logo — consult a trademark attorney
- [ ] **Copyright registration** for original software — optional in India but provides a public record of creation date
- [ ] **Design registration** for distinctive UI elements — optional, consult IP attorney

---

## REMINDER

This checklist identifies what needs legal attention. It does NOT:
- Create any legal protection by itself
- Constitute legal advice
- Replace a qualified Indian lawyer's review

**Every item above that affects legal rights, ownership, or liability must be reviewed and executed with the guidance of a qualified lawyer or Company Secretary.**

---

*Prepared for informational purposes as part of technical due diligence. Not a substitute for legal counsel.*
