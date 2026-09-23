# Developer Red Flag Checklist — KrishiMithra

*Use this during every screening stage. One red flag is a note. Two red flags is a caution. Three or more is a rejection.*

---

## RESUME / GITHUB RED FLAGS

| Red Flag | Why It Matters |
|---|---|
| No GitHub profile or all forked repositories | Cannot demonstrate original work |
| "5+ years Flutter" from someone who graduated after 2020 | Flutter was released in 2018; claims cannot add up |
| Lists every framework and language as expert | Real developers specialise; generalists at interview depth usually know nothing well |
| No named apps with specific contributions | Vague "mobile apps" without details suggests inflated resume |
| Single large commit per project | Never developed incrementally; likely copied or generated code |
| Committed `.env` files or API keys in any public repo | Fundamental security carelessness |
| Commit messages like "fix", "update", "done" | Either no discipline or hiding a messy history |
| Resume is 4+ pages for someone with under 5 years experience | Padding |
| Employment dates have unexplained 12+ month gaps | Ask directly — not automatically disqualifying, but must be explained |
| Claims to have built apps identical to major products (e.g., "built an app like Swiggy") as a solo developer in 3 months | Not credible |

---

## INTERVIEW RED FLAGS

| Red Flag | Why It Matters |
|---|---|
| Cannot name specific Firestore collections or data structures from their previous project | They did not build it |
| Describes Play Store submission as "just upload the APK" | Has never actually done it |
| Claims they have never encountered a bug in their production app | Not credible — every production app has bugs |
| Cannot explain what `BuildContext` is | Junior-level gap in a candidate claiming mid-level experience |
| Cannot explain why Firestore rules matter | Will introduce security vulnerabilities |
| When asked about error handling, gives only theoretical answers | Has never debugged production issues |
| Defensive or evasive when asked about past mistakes | Good developers learn from errors and discuss them openly |
| Claims to know a skill listed on resume but cannot answer a basic question about it | Resume inflation |
| Cannot explain the difference between Firebase client SDK and Firebase Admin SDK | Will request the service account JSON (security risk) |
| Gives identical answers to every scenario question ("I would check the logs") without specifics | Generic answers signal no real depth |

---

## CREDENTIAL / ACCESS RED FLAGS (CRITICAL)

These red flags indicate a potential security risk, not just incompetence.

| Red Flag | Immediate Action |
|---|---|
| Asks for the Firebase service account JSON before starting | Explain how to use Firebase Emulator. If they insist, do not hire. |
| Asks for the production MongoDB connection string "just to test" | Provide a development database. If they push back, do not hire. |
| Wants owner-level GitHub access | Offer Contributor access. If they refuse to work without owner access, do not hire. |
| Asks for the Google Play Console owner email/password | Share the specific app with "Release Manager" access only. Full owner is never shared. |
| Asks to "just push directly to main this once" | Never acceptable. The branch protection rule exists for a reason. |
| Suggests that the NDA or IP agreement is unnecessary for a "quick test" | The agreement must be signed before any code access. No exceptions. |
| Shares code snippets from your codebase in a public forum, Stack Overflow, or AI tool | Immediate termination of engagement. |

---

## CODE QUALITY RED FLAGS (IN TEST AND TRIAL)

| Red Flag | Why It Matters |
|---|---|
| Submitted code does not compile | The minimum standard is that code runs |
| No error handling anywhere — only happy path coded | Not production-ready; will cause crashes |
| Hard-coded strings in place of localized strings | Will break multilingual support |
| Direct Firestore access in UI widgets (no service layer) | Architecture violation; makes testing impossible |
| Entire test submission written in a single `main.dart` or single file | No code organisation; cannot be maintained |
| Uses `dynamic` type everywhere in Dart | Bypasses type safety; hides bugs |
| No `dispose()` of Controllers or subscriptions | Memory leaks in production |
| Cannot explain why they wrote something a specific way | Did not write it themselves |
| Significant style inconsistency between different parts of submission | Multiple people or AI tools wrote different sections |
| Uses `setState` inside `Future.then()` without mounted check | Causes production crashes on slow networks |

---

## BEHAVIOURAL RED FLAGS

| Red Flag | Why It Matters |
|---|---|
| Goes silent for 2+ days without communication during trial | Cannot work independently; or is working multiple jobs and will deprioritise this one |
| Refuses the paid trial task ("I already showed my skills in the test") | The trial task is non-negotiable — it is the most reliable signal |
| Constantly asks for extensions with new excuses | Poor time estimation or overcommitment |
| Claims the brief was unclear when the brief was specific | Either didn't read it or avoiding accountability |
| Takes on tasks outside their brief without informing you | Poor scope judgment; risk of accidental damage to production |
| Discusses your codebase or business plans with others without authorisation | IP risk |
| Pushes for equity or co-founder status very early | Misaligned expectations; evaluate carefully |

---

## POSITIVE SIGNALS (WHAT TO LOOK FOR)

These signals indicate a strong candidate:

| Positive Signal | Why It Matters |
|---|---|
| Can name the exact Firestore collection names, document structure, and security rules from their last project | They designed it themselves |
| Has a Flutter app live on the Play Store that you can download and test | Most reliable signal of production experience |
| Asks clarifying questions during the technical test | Real developers know what they don't know |
| Submits code with `// why` comments explaining non-obvious decisions | Thoughtful developer who communicates through code |
| Points out a security or architecture issue in the brief without being asked | Initiative and technical awareness |
| Estimates accurately — if they say 3 hours, they finish in 3 hours | Professional discipline |
| Voluntarily mentions what they would improve if they had more time | Self-aware about trade-offs |
| Has dealt with a production incident and can walk through what they did | Real operational experience |
| Has contributed to open source (even small fixes) | Comfortable reading unfamiliar code |
| Asks about the `.env` file handling before asking for credentials | Security-aware instinct |
| Has experience with Indian regional language Flutter apps | Directly relevant to KrishiMithra |
| Has built or worked on a marketplace, booking system, or multi-role app | Directly transferable experience |
