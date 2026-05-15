# AGENTS.md

Guide for coding agents (Claude Code, Cursor, etc.) working on the **AMS_UP** Flutter frontend. Read this before editing — it captures conventions that aren't obvious from the code alone.

## Stack

- **Flutter** (Dart SDK `^3.11.1`)
- **State management:** [GetX](https://pub.dev/packages/get) (`get: ^4.7.3`) — `GetView`, `GetxController`, `.obs` reactive variables, `Obx()`, `GetBuilder`
- **HTTP:** Dio with shared_preferences-backed token auth
- **Localisation:** Lao (ລາວ) UI strings are written inline; do not translate
- **Routing:** GetX named routes (see `lib/app/routes/app_pages.dart`, `app_routes.dart`)

## Repository layout

```
lib/app/
├── modules/
│   ├── auth/                # Login
│   ├── admins/              # Admin role (home, approve, announcement, evalutions, navigator)
│   ├── teachers/            # Teacher role (home, schedules, booking, profile, evaluation, feedbacks, navigator)
│   ├── student/             # Student role (home, profile, schedule, booking, score, faculty_feedback, noti, navigator)
│   ├── profiles/            # Shared profile (admin/teacher)
│   └── data/                # Models and data exporters
├── routes/                  # Named-route definitions and bindings
├── services/                # fcm_service.dart, etc.
├── utilities/               # AssetImages and constants
└── widgets/                 # Shared UI components — see "Shared widgets" below
```

Each module follows the GetX convention: `bindings/`, `controllers/`, `views/`.

## Conventions

### 1. Every view must use the GetBuilder + LayoutBuilder shell

All view `build()` methods follow this exact shape — see `auth_view.dart` for the reference implementation:

```dart
class FooView extends GetView<FooController> {
  const FooView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<FooController>(
      builder: (controller) => LayoutBuilder(
        builder: (context, constraints) {
          return Scaffold(
            // ...
          );
        },
      ),
    );
  }
}
```

- The outer `GetBuilder<FooController>` provides the `controller` reference (shadowing `GetView.controller` — same instance).
- The inner `LayoutBuilder` exposes `constraints` for responsive layouts.
- Inner reactive state is still expressed with `Obx(() => ...)` — do **not** rewrite controllers to `update()`-based.
- For views whose controller is created on-demand, keep the registration guard *before* the `return`:

```dart
if (!Get.isRegistered<FooController>()) {
  Get.put(FooController());
}
return GetBuilder<FooController>(...);
```

Pure `StatelessWidget` sub-views with no controller (e.g., `grade_noti.dart`, `booking_detail.dart`) are exempt.

### 2. Use the shared shell widgets

Top-level role-facing views (student + teacher) share a unified visual language via widgets in `lib/app/widgets/`. Re-export through `widgets/widget.dart`. Prefer these over hand-rolling:

| Widget | Purpose |
| --- | --- |
| `AppPageScaffold` | Standard scaffold with optional `login2` background, centered `title`, optional `trailing` action |
| `AppPageTitle` | Large centered page title (replaces AppBar titles on top-level tabs) |
| `AppSectionTitle` | Small uppercase section label |
| `AppSurfaceCard` | White rounded shadowed container (with optional left-border accent / onTap) |
| `AppIconBubble` | Circular icon button used in headers (notifications, refresh) |
| `AppGreetingHeader` | Dashboard greeting row (name + subtitle + trailing) |
| `AppProfileHeader` | Avatar + name + two metadata lines, wrapped in a surface card |
| `AppInfoTile` / `AppActionTile` | Read-only / tappable rows inside an `AppSurfaceCard` |
| `AppStatCard` | Vertical white stat tile (icon + value + label) |
| `AppStatsBanner` + `AppStatItem` | Gradient banner with horizontal stats |
| `AppClassCard` | Schedule / class-list card (colored left border, title, time, location) |
| `AppSignOutButton` | Outlined red sign-out button with loading state |
| `AppFilterChipRow` + `AppFilterChip` | Horizontal scrollable filter chip row |
| `AppLoading`, `AppErrorState`, `AppEmptyState` | Standard loading / error / empty placeholders |
| `BookingCard`, `ProfileCard` | Admin-specific cards — do not reuse for student/teacher views |

### 3. Design tokens

Always use `AppColors.*` and the radius/touch-target constants exposed from it:

- `AppColors.primary` `laoBlue` `statsBlue` `bookingBlue` `successGreen` `rejectRed`
- `AppColors.borderPending` `borderApproved` (status states)
- `AppColors.textPrimary` `textSecondary` `scaffoldBg` `cardBg` `inputFill`
- `AppColors.cardRadius` `buttonRadius` `chipRadius` `minTouchTarget`

Avoid hand-rolled hex unless adding a new token to `app_colors.dart`.

### 4. Reactive state lives in controllers

- Use `RxBool`, `RxString`, `RxList`, `Rx<T>` with `.value` reads.
- Wrap reactive widget regions in `Obx(() => ...)` — keep the scope as small as practical so unrelated rebuilds don't fire.
- Do not convert to `update()`/`GetBuilder`-native state — the outer `GetBuilder` is structural only.

### 5. Background image convention

Top-level role tabs (home / schedule / booking / score) render over the `AssetImages.login2` background by setting `AppPageScaffold(withBackground: true, ...)`. List-style pages (notifications, feedback lists, profile) use the plain `AppColors.scaffoldBg`.

### 6. Lao UI strings

All user-facing text is in Lao. Don't translate or transliterate. When adding new strings, mirror nearby phrasing.

## Routing

- Routes are defined in `lib/app/routes/app_routes.dart` (SCREAMING_SNAKE_CASE constants — pre-existing, do not rename) and wired to pages in `app_pages.dart`.
- Navigation: `Get.toNamed(Routes.X)`, `Get.back()`, `Get.offAllNamed(...)`.
- Each route has a `Bindings` class that puts its controllers — controllers are usually already registered by the time a view builds, but defensive `Get.isRegistered` + `Get.put` guards inside view `build()` are accepted.

## Running and verifying

```bash
flutter pub get
flutter analyze            # must pass with zero errors / warnings
flutter run                # device required
```

When making UI changes, prefer running the app and inspecting the screen — the analyzer cannot catch visual regressions.

## Don'ts

- Do not introduce a new state-management library or wrap views in `StatefulWidget` when a `GetxController` already exists.
- Do not bypass the shared shell widgets to re-implement white-rounded-shadow containers, sign-out buttons, profile headers, etc.
- Do not edit the admin-specific `BookingCard` / `ProfileCard` for student/teacher needs — extend the shared shell widgets instead.
- Do not commit `withOpacity(...)` — use `.withValues(alpha: ...)` (Flutter `>=3.27` deprecation).
- Do not amend prior commits or force-push unless explicitly asked.
