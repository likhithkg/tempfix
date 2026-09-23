# Interview Questions — KrishiMithra Developer Candidates

*Use these questions across the technical phone screen and the live code review session. Do not ask all questions in one session — select based on the candidate's background and the time available. The goal is depth, not breadth.*

---

## FLUTTER QUESTIONS (10)

**F1.** What is the difference between `StatefulWidget` and `StatelessWidget`? When would you choose one over the other? Give an example from an app you built.

**F2.** In KrishiMithra, we use `ValueListenableBuilder` to rebuild the UI when the theme or locale changes. What is a `ValueNotifier`, and when is it more appropriate than using a `StreamBuilder`?

**F3.** Our app uses `Provider` for locale state. What problem does the Provider package solve, and what are its limitations compared to Riverpod or Bloc?

**F4.** Explain `BuildContext`. Why does `BuildContext` sometimes become invalid after an `async` operation, and how do you guard against that in `StatefulWidget`?

**F5.** What is the difference between `MediaQuery.of(context).size` and `LayoutBuilder`? When should you use each?

**F6.** We use `geolocator: any` in pubspec.yaml (an unpinned version). Why is this a bad practice and what would you do to fix it safely without breaking the app?

**F7.** Explain Flutter's `dispose()` method. What resources should always be disposed, and what happens if you forget?

**F8.** You need to display a large list of farmers (potentially 500+ items). What Flutter widget would you use, and what Firestore-side changes would you make to avoid loading all 500 at once?

**F9.** A widget test fails with `"A Ticker was created but disposed too quickly"`. What does this mean and how do you fix it?

**F10.** We support 6 languages. A developer adds a new string to the English ARB file but forgets to add it to the other 5 ARB files. What happens at runtime, and how would you prevent this from happening in your workflow?

---

## FIREBASE / FIRESTORE QUESTIONS (10)

**FB1.** Explain the difference between a Firestore `get()` call and a `snapshots()` stream. When would you use each in KrishiMithra?

**FB2.** Our Firestore rules use a `userRole()` function that does a `get()` on the `users` collection. What is the performance risk of this pattern, and when does it become a problem?

**FB3.** A Firestore query fails with `"The query requires a composite index"`. What does this mean, what causes it, and how do you resolve it? (This actually happened in KrishiMithra — we have `firestore.indexes.json`.)

**FB4.** What is a Firestore `FieldValue.serverTimestamp()` and why should you use it instead of `DateTime.now()` for `createdAt` fields?

**FB5.** Explain the `Timestamp` type in Firestore. In KrishiMithra, we parse timestamps like this: `(v is Timestamp) ? v.toDate() : DateTime.tryParse(v.toString())`. Why is the `is Timestamp` check necessary?

**FB6.** A user creates a Purchase Order (`purchase_orders` collection). The Firestore rule says: `allow create: if isSignedIn() && uid() == request.resource.data.buyerId`. A developer proposes changing it to `allow create: if isSignedIn()`. What are the consequences?

**FB7.** What is the difference between `doc.set()` and `doc.update()` in Firestore? When would `set()` with `SetOptions(merge: true)` be the right choice?

**FB8.** Firebase Authentication returns an ID token. How long does an ID token last, and what happens in our app if a user's token expires while they are mid-session?

**FB9.** We have two Firestore collections for user data: `users` and `userProfile`. This causes duplicate data lookups in some pages. How would you approach consolidating these without a big-bang migration that risks breaking production?

**FB10.** Explain Firebase Authentication's `verifyPhoneNumber` flow. Why does the `verificationCompleted` callback only fire on Android and not on Web?

---

## BACKEND / API QUESTIONS (10)

**API1.** Our Node.js backend runs on Render's free tier. A user reports slow image uploads. What would you check first? (Hint: Render free tier has cold starts.)

**API2.** The backend verifies Firebase ID tokens using `firebase-admin`. Why is server-side token verification preferable to trusting the `uid` sent in the request body?

**API3.** What is CORS and why does the KrishiMithra backend have special handling for requests without an `Origin` header? (Hint: look at the `if (!origin)` check in `server.js`.)

