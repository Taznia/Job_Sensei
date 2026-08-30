# Running Job Sensei on a physical Android phone

For a teammate running the app from Android Studio on her own laptop, with her
phone plugged in over USB.

The app talks to the Node API, so **the backend has to be running and the phone
has to be able to reach it.** That second part is the only genuinely fiddly bit,
and it is what most of this page is about.

---

## 0. Check the machine first

Before anything else, and again right before you present:

```
node tool/preflight.mjs
```

It checks every part of the chain that differs between machines — Node and
Flutter versions, `backend/.env`, DNS, the database connection, whether the
jobs collection has anything in it, the port, the phone, and the `adb reverse`
mapping — and names the one that is broken instead of leaving you to guess
from a connection error.

**FAIL** lines stop the app working. **WARN** lines usually just mean
something is not started yet, like the server.

It has no dependencies of its own, so it runs on a fresh clone before anything
is installed.

---

## 1. Phone setup (once)

On the phone: **Settings → About phone → tap "Build number" seven times** to
unlock Developer options, then **Settings → Developer options → USB debugging
→ on**.

Plug the phone in. Accept the "Allow USB debugging?" prompt that appears on the
handset — it will not show up in Android Studio until you do.

Check the laptop can see it:

```
flutter devices
```

Your phone should be listed by model name. If it says "unauthorized", unplug,
replug, and accept the prompt.

---

## 2. Backend setup (once)

```
cd backend
```

```
npm install
```

Create `backend/.env` with the **team's shared** MongoDB Atlas connection string
so everyone sees the same data:

```
PORT=1190
MONGODB_URI=mongodb://<the team connection string>
JWT_SECRET=any-long-random-string
```

Start it:

```
npm start
```

> **Do not run `npm run seed` against a database someone else is already
> using.** It calls `deleteMany` on jobs, users, posts, resumes and
> applications first — it is a reset, not a top-up. Seed only when the
> cluster is empty, or when you are pointing at your own database name.
>
> To get your own copy instead of sharing, change the database name near the
> end of the connection string, e.g. `.../jobsensei_nazifa?...`, and then
> seeding is safe because it is a different database.

Leave that terminal open. You should see
`Job Sensei API listening on http://localhost:1190`.

Optionally pull in real job listings (Module 2):

```
npm run import:jobs
```

---

## 3. Connect the phone to the backend

A phone's `localhost` is the **phone**, not the laptop, so the app cannot reach
`127.0.0.1:1190` on its own. Pick one of these.

### Option A — USB port forwarding (recommended)

One command maps the phone's port 1190 onto the laptop's:

```
adb reverse tcp:1190 tcp:1190
```

Now `127.0.0.1:1190` on the phone *is* the laptop's backend. This works on any
network, including campus Wi-Fi that blocks device-to-device traffic, and needs
no IP addresses.

> `adb` ships with Android Studio. If the command is not found, it lives in
> `%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe`.

Re-run it after unplugging the phone or restarting adb — the mapping does not
survive either.

### Option B — over Wi-Fi

Both devices must be on the same network, and the network must allow devices to
talk to each other (many campus networks do not).

Find the laptop's IP:

```
ipconfig
```

Look for **IPv4 Address** under your Wi-Fi adapter, e.g. `192.168.0.14`. Use
that instead of `127.0.0.1` in the run command below.

You may also need to let Node through Windows Firewall — Windows usually prompts
the first time the server starts.

---

## 4. Run it from Android Studio

1. **File → Open**, select the `Job_Sensei` folder (the one containing
   `pubspec.yaml`). Open the folder, not a single file, or none of the
   Flutter tooling activates.
2. Wait for the status bar to finish resolving dependencies. If it does not
   start on its own, click **Pub get** in the banner across the top.
3. Plug the phone in and select it in the **device dropdown**, top-right
   beside the Run button. It appears by model name once adb sees it.
4. **Run → Edit Configurations…**, select the Flutter configuration, and put
   this in **Additional run args**:

   ```
   --dart-define=API_BASE_URL=http://127.0.0.1:1190/api
   ```

   Apply, then OK. Without it the app cannot reach the backend — the reason
   is explained below.
5. Open **View → Tool Windows → Terminal** and start the backend:

   ```
   cd backend
   ```

   ```
   npm start
   ```

6. Open a **second terminal tab** — the `+` in the Terminal panel, since the
   first is busy running the server — and map the port across the cable:

   ```
   adb reverse tcp:1190 tcp:1190
   ```

7. Press the green **Run ▶** button.

