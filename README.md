# Job Sensei (Flutter)

Career-support app. The **Node API is a separate repository** you host on Vercel. This project is the Flutter client only.

## How the two backends are split

| Concern | Where it lives |
|---|---|
| Auth, jobs, resumes, community, learning, notifications | Remote Job Sensei API (`API_BASE_URL`) |
| AI chat (Momo) | **This app** → Gemini API directly |
| Chat history | **SQLite on the device** (IndexedDB on web) |

Chat does not use the Job Sensei API. If Vercel is down, AI Sensei still works. If Gemini is missing or fails, jobs/community still work.

## Run

1. Copy `.env.example` to `.env` in this folder if you do not already have `.env`.
2. Put your Gemini key in `.env`:

```env
GEMINI_API_KEY=your-gemini-key
API_BASE_URL=https://YOUR-API.vercel.app/api
```

3. Start the app:

```bash
flutter pub get
flutter run
```

Get a Gemini key from [Google AI Studio](https://aistudio.google.com/apikey). Restart the app after changing `.env` (hot reload will not pick it up).

`--dart-define=GEMINI_API_KEY=...` still overrides `.env` if you need that.

Without a key, chat still opens with an on-device offline coach and a banner.

For a local API from the other repo, leave `API_BASE_URL` empty:

- Web / Windows: `http://localhost:5000/api`
- Android emulator: `http://10.0.2.2:5000/api`

## Web chat

SQLite on web needs `web/sqlite3.wasm` and `web/sqflite_sw.js`. If they are missing:

```bash
dart run sqflite_common_ffi_web:setup --force
```