**API4.** Our backend uses `express.json({ limit: "15mb" })`. Why is a large JSON limit a potential security risk, and what would you set it to for routes that do not receive image data?

**API5.** The backend currently has no rate limiting. Describe how you would implement rate limiting using `express-rate-limit`. What should the limit be for the `/api/upload` route versus the `/api/auth/verify` route?

**API6.** The `/api/ai` routes skip the `verifyToken` middleware. Why might this be intentional, and what alternative protection should those routes have?

**API7.** What is the purpose of the `/api/auth/verify` endpoint? Why is the backend using MongoDB if Firebase is already the auth source of truth?

**API8.** Describe the image upload pipeline from Flutter to Cloudinary. How many network hops are involved, and where could this pipeline fail?

**API9.** A mobile user uploads an image. The backend receives it via Multer, uploads to Cloudinary, then deletes the temp file. What happens if the Cloudinary upload fails — is the temp file deleted? Show how you would fix any issue here.

**API10.** What HTTP status code should the backend return when a Firebase token is expired versus when a token is completely invalid? Our current implementation returns 401 for both — is this correct?

---

## MONGODB QUESTIONS (10)

**MG1.** KrishiMithra uses MongoDB Atlas for user profile sync from Firebase. What problem does this solve that Firestore alone does not solve?

**MG2.** The backend connects to MongoDB using Mongoose. What does the `connectDB()` function do, and what happens to incoming requests if MongoDB is temporarily unreachable?

**MG3.** What is a Mongoose Schema and what does it give you that a plain `db.collection.insertOne()` call does not?

**MG4.** How would you add a new field (e.g., `lastActiveAt`) to the user model in MongoDB without breaking existing documents that do not have that field?

**MG5.** What is the difference between `findOne()` and `findById()` in Mongoose? When would you use each?

**MG6.** Explain MongoDB's `upsert` operation. How would you use it in the `verifyAndSyncUser` controller to either create or update a user document depending on whether they already exist?

**MG7.** Our MongoDB URI is in the backend `.env` file. What are the minimum permissions the database user in that URI should have? (Think about least privilege.)

**MG8.** What is a MongoDB Atlas IP Access List, and why is it important for production? If our backend is hosted on Render, what IP should be whitelisted?

**MG9.** You need to find all users who signed in within the last 7 days. Write the Mongoose query (pseudo-code is fine).

**MG10.** What is a MongoDB index and when would you add one? If we query users frequently by `email`, should we add an index on that field?

---

## CLOUDINARY / IMAGE UPLOAD QUESTIONS (5)

**CL1.** KrishiMithra uses Cloudinary for product images and Supabase for profile photos — two separate image storage systems. What is the practical implication of this split for a new developer?

**CL2.** Image upload works on the Android emulator but fails on a real device. Walk me through your debugging process step by step.

**CL3.** A Cloudinary upload returns a `secure_url`. How should this URL be stored in Firestore, and what happens if Cloudinary deletes or changes the URL in the future?

**CL4.** What is Multer and what does it do in the KrishiMithra upload pipeline? What is the `dest` or `storage` option and why does the backend use `diskStorage` with a temp file rather than `memoryStorage`?

**CL5.** How would you add image compression before upload (e.g., reduce file size to under 500KB before sending to the backend)? Where in the pipeline would you add this — Flutter side or backend side?

---

## GIT / GITHUB QUESTIONS (5)

**GT1.** You have been working on a feature branch for 3 days. The `main` branch has had 5 commits since you branched. How do you bring your branch up to date with `main` before submitting a PR?

**GT2.** You accidentally commit a file containing an API key to a public repository. What do you do immediately, and in what order?

**GT3.** What is branch protection and why should `main` always have it enabled in KrishiMithra's repository? What rules would you set?

**GT4.** Explain the difference between `git merge` and `git rebase`. For a startup with one developer, which would you use for feature branches, and why?

**GT5.** A PR you submitted gets rejected with the comment "this function already exists in `lib/services/distance_service.dart`". What does this tell you about how you approached the task, and what would you do differently?

---

## SECURITY QUESTIONS (5)

**SEC1.** A junior developer asks you: "Can you send me the Firebase service account JSON? I need it to test the backend locally." How do you respond?

