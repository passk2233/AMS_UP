# AMS UP — Academic Management System

> **CEIT (College of Engineering and Information Technology) — Academic Management System.**
> A cross-platform mobile application that connects Administrators, Teachers, and Students under one roof: timetables, room bookings, announcements, evaluations, grades, and notifications.

[![Flutter](https://img.shields.io/badge/Flutter-3.35%2B-02569B?logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-%5E3.11.1-0175C2?logo=dart&logoColor=white)](https://dart.dev/)
[![GetX](https://img.shields.io/badge/State-GetX_4.7-8A2BE2)](https://pub.dev/packages/get)
[![FCM](https://img.shields.io/badge/Notifications-Firebase_Cloud_Messaging-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com/docs/cloud-messaging)
[![License](https://img.shields.io/badge/license-Internal-lightgrey)](#license)

---

## Table of Contents

1. [About](#about)
2. [Highlights](#highlights)
3. [Tech Stack](#tech-stack)
4. [Project Documentation](#project-documentation)
5. [Quick Start](#quick-start)
6. [Folder Layout](#folder-layout)
7. [Screenshots](#screenshots)
8. [Roles & Permissions](#roles--permissions)
9. [Roadmap](#roadmap)
10. [License](#license)

---

## About

`ams-up` is the official mobile front-end for the CEIT faculty management platform. It is paired with a Go (Golang) RESTful API backend and a MariaDB database (see [`DATABASE_SCHEMA.md`](./DATABASE_SCHEMA.md)).

The app supports the Lao (ລາວ) language as the primary UI language with English fallbacks where applicable.

## Highlights

- **Role-based shell** — Admin, Teacher, and Student each get a dedicated bottom-nav shell with tabs tailored to their workflow.
- **Room booking** — Students and teachers reserve rooms; admins approve or reject pending requests.
- **Announcements & push** — Admins broadcast notifications to all users, a department, a student group, or a single student. Devices receive a push via Firebase Cloud Messaging (FCM).
- **Teacher evaluation** — Students rate teachers per study plan with star scores and optional comments. Teachers and admins see aggregated, anonymous results.
- **Timetables** — Per-day schedule views generated from `study_plan` rows.
- **Scores & GPA** — Students see per-subject grades, credits, and a live GPA on a 4.00 scale.

## Tech Stack

| Layer | Choice |
|---|---|
| Mobile UI | Flutter (Material 3) |
| State / DI / Routing | [GetX](https://pub.dev/packages/get) 4.7 |
| Networking | [Dio](https://pub.dev/packages/dio) 5.9 |
| Local persistence | [shared_preferences](https://pub.dev/packages/shared_preferences) |
| Env config | [flutter_dotenv](https://pub.dev/packages/flutter_dotenv) |
| Push notifications | Firebase Core + Firebase Messaging |
| Date/Time | [intl](https://pub.dev/packages/intl) |
| Backend | Go (Golang) RESTful API |
| Database | MariaDB 10.4 (utf8mb4) |

## Project Documentation

| Document | What's inside |
|---|---|
| [ARCHITECTURE.md](./ARCHITECTURE.md) | App structure, GetX layering, FCM flow |
| [SETUP.md](./SETUP.md) | Environment setup, Firebase config, run instructions |
| [FEATURES.md](./FEATURES.md) | Feature matrix by role |
| [API.md](./API.md) | Backend endpoints consumed by the app |
| [ROUTES.md](./ROUTES.md) | Named routes and navigation map |
| [DATABASE_SCHEMA.md](./DATABASE_SCHEMA.md) | Full database reference (provided) |
| [CONTRIBUTING.md](./CONTRIBUTING.md) | Code style, branch policy, PR checklist |

## Quick Start

```bash
# 1. Clone & install
git clone <repo-url>
cd ams-up
flutter pub get

# 2. Create your .env (see SETUP.md)
echo "API_URL=https://your-api-host" > .env

# 3. Add Firebase config (android/app/google-services.json + iOS GoogleService-Info.plist)
#    See SETUP.md for the FlutterFire CLI walkthrough

# 4. Run
flutter run
```

> For detailed steps including Firebase configuration and ngrok tunneling for local API testing, see [SETUP.md](./SETUP.md).

## Folder Layout

```
lib/
├── main.dart                       # Entry point + Firebase + FCM init
├── firebase_options.dart           # Generated FlutterFire config
└── app/
    ├── modules/                    # Feature modules (GetX pattern)
    │   ├── admins/                 # Admin: home, approve, announcement, evaluations
    │   ├── auth/                   # Login screen + controller
    │   ├── booking/                # Shared booking module (teacher)
    │   ├── data/
    │   │   ├── data_exporter.dart  # Barrel file for all models
    │   │   └── models/             # 30+ JSON models mirroring DB tables
    │   ├── profiles/               # Shared profile module
    │   ├── student/                # Student: home, schedule, booking, score, feedback
    │   └── teachers/               # Teacher: home, schedule, booking, evaluation
    ├── routes/                     # GetX named routes & page registry
    ├── services/                   # fcm_service.dart and other singletons
    ├── utilities/                  # Asset constants
    └── widgets/                    # Shared UI: colors, dialogs, cards, app bars
```

Each module follows the canonical **GetX pattern**: `bindings/`, `controllers/`, `views/`.

## Screenshots

> Add screenshots to `docs/screenshots/` and reference them here.

| Login | Admin Dashboard | Student Schedule | Booking |
|:---:|:---:|:---:|:---:|
| _coming soon_ | _coming soon_ | _coming soon_ | _coming soon_ |

## Roles & Permissions

| Role | Landing Page | Key Capabilities |
|---|---|---|
| **Administrator** | `AdminShellView` | Approve bookings, broadcast announcements, manage evaluation questions, view teacher evaluation aggregates |
| **Teacher** | `TeacherShellView` | View teaching schedule, request rooms, see own evaluation scores and student comments |
| **Student** | `HomeStudentView` | View class schedule, book rooms, see grades & GPA, submit faculty evaluations |

See [FEATURES.md](./FEATURES.md) for the full feature matrix.

## Roadmap

- [ ] Refresh token rotation in `AuthController`
- [ ] Offline cache for schedules and grades
- [ ] Localization toggle (Lao ⇄ English) in user settings
- [ ] In-app exam taking (uses `open_exam` / `exam_answers` tables — backend exists, UI pending)
- [ ] Profile photo upload pipeline
- [ ] CI: `flutter analyze` + `flutter test` on every PR

## License

This codebase is internal to the CEIT faculty project. Contact the project maintainers before redistribution.

---

_Last updated: May 2026._