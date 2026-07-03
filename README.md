# job_sensei_flutter

Flutter frontend structure for the Job Sensei career-support application.

## Folder Structure

```text
job_sensei_flutter/
│
├── android/
├── ios/
├── web/
├── linux/
├── macos/
├── windows/
│
├── assets/
│   ├── icons/
│   ├── images/
│   ├── fonts/
│   └── animations/
│
├── lib/
│
│   ├── app/
│   │   ├── app.dart
│   │   ├── router.dart
│   │   ├── theme.dart
│   │   └── injector.dart
│   │
│   ├── core/
│   │   ├── constants/
│   │   ├── errors/
│   │   ├── network/
│   │   ├── services/
│   │   ├── storage/
│   │   ├── utils/
│   │   └── widgets/
│   │
│   ├── shared/
│   │   ├── models/
│   │   ├── widgets/
│   │   ├── enums/
│   │   └── extensions/
│   │
│   ├── features/
│   │
│   │   ├── authentication/
│   │   ├── profile/
│   │   ├── jobs/
│   │   ├── resumes/
│   │   ├── applications/
│   │   ├── ai/
│   │   ├── learning/
│   │   ├── community/
│   │   ├── notifications/
│   │   └── admin/
│   │
│   └── main.dart
│
├── test/
│
├── pubspec.yaml
└── README.md
```

## What Each Folder Is For

- `android/`, `ios/`, `web/`, `linux/`, `macos/`, `windows/`: Flutter platform targets.
- `assets/`: static resources used by the UI.
- `lib/app/`: app entry composition, routing, theming, and dependency injection setup.
- `lib/core/`: shared constants, error handling, networking, storage, utilities, and base widgets.
- `lib/shared/`: reusable models, widgets, enums, and extensions shared across features.
- `lib/features/`: feature modules organized by domain.
- `test/`: unit and widget tests.

## Feature Modules

- `authentication/`: login, register, forgot password, OTP verification.
- `profile/`: user profile and career profile screens.
- `jobs/`: job search, saved jobs, recommendations, and job details.
- `resumes/`: resume builder, preview, templates, and AI suggestions.
- `applications/`: application submission and tracking.
- `ai/`: AI career companion and interview support.
- `learning/`: skill-gap learning resources and progress tracking.
- `community/`: groups, posts, comments, and discussions.
- `notifications/`: email and in-app notification views.
- `admin/`: admin moderation and management screens.

## Getting Started

1. Install the Flutter SDK.
2. Run `flutter pub get` inside the project root.
3. Launch the app with `flutter run`.

## Notes

- This repository is only the frontend.
- Update API endpoints and environment values from the configuration files inside `lib/` when connecting to the backend.