**SEC2.** You find that the production Firebase API key is committed to the public GitHub repository in `firebase_options.dart`. Is this a security emergency? Why or why not? What is the difference between a Firebase client API key and a Firebase Admin service account key?

**SEC3.** Our Firestore rules have this catch-all at the bottom: `match /{document=**} { allow read, write: if false; }`. If you delete this rule, what is the default Firestore behavior for collections not explicitly listed?

**SEC4.** The `export_products` collection allows `allow read: if true` (unauthenticated public read). A malicious actor writes a script that reads 100,000 documents from this collection per hour. What is the risk, and what Firestore-level protection can you add?

**SEC5.** You discover that the backend's MongoDB URI contains a database user with `readWriteAnyDatabase` permissions (full access to all databases). What should the minimum permission be, and why?

---

## DEBUGGING QUESTIONS (5)

**DB1.** Image upload works on the Android emulator but fails on a real Android device. What would you check?

*(Good answer covers: real device network vs emulator network, certificate pinning, actual error message from the backend, Logcat output, testing with a direct HTTP client like Postman on the same network.)*

**DB2.** A `PERMISSION_DENIED` Firestore error occurs in production but works fine in the development Firebase project. What are the three most likely causes?

*(Good answer covers: production Firestore rules are different from dev rules, user's `role` field may not exist in production `users` collection, collection name typo in production vs dev.)*

**DB3.** The app works perfectly in debug mode but crashes with `MissingPluginException` in release mode. What causes this and how do you fix it?

*(Good answer covers: release build tree-shaking, plugin not registered in `MainActivity`, ProGuard rules stripping plugin classes.)*

**DB4.** A location-based search returns farmers sorted incorrectly — some far farmers appear before nearby ones. How would you debug the sorting logic?

*(Good answer covers: log the raw lat/lon values and distances before sorting, verify the Haversine calculation is correct, check if null lat/lon values are defaulting to 0.0 which is near the Gulf of Guinea in Africa.)*

**DB5.** A developer asks for the Firebase service account JSON. What should happen?

*(Correct answer: Never provide it to a developer. The backend already has it configured via environment variables on Render. If the developer needs to test locally, set up a Firebase Emulator. The service account JSON gives admin-level access to the entire Firebase project.)*

---

## PRODUCTION / DEPLOYMENT QUESTIONS (5)

**PD1.** Walk me through the exact steps to build and sign a production AAB (Android App Bundle) for Play Store submission. What files do you need and where are they?

**PD2.** We currently sign the release build with the debug keystore (`signingConfig = signingConfigs.getByName("debug")`). What is wrong with this and what needs to change?

**PD3.** After renaming the Android package from `com.example.temp_fix` to `com.krishimithra.app`, what other files need to be updated? List them all.

**PD4.** The Render backend goes cold (shuts down after inactivity). What is the user-visible effect, and what are the options for keeping it warm without upgrading to a paid plan?

**PD5.** We want to deploy the next version without any downtime. What is your strategy for rolling out a database schema change (adding a new required field to existing Firestore documents) while the previous version is still running?

---

## PRACTICAL SCENARIO QUESTIONS

**SC1.** Image upload works on the Android emulator but fails on a real device.

**SC2.** Firestore `PERMISSION_DENIED` occurs after deployment to production. The same code works on the development Firebase project.

**SC3.** The app works in development/debug mode but crashes in release mode with no useful error message.

**SC4.** A developer you are reviewing asks for the Firebase service account JSON. What do you say and do?

**SC5.** The location-based nearest-farmer search returns incorrect results — farmers in another city appear before local farmers.

**SC6.** A user reports that after signing in with Google on Android, they are shown an error and kicked back to the login screen, but sign-in works fine on the web version.

**SC7.** The app's APK is 180MB. The Play Store recommends under 150MB. What would you check and how would you reduce the APK size?

**SC8.** A new developer joins and asks: "Why are there two export hubs — `export_hub/` and `exporter_hub/`?" How do you explain this, and what do you do with the old one?

*(Right answer: `export_hub/` is a legacy module kept for reference. New work goes into `exporter_hub/`. The legacy module should be documented as deprecated, not deleted until verified it has no active users.)*
