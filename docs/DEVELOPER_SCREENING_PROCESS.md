# Developer Screening Process — KrishiMithra Private Limited

*9-stage process. Do not skip stages. Each stage eliminates candidates before the next begins.*

---

## STAGE 1 — RESUME SCREENING

**What to check:**

- Total years of Flutter/Dart experience (minimum 2 years)
- Names of apps they have actually shipped (not just built)
- Firebase listed as a skill (Auth, Firestore — not just "Firebase")
- Node.js or backend experience listed
- Git / GitHub mentioned
- Gaps in employment or project timeline that are unexplained
- No resume longer than 2 pages for a mid-level developer

**Questions to ask at this stage:** None — this is review only.

**What to request:** GitHub profile link. If they do not have one, reject immediately. You cannot evaluate a developer who does not show their code.

**Red flags:**

- "5+ years Flutter" from someone who graduated after 2021 (Flutter was released in 2018)
- Lists every framework ever created as a skill
- No specific app names, only vague "mobile apps"
- Resume appears auto-generated without any real project details
- Backend experience listed as "MySQL" or "PHP" only — does not match this stack

**Advance if:** 2+ years Flutter, at least one shipped app named, GitHub profile provided.

---

## STAGE 2 — GITHUB PORTFOLIO REVIEW

**What to check:**

- Do they have Flutter repositories with meaningful code (not just tutorials)?
- Do commits look like real development work (multiple commits per feature, meaningful messages)?
- Do they handle state, async operations, and errors properly in their code?
- Do their Firebase-related files show understanding of Firestore structure?
- Is there a `.gitignore` in their projects? Do they accidentally commit `.env` files?
- Code style: is it consistent? Are there obvious code smells?

**What evidence to request:**

- Ask them to link to one specific file or feature in their GitHub that they are most proud of
- Ask them to explain what it does in 3 sentences — this reveals if they actually wrote it

**Red flags:**

- Only forked repositories — no original code
- Commits like "fix stuff", "done", "update" — no meaningful history
- Single mega-commit with entire codebase — never developed incrementally
- No error handling anywhere in their code
- Hard-coded credentials in any repository
- Entire app in `main.dart` — no code organisation
- All code appears AI-generated (uniform style, no comments, overly perfect structure with no real debugging evidence)

**Advance if:** At least 2 Flutter repositories with real code. Able to explain one specific file they wrote.

---

## STAGE 3 — TECHNICAL PHONE SCREEN (30 minutes)

**Purpose:** Qualify communication, motivation, and basic competence before investing time in a full technical interview.

**What to ask:**

1. Walk me through the last Flutter app you shipped. What was your exact role? What did you build?
2. Have you ever submitted an app to Google Play Store yourself? Walk me through the steps you took.
3. Have you worked with Firestore before? Describe the data structure you used in a recent project.
4. Have you ever debugged a crash that happened only in release mode but not debug mode? What did you do?
5. Tell me one technical decision you made in a previous project that you would make differently today.

**Red flags:**

- Cannot name the specific Firestore collections they used in their project
- Describes the Play Store submission process vaguely ("just upload the APK")
- Has never encountered a release-mode-only crash — they may not have done real production work
- Defensive about past mistakes — good developers learn from errors and can articulate them

**Advance if:** Answers are specific, not generic. Can name exact tools, files, and decisions. Comfortable admitting things they would do differently.

---

## STAGE 4 — KRISHIMITHRA-SPECIFIC TECHNICAL TEST

**See `DEVELOPER_TECHNICAL_TEST.md` for the full test specification.**

**What to check after test submission:**

- Was the task completed or partially completed?
- Does the code actually run?
- Is the code their own or AI-generated wholesale? (Ask them to explain specific lines live)
- Did they handle errors or just the happy path?
- Did they ask reasonable clarifying questions during the test, or no questions at all?
- Time taken vs time estimate: did they estimate accurately?

**Red flags:**

- Submits code that does not compile
- No error handling in submitted code
- Cannot explain specific lines when asked
- Claims it took 1 hour for a 3-hour test with full, perfect output — probable AI copy

**Advance if:** Code runs, handles edge cases, and they can explain every line.

---

## STAGE 5 — LIVE CODE REVIEW (45 minutes)

**Purpose:** Have them walk you through their technical test submission while you ask specific questions.

**What to do:**

