# Running Job Sensei on a new PC

Written for setting the project up on a lab or school machine to demo it.
Budget **45 minutes** the first time, and do a dry run before demo day — not on
demo day.

---

## 0. Before you leave

Two things to do on the machine where the project already works:

1. **Push your work.** Anything uncommitted does not exist on the other PC.
   ```
   git status
   git push origin adreed
   ```
2. **Read "If the school PC blocks you" at the bottom of this file** and prepare
   the fallback. Managed machines often block the exact things Flutter needs,
   and you do not want to discover that with a class watching.

---

## 1. Check what is already installed

Open PowerShell and run each of these. Any that fail, install in step 2.

```
git --version
flutter --version
```

Also confirm **Google Chrome** is installed — it is the easiest run target and
avoids needing Visual Studio.

---

## 2. Install the Flutter SDK

Do **not** use the VS Code "Download SDK" button. It clones from GitHub and
fails on unstable connections with `early EOF` / `invalid index-pack output`.
Use the prebuilt zip instead.

**Download** (`-C -` resumes if the connection drops — rerun the same command):

```
curl.exe -L -C - -o "$env:USERPROFILE\Downloads\flutter_stable.zip" "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.47.0-stable.zip"
```

**Extract** to `C:\src` — use `tar`, not `Expand-Archive`, which is very slow on
a zip this size:

```
mkdir C:\src -Force
tar -xf "$env:USERPROFILE\Downloads\flutter_stable.zip" -C C:\src
```

Rules for the location: **not** inside `C:\Program Files` (Flutter needs write
access), and **no spaces** anywhere in the path.

If you have no write access to `C:\`, extract to your user folder instead and
use that path everywhere below:

```
tar -xf "$env:USERPROFILE\Downloads\flutter_stable.zip" -C "$env:USERPROFILE"
```

**Add to PATH** (user-level, no admin needed). Run this **once** — running it
repeatedly appends duplicates:

```
[Environment]::SetEnvironmentVariable("Path", "$([Environment]::GetEnvironmentVariable('Path','User'));C:\src\flutter\bin", "User")
```

**Then fully quit and reopen VS Code.** A new terminal tab is not enough — it
inherits the old environment from the running VS Code process. See
troubleshooting if `flutter` still is not recognised.

---

## 3. Enable Developer Mode

Flutter uses symlinks for plugin resolution and Windows restricts those.
Without this, `flutter pub get` fails.

```
start ms-settings:developers
```

Toggle **Developer Mode** on.

> **This is the step most likely to be blocked by school IT policy.** If the
> toggle is greyed out or missing, stop and use the fallback at the bottom.

---

## 4. Clone and run

```
git clone https://github.com/Taznia/Job_Sensei.git
cd Job_Sensei
git checkout adreed
flutter pub get
flutter run -d chrome
```

First run compiles the web bundle and takes a few minutes. Later runs are fast.

Click **Profile** in the navigation to reach the career profile page.

---

## 5. Check it works

```
flutter analyze
flutter test
```

`analyze` reports ~57 `info`-level deprecation notices in the older screens —
those are expected and harmless. What matters is **no `error` lines**, and
`All tests passed!` from `flutter test`.

---

## Troubleshooting

**`flutter : The term 'flutter' is not recognized`**

The terminal started before the PATH change. Refresh the current session:

```
$env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')
```

To fix it permanently, fully exit VS Code (File → Exit, closing every window)
and reopen. Or sidestep PATH entirely by calling the full path:

```
& "C:\src\flutter\bin\flutter.bat" run -d chrome
```

**`Building with plugins requires symlink support`**

Developer Mode is off. Go back to step 3.

**`Failed to clone Flutter` / `early EOF` / `invalid index-pack output`**

You are using the VS Code SDK download or `git clone` of the Flutter repo. Use
the zip in step 2. If you must clone, shallow-clone to cut the transfer size:

```
git clone --depth 1 -b stable https://github.com/flutter/flutter.git C:\src\flutter
```

**No Chrome on the machine**

```
flutter run -d edge
```

Avoid `-d windows` — that target needs the Visual Studio C++ workload, which is
a multi-gigabyte install.

**PATH has duplicate entries**

Harmless, but this dedupes it:

```
$p = [Environment]::GetEnvironmentVariable('Path','User') -split ';' | Where-Object { $_ } | Select-Object -Unique
[Environment]::SetEnvironmentVariable('Path', ($p -join ';'), 'User')
```

---

## If the school PC blocks you

If Developer Mode is locked, or you cannot install or write outside your user
folder, do not fight it during the demo. Prepare this **in advance** on a
machine where the project runs:

```
flutter build web --release
```

That writes a self-contained static site to `build/web`. It needs no Flutter and
no install to view — only a browser and a web server. Two ways to use it:

**A. Host it and demo from a URL (most reliable).** Drag the `build/web` folder
onto <https://app.netlify.com/drop> — no account needed — and you get a link
that works on any machine, including a phone. GitHub Pages also works since this
repo is public.

**B. Carry it on a USB stick.** Copy `build/web` across. It cannot be opened by
double-clicking `index.html` — browsers block the asset requests over `file://`.
It needs a local server, so this only works if the machine has Python:

```
cd build\web
python -m http.server 8000
```

Then open <http://localhost:8000>.

Option A is the safer bet. Even if you plan to run the full toolchain, spend the
five minutes to set up a hosted URL as a backup.

---

## Notes on the design

The career profile screen is built to the Figma frame. It uses **Inter**, which
is not bundled in this repo, so type falls back to the platform font. To match
the design exactly, drop the Inter `.ttf` files into `assets/fonts`, declare the
family in `pubspec.yaml`, and set `ProfileDesign.fontFamily` to `'Inter'` in
`lib/features/profile/presentation/widgets/profile_design.dart`.

To re-pull designs from Figma, see `tool/figma_pull.mjs`. It needs a personal
access token in `.figma.env` (copy `.figma.env.example`). That file is
gitignored and never committed.
