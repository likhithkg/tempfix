# Claude + Developer + Founder Workflow — KrishiMithra

*This document defines who does what, to prevent confusion, duplication, and overreach.*

---

## THE THREE ROLES

### FOUNDER
Business owner, product decision-maker, company account holder.

**Controls:**
- Product roadmap and feature priorities
- All production accounts and credentials (Firebase, MongoDB, Cloudinary, Play Console)
- Final approval on all PRs that affect production behaviour
- IP and legal decisions
- Hiring, firing, and contractor agreements
- Budget and cost decisions (API pricing, hosting upgrades)

**Does NOT:**
- Write production code (unless a developer)
- Grant production credentials to developers or Claude
- Merge PRs without review

---

### HUMAN DEVELOPER
Technical executor. Implements, debugs, tests, and deploys.

**Does:**
- Reads and understands the existing codebase before changing anything
- Implements features from written specifications
- Debugs issues using device logs, Firebase Console, Render logs
- Writes tests for implemented features
- Submits all code via Pull Request (never directly to main)
- Sets up release builds and Android signing
- Responds to production incidents within agreed SLA
- Updates dependencies responsibly (test before updating)
- Documents non-obvious decisions in code or PR descriptions

**Does NOT:**
- Make product decisions without founder approval
- Access production credentials beyond what is granted
- Deploy to production without founder review
- Commit to main directly
- Share any part of the codebase with third parties

---

### CLAUDE (AI Engineering Assistant)
Code analysis, implementation guidance, and productivity tool.

**Does:**
- Reads and explains existing code
- Writes new code from a clear specification
- Refactors code while preserving behaviour
- Generates widget tests and unit tests
- Analyzes Firestore security rules for logical gaps
- Reviews pull request diffs for correctness
- Generates documentation (like this document)
- Helps debug issues by reading error messages and logs
- Suggests architecture patterns appropriate to the existing codebase
- Translates between languages for ARB localization strings

**Does NOT:**
- Execute code (cannot run `flutter build`, `firebase deploy`, or `git push`)
- Hold legal ownership of any code it generates
- Store or remember credentials between sessions
- Make business decisions
- Replace a developer for tasks requiring physical device testing, signing, or Play Store submission
- Replace a lawyer for IP, contract, or compliance questions

---

## WORKFLOW: FEATURE DEVELOPMENT

```
FOUNDER → writes product requirement (what the feature should do and why)
    ↓
CLAUDE → reads requirement + codebase, produces implementation plan
    ↓
FOUNDER → reviews plan, approves or adjusts
    ↓
DEVELOPER → creates feature branch, implements guided by plan + Claude assistance
    ↓
CLAUDE → reviews developer's implementation diff on request, flags issues
    ↓
DEVELOPER → addresses review feedback, writes tests
    ↓
DEVELOPER → submits Pull Request
    ↓
FOUNDER (+ Claude on request) → reviews PR
    ↓
FOUNDER → approves and merges
    ↓
DEVELOPER → deploys to staging/dev, tests
    ↓
FOUNDER → approves production deployment
    ↓
DEVELOPER → executes production deployment
```

---

## WORKFLOW: BUG INVESTIGATION

```
BUG REPORTED (by founder, user, or monitoring)
    ↓
DEVELOPER → reproduces bug, collects logs (Logcat / Render logs / Firebase Console)
    ↓
DEVELOPER asks CLAUDE → "Here is the error message and the relevant code. What could cause this?"
    ↓
CLAUDE → analyses the code and error, suggests likely causes and fixes
    ↓
DEVELOPER → applies fix on a bug-fix branch, tests
    ↓
DEVELOPER → submits PR with fix description
    ↓
FOUNDER → approves
    ↓
DEVELOPER → deploys
```

---

## WORKFLOW: SECURITY CONCERN

```
SECURITY CONCERN IDENTIFIED (by developer, Claude, or external report)
    ↓
DEVELOPER → reports to FOUNDER immediately (do not fix silently and push)
    ↓
FOUNDER → decides severity (can consult Claude for technical assessment)
    ↓
If HIGH severity → assess whether production system needs immediate action
    ↓
FOUNDER → may rotate credentials, restrict access, or revert a deployment
    ↓
DEVELOPER → fixes in a private branch
    ↓
FOUNDER → reviews fix (can ask Claude to verify)
    ↓
FOUNDER → deploys fix
    ↓
FOUNDER → documents the incident
```

---

## WHAT CLAUDE CAN HELP WITH TODAY

| Task | Claude Capability |
|---|---|
| Explain how a module works | Full — can read and explain all code |
| Write a new widget from spec | Full |
| Write a Firestore security rule | Full — but developer must test it |
| Review a Firestore rule for security gaps | Full |
| Write unit or widget tests | Full — but developer must run them |
| Analyze a crash stack trace | Full — give Claude the stack trace |
| Rename Android package ID | Full — generates the diff, developer executes |
| Add rate limiting to Express backend | Full — generates the code, developer tests |
| Write ARB localization strings | Full — generates all 6 language strings |
| Review a PR diff | Full — paste the diff and ask for review |
| Estimate task complexity | Good — with codebase context |
| Debug a location sorting bug | Good — needs the actual data and code |
| Understand Firestore billing | Good — from training knowledge |
| Sign a production APK | Cannot — requires physical execution |
| Run `flutter analyze` | Cannot — but developer should run this daily |
| Push to GitHub | Cannot |
| Access Firebase Console | Cannot |
| Make a legal determination | Cannot — requires lawyer |

---

## PRACTICAL DAILY WORKFLOW

**Developer's morning:**
1. Pull latest from `develop` branch
2. Run `flutter analyze` — fix any new warnings before starting
3. Check yesterday's open tasks in GitHub Issues or the agreed tracker
4. If stuck on something, paste the relevant code + error into Claude and ask

**Developer submitting a PR:**
1. Self-review the diff first — remove debug prints, check error handling
2. Run the relevant tests
3. Paste the diff into Claude: "Review this PR for correctness and any obvious issues"
4. Address Claude's feedback, then submit to GitHub

**Founder reviewing a PR:**
1. Read the PR description — does it match the requirement?
2. If technically complex, paste the diff into Claude: "Does this implementation look correct for X requirement?"
3. Approve or request changes

---

## OWNERSHIP CLARITY

| Asset | Owner |
|---|---|
| All code written by the developer | KrishiMithra Private Limited (per IP Assignment Agreement) |
| All code suggested or generated by Claude | KrishiMithra Private Limited (Anthropic's terms assign code ownership to the user) |
| All production accounts | KrishiMithra Private Limited |
| The application IP | KrishiMithra Private Limited (subject to legal documentation) |
| Claude (the AI tool) | Anthropic — licensed to the company for use, not owned |

---

## ESCALATION MATRIX

| Situation | Who Decides |
|---|---|
| Feature scope change | Founder |
| Bug severity classification | Developer + Founder |
| Production deployment timing | Founder |
| Credential rotation | Founder |
| Dependency upgrade that changes behaviour | Developer (with Founder awareness) |
| Hiring a second developer | Founder |
| Suspicion of a security breach | Founder — immediate action |
| Developer requesting access beyond what's granted | Founder — evaluate and respond in writing |
