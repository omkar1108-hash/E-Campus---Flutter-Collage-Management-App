# E-Campus – Flutter College Management App

Capstone project for **Mobile Computing** (MCA Sem III, AIMSR). One mobile app
for students, class representatives, teachers and administrators.

| Feature | How it works |
|---|---|
| **OTP login & registration** | Firebase Authentication (phone/SMS OTP), then a one-time profile form |
| **Role-based access control** | Roles `student`, `class_rep`, `teacher`, `admin` stored in Firestore; enforced by UI *and* `firestore.rules` |
| **Role-aware drawer** | Students get 6 core entries; extra entries appear for class reps (post news), teachers (upload books, broadcast bus), admins (manage users) |
| **E-Library** | PDFs in Firebase Storage (or any link), listed per department, searchable, opened in the reader/browser |
| **Bus tracking** | Staff phone streams GPS (`geolocator`) → Firestore → live markers on Google Maps |
| **Chat** | Department group room + one-to-one chats with teachers/classmates (Firestore, real time) |
| **AI chatbot** | OpenAI ChatGPT Chat Completions API |
| **Tech news** | Class reps/teachers/admins post per department; students see their department's feed |

Docs: [`docs/REPORT.md`](docs/REPORT.md) (project report following the capstone structure).

## Run it

Prerequisites: Flutter 3.x (Dart ≥ 3.13), a Firebase project, a Google Maps API key, an OpenAI API key.

1. **Firebase**
   - Create a project; enable **Authentication → Phone**, **Cloud Firestore**, **Storage**.
   - Add your Android app (`in.edu.aimsr.e_campus`) and register your **SHA-1/SHA-256** (needed for phone auth). For testing without real SMS, add test numbers under Authentication → Phone.
   - `dart pub global activate flutterfire_cli && flutterfire configure` – this overwrites `lib/firebase_options.dart`.
   - Deploy rules: `firebase deploy --only firestore:rules,storage` (files `firestore.rules`, `storage.rules`).
2. **Google Maps** – enable *Maps SDK for Android* and put the key in `android/app/src/main/AndroidManifest.xml` (`com.google.android.geo.API_KEY`). For iOS, call `GMSServices.provideAPIKey(...)` in `AppDelegate.swift`.
3. **Run**
   ```bash
   flutter pub get
   flutter run --dart-define=OPENAI_API_KEY=sk-... 
   ```
   Optional: `--dart-define=OPENAI_MODEL=gpt-4o-mini`.
4. **Create the first admin** – everyone registers as a student. Sign in once, then in the Firebase console open `users/<your uid>` and set `role` to `admin`. After that, admins promote others from *Manage Users*.

Until `flutterfire configure` is run the app shows a "Firebase setup required" screen instead of crashing.

## Project layout

```
lib/
  main.dart, app.dart            entry point, providers, session gate
  config.dart                    departments, dart-define secrets, constants
  models/                        AppUser + UserRole (RBAC), Book, NewsItem, ChatMessage, BusLocation
  services/                      auth_service, firestore_service, openai_service, chat_ids
  providers/session_provider.dart  auth + profile state
  screens/                       auth, profile setup, home/drawer, library, bus, chat, AI, news, admin
test/                            unit tests (RBAC, drawer, models, OpenAI client)
firestore.rules, storage.rules   server-side security
docs/REPORT.md                   project report
```

## Tests

```bash
flutter analyze
flutter test
```

## Known limitations

- The OpenAI key supplied via `--dart-define` is embedded in the app binary and can be extracted. Fine for a demo; for production route requests through your own backend (e.g. a Cloud Function) that holds the key.
- Bus broadcasting works while the app is in the foreground (no background service).
- Deleting a book removes its listing but not the uploaded Storage file.
- Teachers see content for their own department (only admins see all departments).
- The code passes `flutter analyze` and the unit tests, but it has **not been run on an emulator or device yet** (no Firebase project/Maps key was available while building it). Do the manual test cases in `docs/REPORT.md` §5.2 before your demo.
