# Running Job Sensei on a physical Android phone

For a teammate running the app from Android Studio on her own laptop, with her
phone plugged in over USB.

The app talks to the Node API, so **the backend has to be running and the phone
has to be able to reach it.** That second part is the only genuinely fiddly bit,
and it is what most of this page is about.

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

Seed it once, then start it:

```
npm run seed
```

```
npm start
```

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

## 4. Run the app

From the project root, with the phone connected:

```
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:1190/api
```

For Option B, swap in the laptop's IP:

```
flutter run --dart-define=API_BASE_URL=http://192.168.0.14:1190/api
```

**In Android Studio** instead of the terminal: Run → Edit Configurations… →
select the Flutter configuration → put this in **Additional run args**:

```
--dart-define=API_BASE_URL=http://127.0.0.1:1190/api
```

Then pick the phone in the device dropdown and press Run.

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