Order matters across steps 3, 6 and 7: `adb reverse` needs the phone already
connected, and the app needs the mapping already in place before it starts.

---

## 4b. Or run it from the terminal

From the project root, with the phone connected:

```
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:1190/api
```

For Option B, swap in the laptop's IP:

```
flutter run --dart-define=API_BASE_URL=http://192.168.0.14:1190/api
```


### Why the `--dart-define` matters

Without it the app falls back to `localhost:5000`, and on Android that gets
rewritten to `10.0.2.2` — the address of the host machine **as seen from an
emulator**. On a real handset `10.0.2.2` is nothing, and every request fails.

An explicit `API_BASE_URL` is used exactly as written, which is what makes both
options above work.

---

## 5. Sign in

The career profile is per-account, so the Profile tab needs a session. Open
**Profile** and use the **Sign in** button, or the demo account:

- Email: `demo@jobsensei.app`
- Password: `Demo123!`

Everything on that screen then reads and writes through the API — add a skill on
the phone and it is in Atlas.

---

## Demo script — Adreed's four modules

Sign in first (`demo@jobsensei.app` / `Demo123!`). Everything below reads and
writes the live Atlas database, so an edit on the phone is really stored.

### Module 1 — Career Profile · the **Profile** tab

Education, work experience, preferred roles, location, expected salary,
skills, certifications, portfolio links and career goals.

- The ring at the top is a weighted completeness score, not a field count —
  skills and job preferences carry the most because matching reads them
  directly.
- Tap **Edit** on any section to add, edit or delete entries.
- Add a skill and watch the ring and the "+N more" chip both change.

### Module 2 — Job import · run once before the demo

```
npm run import:jobs
```

Pulls real listings from the Remotive and Arbeitnow public APIs, normalises
them onto our schema, and upserts by `(source, externalId)` so re-running
updates rather than duplicates. Imported jobs then appear in the Jobs tab
alongside internal ones, tagged **via Remotive** / **via Arbeitnow**.

Check what is stored at any time:

```
http://127.0.0.1:1190/api/jobs/import/status
```

### Module 3 — Job Search · the **Jobs** tab

Filtering happens on the server, so a filter applies to the whole collection
rather than to the page already downloaded.

- Type in the search box — results are ranked by relevance, and the header
  count updates.
- Tap **Filters** for company, location, skills, job type, working
  arrangement, experience level, and salary range. The button shows how many
  are active.
- Worth calling out: salary matches on **overlap**, so a 90k–140k job still
  appears when you ask for 100k and up.
- Change the sort to **Highest pay** or **Newest**.
- Tap the bookmark icon to save a job for later.

### Module 4 — Job Match Score · open any job from the Jobs tab

Compares the career profile, and the selected resume when there is one,
against that job's requirements.

- The ring gives an overall score and a verdict (Strong / Good / Fair / Low).
- **How this score is made up** breaks it into Skills, Experience,
  Preferences and Education, each with a plain-English reason. That is what
  makes the number accountable rather than an assertion.
- It deliberately gives **no learning recommendations** — that is the
  skill-gap feature, reached from the "Analyze Skills in Learn" button below.

> A good moment to show the modules connecting: edit the profile (Module 1),
> then reopen a job and watch the match score (Module 4) move.

---

## Troubleshooting

**"Could not reach the Job Sensei API at …"**

The app is telling you the URL it tried. Check, in order:

1. Is `npm start` still running in the backend terminal?
2. Did you run `adb reverse tcp:1190 tcp:1190` *after* plugging the phone in?
3. Does the URL in the message match how you connected — `127.0.0.1` for
   Option A, the laptop's LAN IP for Option B?

**Requests fail only on the phone, fine in a browser**

Almost always the `adb reverse` mapping was lost. Re-run it.

**"Sign in to view and edit your career profile"**

Expected when signed out. Tap **Sign in**.

**App builds but the phone shows an old version**

Stop the run and start it again — a hot reload does not pick up a changed
`--dart-define`.

**`flutter devices` does not list the phone**

USB debugging off, the on-phone prompt not accepted, or a charge-only cable.
Try a different cable before anything else.

---

## What talks to what

```
  Phone (app)  ──http──▶  laptop:1190  ──▶  MongoDB Atlas
       │                   Node/Express        (shared team cluster)
       └── adb reverse maps the phone's 127.0.0.1:1190
           onto the laptop's, over the USB cable
```

The Flutter app holds no database credentials — it only ever talks to the API,
which is the only thing that knows the Atlas connection string.
