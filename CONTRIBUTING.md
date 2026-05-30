# Contributing

> Guidelines for working on `ams-up`. Read this before opening a pull request — it'll save everyone time.

---

## Table of Contents

1. [Getting Started](#getting-started)
2. [Branch & Commit Strategy](#branch--commit-strategy)
3. [Code Style](#code-style)
4. [Adding a New Feature Module](#adding-a-new-feature-module)
5. [Adding a New Model](#adding-a-new-model)
6. [Pull Request Checklist](#pull-request-checklist)
7. [Reporting Bugs](#reporting-bugs)

---

## Getting Started

If you haven't already, follow [SETUP.md](./SETUP.md) to get the project running. Then:

```bash
git checkout -b feat/<short-description>
flutter pub get
flutter analyze
flutter run
```

## Branch & Commit Strategy

| Branch | Purpose |
|---|---|
| `main` | Always deployable. Protected. Merges only from PRs. |
| `develop` (if used) | Integration branch for the next release. |
| `feat/<name>` | New feature work. |
| `fix/<name>` | Bug fix. |
| `chore/<name>` | Refactors, doc updates, dependency bumps. |

**Commit message style** — short imperative subjects, optional body:

```
feat(admin): add bulk approval to booking list

- Multi-select bookings with checkboxes
- Batch PATCH endpoint not yet wired; falls back to sequential calls
```

Prefixes commonly used: `feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `style`.

## Code Style

The project uses `package:flutter_lints/flutter.yaml` (see `analysis_options.yaml`). Run before pushing:

```bash
flutter analyze
dart format .
```

### Dart conventions

- **2-space indentation**, no tabs.
- `const` constructors and literals wherever possible.
- Prefer `final` over `var`.
- Trailing commas in multi-line argument lists — Dart formatter relies on them.
- Avoid `print`; use `debugPrint` for development logs.

### File & folder naming

- Files: `snake_case.dart`.
- Classes: `PascalCase`. Views end in `View`, controllers in `Controller`, bindings in `Binding`, models in `Model`.
- One public class per file unless tightly coupled (e.g. helper classes for a controller).

### GetX conventions

- Register controllers in a **`Bindings`** class — do not call `Get.put` inside a `build()` method except as a safety net like:

  ```dart
  if (!Get.isRegistered<MyController>()) Get.put(MyController());
  ```

- Use `Obx(() => ...)` for reactive rebuilds. Don't mix `setState` with GetX state in the same widget.
- Reactive fields go on the controller and are accessed via `Get.find<C>()` or `GetView<C>.controller`.
- Use `Rx<T>` for nullable observables and `Rx<T?>` only when null is meaningful.

### Networking

- Always pass the bearer token: `_dio.options.headers['Authorization'] = 'Bearer $_token'`.
- Always `try { ... } on DioException` and route to `AppDialogs.showError(...)`.
- Re-use the `_extractList(data)` helper for list endpoints that may return either `[...]` or `{ "data": [...] }`.
- Never hard-code the base URL — read from `dotenv.env['API_URL']`.

### UI

- Pull colors from `AppColors`. If a new colour is genuinely needed, add it to `app_colors.dart` rather than inlining `Color(0x...)`.
- For success / warning / error / confirmation flows, use `AppDialogs` instead of `Get.snackbar` so the UX stays consistent.
- For Lao text, keep it as Dart string literals — do **not** machine-translate UI strings without review by a native speaker.
- New widgets that are reused should live under `lib/app/widgets/` and be re-exported from `widget.dart`.

## Adding a New Feature Module

The project uses `get_cli` conventions. The fastest path:

```bash
get create page:my_feature
```

If you'd rather do it by hand, create:

```
lib/app/modules/<role>/<my_feature>/
├── bindings/my_feature_binding.dart
├── controllers/my_feature_controller.dart
└── views/my_feature_view.dart
```

Then:

1. Add a route in `lib/app/routes/app_routes.dart`:

   ```dart
   static const MY_FEATURE = _Paths.MY_FEATURE;
   // ...
   static const MY_FEATURE = '/my-feature';
   ```

2. Register the page in `lib/app/routes/app_pages.dart`:

   ```dart
   GetPage(
     name: _Paths.MY_FEATURE,
     page: () => const MyFeatureView(),
     binding: MyFeatureBinding(),
   ),
   ```

3. Wire it into the relevant shell if it should appear as a tab (`AdminShellView`, `TeacherShellView`, or `HomeStudentController.pages`).

## Adding a New Model

When the backend exposes a new entity:

1. Create `lib/app/modules/data/models/my_thing_model.dart` mirroring the DB schema.
2. Implement `fromJson` and `toJson` with safe defaults (`?? 0`, `?? ''`).
3. Nest related models the backend preloads.
4. Export it from `lib/app/modules/data/data_exporter.dart`:

   ```dart
   export 'models/my_thing_model.dart';
   ```

5. Add a row to the relevant table in [DATABASE_SCHEMA.md](./DATABASE_SCHEMA.md) if missing.
6. Add the endpoint(s) you'll consume to [API.md](./API.md).

Template:

```dart
class MyThingModel {
  int id;
  String name;
  DateTime? createdAt;

  MyThingModel({
    required this.id,
    required this.name,
    this.createdAt,
  });

  factory MyThingModel.fromJson(Map<String, dynamic> json) {
    return MyThingModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'created_at': createdAt?.toIso8601String(),
      };
}
```

## Pull Request Checklist

Before requesting review, tick every box that applies:

- [ ] `flutter analyze` passes with no new warnings.
- [ ] `dart format .` has been run.
- [ ] The change targets the correct branch (`main` or `develop`).
- [ ] New screens have both a `View`, `Controller`, and `Binding`.
- [ ] New endpoints documented in [API.md](./API.md).
- [ ] New routes documented in [ROUTES.md](./ROUTES.md).
- [ ] New models exported from `data_exporter.dart`.
- [ ] User-facing strings are in Lao where the surrounding screen already is.
- [ ] No hard-coded API URLs, secrets, or test tokens.
- [ ] No `print()` left behind — use `debugPrint` if needed.
- [ ] Screenshots / screen recordings attached for UI-visible changes.
- [ ] Tested on at least one Android device or emulator.

## Reporting Bugs

When opening an issue, include:

1. **What you did** — exact steps.
2. **What you expected.**
3. **What actually happened** — copy/paste any error dialog detail panel content (it includes status code, URL, and response body).
4. **Environment** — Flutter version (`flutter --version`), device, OS version.
5. **Backend version / git SHA** if known.

Screenshots and logs go a long way.

---

Thanks for contributing! For any architectural question, see [ARCHITECTURE.md](./ARCHITECTURE.md). For role-specific feature behaviour, see [FEATURES.md](./FEATURES.md).