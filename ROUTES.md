# Routes & Navigation

> The complete map of named routes, their views, bindings, and how the app transitions between them.

---

## Table of Contents

1. [Routes At a Glance](#routes-at-a-glance)
2. [Route Definitions](#route-definitions)
3. [Login Routing Decision](#login-routing-decision)
4. [Shell Tabs (Bottom Navs)](#shell-tabs-bottom-navs)
5. [Navigation Patterns](#navigation-patterns)

---

## Routes At a Glance

```
                    ┌─────────────┐
                    │   /auth     │  ← INITIAL
                    └──────┬──────┘
                           │ POST /auth/login
                           │ inspect roles
              ┌────────────┼─────────────┐
              │            │             │
              ▼            ▼             ▼
       /admin-home   /teacher-home   /home-student
       (AdminShell)  (TeacherShell)  (HomeStudent)

  ┌─ from anywhere with deep links ─────────────────────────┐
  │  /announcement     /approve         /evalution           │
  │  /schedules        /booking         /feedbacks           │
  │  /profiles         /score           /schedule-student    │
  │  /booking-student  /profile-student /faculty-feedback    │
  │  /evaluation-form  /student-noti                         │
  └──────────────────────────────────────────────────────────┘
```

`AppPages.INITIAL` is `Routes.AUTH`. Defined in `lib/app/routes/app_pages.dart`.

## Route Definitions

| Constant | Path | View | Binding | Role |
|---|---|---|---|---|
| `Routes.AUTH` | `/auth` | `AuthView` | `AuthBinding` | _everyone_ |
| `Routes.ADMIN_HOME` | `/admin-home` | `AdminShellView` | `AdminShellBinding` | Admin |
| `Routes.TEACHER_HOME` | `/teacher-home` | `TeacherShellView` | `TeacherShellBinding` | Teacher |
| `Routes.HOME_STUDENT` | `/home-student` | `HomeStudentView` | `HomeStudentBinding` | Student |
| `Routes.ANNOUNCEMENT` | `/announcement` | `AnnouncementView` | `AnnouncementBinding` | Admin |
| `Routes.APPROVE` | `/approve` | `ApproveView` | `ApproveBinding` | Admin |
| `Routes.EVALUTION` | `/evalution` | `EvalutionView` | `EvalutionBinding` | Admin |
| `Routes.PROFILES` | `/profiles` | `ProfilesView` | `ProfilesBinding` | Admin / Teacher |
| `Routes.SCHEDULES` | `/schedules` | `SchedulesView` | `SchedulesBinding` | Teacher |
| `Routes.BOOKING` | `/booking` | `BookingView` | `BookingBinding` | Teacher |
| `Routes.FEEDBACKS` | `/feedbacks` | `FeedbacksView` | `FeedbacksBinding` | Teacher |
| `Routes.SCORE` | `/score` | `ScoreView` | `ScoreBinding` | Student |
| `Routes.SCHEDULE_STUDENT` | `/schedule-student` | `ScheduleStudentView` | `ScheduleStudentBinding` | Student |
| `Routes.BOOKING_STUDENT` | `/booking-student` | `BookingStudentView` | `BookingStudentBinding` | Student |
| `Routes.PROFILE_STUDENT` | `/profile-student` | `ProfileStudentView` | `ProfileStudentBinding` | Student |
| `Routes.FACULTY_FEEDBACK` | `/faculty-feedback` | `FacultyFeedbackView` | `FacultyFeedbackBinding` | Student |
| `Routes.EVALUATION_FORM` | `/evaluation-form` | `EvaluationFormView` | `FacultyFeedbackBinding` | Student |
| `Routes.STUDENT_NOTI` | `/student-noti` | `StudentNotiView` | `StudentNotiBinding` | Student |

> **`HOME` and `STUDENT_HOME` are reserved** (declared in `app_routes.dart`) but not currently wired to a `GetPage`. They're placeholders for future expansion.

## Login Routing Decision

`AuthController.login()` reads `userModel.roles` and dispatches:

```dart
if (isAdmin)        Get.offAllNamed(Routes.ADMIN_HOME);
else if (isTeacher) Get.offAllNamed(Routes.TEACHER_HOME);
else if (isStudent) Get.offAllNamed(Routes.HOME_STUDENT);
else                /* show snackbar: role not recognised */
```

Where the role checks are case-insensitive matches against:

- `'administrator'` or `'admin'`
- `'teacher'`
- `'student'`

`offAllNamed` clears the navigation stack, so the user can't press back into the login screen.

## Shell Tabs (Bottom Navs)

Each role-based shell wraps several feature views inside an `IndexedStack` or page swap so tab state survives switches.

### Admin shell — `AdminShellView`

| Index | Tab Label | Widget |
|:---:|:---|:---|
| 0 | ສະຫຼຸບ (Dashboard) | `AdminHomeView` |
| 1 | ການຢືນຢັນ (Approvals) | `ApproveView` |
| 2 | ການປະກາດ (Announcements) | `AnnouncementView` |
| 3 | ການປະເມີນ (Evaluations) | `EvalutionView` |
| 4 | ໂປຣໄຟລ໌ (Profile) | `ProfilesView` |

Controller: `BottomNavController`. Programmatic helpers:

- `resetToHome()`
- `gotoApprovePage()`
- `gotoNotificationPage()`
- `gotoEvalutionPage()`
- `gotoProfilesPage()`

The app-bar pending-requests badge calls `gotoApprovePage()` when tapped.

### Teacher shell — `TeacherShellView`

| Index | Tab Label | Widget |
|:---:|:---|:---|
| 0 | Home | `TeacherHomeView` |
| 1 | Schedule | `SchedulesView` |
| 2 | Booking | `BookingView` |
| 3 | Evaluation | `TeacherEvaluationView` |
| 4 | Profile | `TeacherProfileView` |

Controller: `TeacherBottomNavController`. Tabs are also reachable from the home screen's quick-action buttons.

### Student shell — `HomeStudentView`

| Index | Tab Label | Widget |
|:---:|:---|:---|
| 0 | Home | `HomePage` |
| 1 | Schedule | `ScheduleStudentView` |
| 2 | Booking | `BookingStudentView` |
| 3 | Score | `ScoreView` |
| 4 | Profile | `ProfileStudentView` |

Controller: `HomeStudentController` (its `pages` list and `buildBottomNavigation()` together render the shell).

## Navigation Patterns

### Push within a shell

```dart
Get.toNamed(Routes.FACULTY_FEEDBACK);
Get.toNamed(Routes.EVALUATION_FORM, arguments: faculty);
```

### Replace stack (e.g. after login or logout)

```dart
Get.offAllNamed(Routes.AUTH);
Get.offAllNamed(Routes.ADMIN_HOME);
```

### Switch tab without push

```dart
Get.find<BottomNavController>().gotoApprovePage();        // admin
Get.find<TeacherBottomNavController>().changeTab(1);      // teacher
Get.find<HomeStudentController>().changePage(2);          // student
```

### Pass typed data between screens

```dart
// Student tapping "Evaluate" on a faculty card
Get.toNamed(Routes.EVALUATION_FORM, arguments: facultyObject);

// In EvaluationFormView
final Faculty faculty = Get.arguments;
```

### Modal sheets & dialogs

- Booking creation uses `showModalBottomSheet` (teacher) or a custom `AlertDialog` (student).
- All confirmations route through `AppDialogs.showConfirmation` for a consistent look.
- Detail views like `_showDetailSchedule` use `Get.bottomSheet`.

---

For the screens behind each route, see [FEATURES.md](./FEATURES.md). For the endpoints they call, see [API.md](./API.md).