- Pick 5 specific lines or sections from their test submission
- Ask: "Why did you write it this way?" for each
- Ask: "What would happen if the user's internet dropped here?"
- Ask: "How would you test this function?"
- Show them a deliberately broken version of a function from the test — ask them to spot the bug

**What evidence to request:**

- Screen-share session so you can see them navigate the code live
- Ask them to make one small change live to verify they can edit the code in real time

**Red flags:**

- Stumbles on their own code, clearly did not write it
- Cannot read error messages or explain what an exception means
- Refuses to screen-share or makes excuses
- Gives only theoretical answers, cannot navigate actual code

**Advance if:** Fluent in their own code. Handles live questions confidently.

---

## STAGE 6 — PAID TRIAL TASK (1 week)

**Purpose:** The most reliable signal. Pay them to do a real, bounded task on a non-production codebase.

**What to give them:**

- A clone of the development branch (NOT main, NOT production credentials)
- A development Firebase project (NOT the production project)
- A clear, written brief with acceptance criteria
- A fixed budget for the week

**What task to assign:**

Choose from:
- Add rate limiting to the Node.js backend (express-rate-limit, test with a script)
- Write 10 widget tests for the login flow and one key module
- Rename the Android package ID in a test fork and verify the app still builds

**What to evaluate:**

- Did they deliver against the written acceptance criteria?
- Did they communicate blockers early or go silent?
- Is the code quality consistent with what they showed in the interview?
- Did they ask questions when stuck, or waste days going in the wrong direction?
- Did they touch anything outside the brief (a sign of overreach or poor scope judgment)?

**Red flags:**

- Silent for days without communication
- Delivers code that does not match the brief
- Asks for production credentials "just to test"
- Significantly overruns the time estimate without warning

**Advance if:** Delivered against acceptance criteria. Communicated clearly. Code matches their interview quality.

---

## STAGE 7 — FINAL INTERVIEW (30 minutes)

**Purpose:** Culture fit, expectations alignment, and commitment check.

**What to ask:**

1. What aspects of this project interest you most? What worries you?
2. How do you prefer to communicate when you're stuck — call, message, document?
3. What does your current availability look like for the next 3 months?
4. If you find a security vulnerability, what do you do first?
5. Under what circumstances would you push directly to main?

**What the right answers sound like:**

- Interested in the agricultural/social impact angle, specific module they want to work on
- Direct communicator, not silent when blocked
- Honest about availability constraints
- Reports security vulnerabilities immediately to the company, not fixes silently
- Never pushes to main directly — always a PR

**Red flags:**

- Vague about availability or commitment
- Views security issues as embarrassing to report
- Says "I'd just fix the security issue and push it" — no review process
- Seems uninterested in the domain

---

## STAGE 8 — CONTRACT / NDA / IP ASSIGNMENT

**This step must happen BEFORE any code access is granted.**

**What must be signed:**

1. **NDA** — covering all proprietary business information
2. **IP Assignment Agreement** — all code written during engagement is assigned to KrishiMithra Private Limited
3. **Employment Agreement OR Consultant Agreement** (depending on engagement type)
4. **Confidentiality clause** — cannot share codebase, credentials, data with third parties

**Important:**

- Have a lawyer review these documents. Do not use templates from the internet without legal review.
- The developer must sign BEFORE receiving access to any repository, Firebase project, or credential.
- Keep signed copies in the company's records.

See `LEGAL_REVIEW_CHECKLIST.md` for the full legal document checklist.

---

## STAGE 9 — CONTROLLED ONBOARDING

**What to do:**

1. Grant GitHub access as Contributor (NOT Owner) to specific repository only
2. Provide development Firebase project credentials (NOT production)
3. Set up branch protection: all changes via PR, require 1 approval (founder's), no direct push to main
4. Share `docs/DEVELOPER_30_DAY_PLAN.md` as their Week 1 roadmap
5. Share `docs/CLAUDE_DEVELOPER_WORKFLOW.md` so they understand how to work with Claude
6. Do NOT share: production `.env` files, MongoDB Atlas master credentials, Firebase Admin SDK private key, Cloudinary API secret, Google Play Console owner access

**First week check-in:**

- Does their development environment run the app?
- Have they read and understood the codebase architecture?
- Can they explain the module structure without being prompted?
- Have they raised any questions or concerns about the codebase?

**Red flags at onboarding:**

- Asks for owner-level GitHub access "for convenience"
- Asks for the Firebase production service account JSON
- Asks for the production MongoDB connection string "to test"
- Goes silent for more than 2 days without communication
