# Technical Test — KrishiMithra Developer Candidate

**Time limit:** 2–4 hours  
**Submission:** GitHub repository link (or zip file if preferred)  
**What to bring:** Your own Firebase project (free tier is fine), Flutter SDK, Node.js

*This test is based on the actual KrishiMithra technology stack. It does not require you to recreate the full application. It is designed to reveal whether you can read existing architecture, make a real change, and handle errors properly — not whether you can generate working code from scratch.*

---

## CONTEXT

KrishiMithra has a Node.js/Express backend deployed on Render. The backend currently has no rate limiting, which means any user can flood the API with requests. Your task has two parts: a Flutter task and a backend task.

---

## TASK 1 — FLUTTER: Location-Based Card Sort (90 minutes)

### Brief

Build a small standalone Flutter screen. **Do not build the full KrishiMithra app.** Create a new Flutter project and implement only this screen.

The screen shows a list of "farm listings" loaded from a mock JSON source (provided below). Each listing has a `lat`, `lon`, `name`, and `crop` field. The screen also reads the device's current location (use the `geolocator` package). The listings must be sorted by distance from the user's current location, nearest first.

Display each listing in a Card showing:
- Farm name
- Crop type
- Distance from user in kilometers (formatted to 1 decimal place: e.g., "3.2 km")

The distance calculation must use the Haversine formula or an equivalent (you may use a package). Do not fake the distance by sorting randomly.

### Mock data (embed this in your code)

```json
[
  { "id": "1", "name": "Ravi's Farm", "crop": "Tomato", "lat": 12.9716, "lon": 77.5946 },
  { "id": "2", "name": "Priya Agro", "crop": "Maize", "lat": 13.0827, "lon": 80.2707 },
  { "id": "3", "name": "Green Valley", "crop": "Wheat", "lat": 18.5204, "lon": 73.8567 },
  { "id": "4", "name": "Krishnappa Seeds", "crop": "Paddy", "lat": 15.3173, "lon": 75.7139 },
  { "id": "5", "name": "Sai Farm House", "crop": "Cotton", "lat": 17.3850, "lon": 78.4867 }
]
```

### Requirements

- Handle the case where location permission is denied (show a meaningful message, not a crash)
- Handle the case where location fetch times out (show a loading state, then an error)
- The list must update immediately when location is obtained
- Use Flutter's built-in `StatefulWidget` or `setState` — do not add GetX, Riverpod, or Bloc for this test
- No hard-coded lat/lon for "current location" — you must actually call `Geolocator.getCurrentPosition()`

### Expected output

A working Flutter app showing the sorted list. Distance is correct (verify by comparing to a map app).

---

## TASK 2 — BACKEND: Add Rate Limiting to Express API (60 minutes)

### Brief

You are given a minimal Express.js server (create it yourself, 30 lines maximum). Add rate limiting so that:

- Any single IP address can make at most **20 requests per minute** to any route
- When the limit is exceeded, the server returns HTTP 429 with JSON body: `{ "error": "Too many requests. Try again in 1 minute." }`
- The `/health` route is **exempt** from rate limiting (always returns 200)

### Starter server (create this yourself)

```javascript
const express = require('express');
const app = express();

app.use(express.json());

app.get('/health', (req, res) => res.json({ status: 'ok' }));
app.post('/api/data', (req, res) => res.json({ received: req.body }));
app.get('/api/users', (req, res) => res.json([{ id: 1, name: 'Test' }]));

app.listen(3000, () => console.log('Running on port 3000'));
```

### Requirements

- Use `express-rate-limit` package
- Rate limit applies per IP
- `/health` route must NOT be rate limited
- Submit a `package.json`, `server.js`, and a short test script (bash or node) that demonstrates hitting the limit

### Expected output

- Server code with rate limiting
- A way to verify it works (curl commands or a small test script)

---

## TASK 3 — SHORT ANSWER: Firestore Security (20 minutes)

Answer these questions in writing (not code). 3–4 sentences each.

**Q1:** In KrishiMithra's Firestore, the `export_products` collection allows public read (`allow read: if true`). What is the business reason this might be intentional, and what security risk does it create? How would you mitigate the risk while keeping public read?

**Q2:** The rule for `purchase_orders` allows read/update/delete if `uid() == resource.data.buyerId || uid() == resource.data.farmerId || isAdmin()`. A developer says: "We should just use `allow read, write: if isSignedIn()` instead — it's simpler." Why is this a bad idea? What would go wrong?

**Q3:** A new `saved_addresses` collection needs to be added. Each document is owned by one user and should only be readable/writable by that user. Write the Firestore security rule for this collection. (You may write the actual rule syntax.)

---

## EVALUATION CRITERIA

| Criterion | Weight | What we look for |
|---|---|---|
| Task 1: Does it run? | High | App compiles and renders without errors |
| Task 1: Location handling | High | Handles permission denied and timeout gracefully |
| Task 1: Distance sort accuracy | High | Sorting is correct, not faked |
| Task 1: Code organisation | Medium | Separation of concern, readable code |
| Task 2: Rate limiting works | High | 429 after 20 requests from same IP |
| Task 2: /health exempt | High | /health always returns 200 regardless of limit |
| Task 2: Test verification | Medium | Demonstrates working limit |
| Task 3: Q1 — business reasoning | Medium | Shows understanding of public data trade-offs |
| Task 3: Q2 — rule analysis | High | Understands why over-permissive rules are dangerous |
| Task 3: Q3 — rule syntax | High | Correct Firestore rule syntax, correct logic |

---

## COMMON FAILURE SIGNS

- **Location is hardcoded** to a city rather than using Geolocator — tells us they avoided the hard part
- **No permission handling** — app crashes on permission denied instead of showing a message
- **Rate limit does not actually stop requests** — they added the package but configured it incorrectly
- **/health is also rate limited** — they applied the limit globally without exemption
- **Task 3 answers are generic** — "add authentication" without explaining the specific Firestore rule issue
- **Q3 rule has `allow write: if isSignedIn()`** instead of checking the owner — common mistake revealing rule misunderstanding
- **Code submitted does not compile** — most basic failure
- **Entire project is AI-generated** and candidate cannot explain specific lines in the live review
- **Estimates wildly optimistic** — "I finished in 45 minutes" with incomplete or broken code
