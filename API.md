# API Reference (Client-Side)

> Every backend endpoint consumed by the Flutter client, with the controller(s) that call it, expected payloads, and notable behaviours.

> This document describes the API **as the mobile client expects it**. The authoritative server-side reference belongs in the Go backend repo.

---

## Conventions

- **Base URL:** `${API_URL}` from `.env`.
- **Content-Type:** `application/json`.
- **Auth:** all routes except `POST /auth/login` require `Authorization: Bearer <jwt>`.
- **Extra header:** `ngrok-skip-browser-warning: true` is always sent (harmless against non-ngrok backends).
- **Pagination:** when a list endpoint accepts `limit`, the client passes 50–500 depending on the screen.
- **Response shape:** the client tolerates both `[ ... ]` and `{ "data": [ ... ], "meta": { ... } }` envelopes via this helper:

  ```dart
  static List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map && data['data'] is List) return data['data'] as List;
    return const [];
  }
  ```

---

## Authentication

### `POST /auth/login`

Authenticates a user and returns a JWT plus the user blob.

**Request body**

```json
{
  "username": "alex",
  "password": "secret",
  "device_token": "fcm-token-or-null",
  "platform": "android | ios | web | unknown"
}
```

**Response (200)**

```json
{
  "token": "eyJhbGciOi...",
  "user": {
    "id": 1,
    "username": "alex",
    "email": "alex@example.com",
    "roles": ["Administrator"],
    "student": null,
    "teacher": null
  }
}
```

Used by: `AuthController.login()`.

---

### `GET /auth/me`

Returns the currently authenticated user, including nested `student` or `teacher` and the `roles` array.

Used by virtually every controller to bootstrap user context: `AdminHomeController`, `BookingController`, `BookingStudentController`, `ProfileStudentController`, `ProfilesController`, `ScoreController`, `ScheduleStudentController`, `FeedbacksController`, `FacultyFeedbackController`, `SchedulesController`, `TeacherEvaluationController`, `TeacherHomeController`.

On a `401`, the client clears the token and redirects to `/auth`.

---

## Reference Data

### `GET /departments`

Query: `limit`.

Returns `DepartmentModel[]`. Used by the announcement composer to populate the department dropdown.

### `GET /student-groups`

Query: `limit`.

Returns `StudentGroupModel[]`. Used by the announcement composer.

### `GET /student-types`

No query. Returns `StudentTypeModel[]`. Used by the announcement composer.

### `GET /students/:id`

Returns a single `StudentModel`. Used by the announcement composer's "individual" lookup. Tolerates both `{ data: {...} }` and a flat object.

### `GET /teachers`

Query: `limit`. Returns `TeacherModel[]`. Used by `EvalutionController` to enrich aggregated results.

### `GET /teachers/:id`

Returns a single `TeacherModel`. Used by `TeacherEvaluationController` to load the current teacher.

### `GET /semasters`

Query: `limit`. Returns `SemasterModel[]`.

The client picks the active semester with this fallback order:

1. The first semester whose `start_date <= now <= end_date`.
2. The first semester with `status == 1`.
3. The most recent semester returned.

Used by `AdminHomeController` and `AdminAppBarControllers`.

### `GET /rooms`

Query: `limit`. Returns `RoomModel[]`. Used by booking screens and the admin dashboard.

---

## Room Bookings

### `GET /room-bookings`

Query: `limit`, optional `status` (`pending`, `approved`, `rejected`).

Returns `RoomBookingModel[]` with nested `room` and `user` (which itself nests `student` or `teacher`).

Used by `AdminHomeController`, `ApproveController`, `BookingController`, `BookingStudentController`.

### `POST /room-bookings`

Create a new booking request (defaults to `pending` server-side).

**Request body**

```json
{
  "room_id": 12,
  "user_id": 7,
  "booking_date": "2026-05-13T00:00:00Z",
  "start_time": "08:30",
  "end_time": "10:00",
  "purpose": "Team meeting"
}
```

Notes:

- `booking_date` is sent as **RFC 3339 UTC** (`.toUtc().toIso8601String()`).
- `start_time` / `end_time` are validated client-side against `^([01]\d|2[0-3]):[0-5]\d$` and `start < end`.

Used by `BookingController.createBooking` and `BookingStudentController.createBooking`.

### `PATCH /room-bookings/:bookingId/status`

Approve or reject a booking.

**Request body**

```json
{ "status": "approved" }
```

Or `{ "status": "rejected" }`. The client updates local state optimistically and refreshes the app-bar badge through `AdminAppBarControllers.refreshData()`.

Used by `AdminHomeController` and `ApproveController`.

---

## Notifications

### `GET /notifications`

Query: `limit`.

Returns `NotificationModel[]`. Used by `AnnouncementController` (admin history) and `StudentNotiController`.

### `POST /notifications`

Broadcast a new notification. The `type` field encodes the target audience as a human-readable string built by `AnnouncementController._buildNotificationType()`, for example:

- `"ທັງໝົດ"` — all users
- `"ນັກສຶກສາ | ພາກ: ... | ກຸ່ມ: ... | ປະເພດ: ... | ປີ ..."` — filtered students
- `"ອາຈານ | ພາກ: ..."` — filtered teachers
- `"ບຸກຄົນສະເພາະ | ID: 7 | <name>"` — individual

**Request body**

```json
{
  "title": "Class cancelled",
  "message": "Tomorrow's class is cancelled.",
  "type": "ນັກສຶກສາ | ພາກ: ... | ກຸ່ມ: ..."
}
```

The backend is expected to fan this out via FCM using stored `user_devices` tokens.

Used by `AnnouncementController.sendNotification`, `editNotification` (delete-then-create), and `resendNotification`.

### `DELETE /notifications/:notiId`

Removes a notification. Used by `AnnouncementController.deleteNotification` and the edit flow.

---

## Evaluations

### `GET /evaluation-questions`

Query: `limit`, optional `is_active=1`.

Returns `EvaluationQuestionModel[]`. Used by:

- `EvalutionController` (admin CRUD list)
- `FacultyFeedbackController` (active-only, shown to students)
- `TeacherEvaluationController` (full list for context)

### `POST /evaluation-questions`

```json
{ "question": "...", "category": "Teaching", "is_active": 1 }
```

### `PUT /evaluation-questions/:id`

Update text, category, or toggle active state.

### `DELETE /evaluation-questions/:id`

Used by `EvalutionController`.

### `GET /evaluation-results`

Query: `limit`, optional `study_plan_id`, `student_id`.

Returns `EvaluationResultModel[]`. Used by:

- `EvalutionController` — full pull for teacher aggregation.
- `TeacherEvaluationController` — same pull, then filtered by the teacher's own study plans.
- `FeedbacksController` — comments only.
- `FacultyFeedbackController` — "has this student already submitted?" check.

### `POST /evaluation-results`

```json
{
  "study_plan_id": 42,
  "student_id": 7,
  "eva_question_id": 3,
  "score": 5,
  "comment": "Great teacher"
}
```

The client posts **one row per question** when a student submits their feedback (`FacultyFeedbackController.submitFeedback`). Only the first row carries a `comment`; subsequent rows pass `null`.

---

## Study Plans

### `GET /study-plans`

Query: `limit`, optional `teacher_id`, `std_group_id`.

Returns `StudyPlanModel[]` with these preloads expected:

- `semaster`
- `subject` (with `curriculum`)
- `student_group`
- `teacher` (with `department`)
- `room`

Notable behaviour: the client **falls back to client-side filtering** when `teacher_id` is supplied but the backend returns zero results — it then re-fetches without the filter and filters in Dart. See `SchedulesController.fetchSchedules`, `FeedbacksController.fetchFeedbacks`, `TeacherHomeController.fetchDashboard`, and `TeacherEvaluationController._loadData`.

---

## Enrollments

### `GET /enrollments`

Query: `limit`, optional `std_id`.

Returns `EnrollmentModel[]` with nested `study_plan.subject.curriculum` and `study_plan.teacher`. Used by `ScoreController` to build the student's transcript and compute GPA.

---

## Endpoint × Controller Index

| Endpoint | Controllers |
|---|---|
| `POST /auth/login` | `AuthController` |
| `GET /auth/me` | almost every controller (see above) |
| `GET /departments` | `AnnouncementController` |
| `GET /student-groups` | `AnnouncementController` |
| `GET /student-types` | `AnnouncementController` |
| `GET /students/:id` | `AnnouncementController` |
| `GET /teachers` | `EvalutionController` |
| `GET /teachers/:id` | `TeacherEvaluationController` |
| `GET /semasters` | `AdminHomeController`, `AdminAppBarControllers` |
| `GET /rooms` | `AdminHomeController`, `BookingController`, `BookingStudentController` |
| `GET /room-bookings` | `AdminHomeController`, `ApproveController`, `AdminAppBarControllers`, `BookingController`, `BookingStudentController`, `TeacherHomeController` |
| `POST /room-bookings` | `BookingController`, `BookingStudentController` |
| `PATCH /room-bookings/:id/status` | `AdminHomeController`, `ApproveController` |
| `GET /notifications` | `AnnouncementController`, `StudentNotiController` |
| `POST /notifications` | `AnnouncementController` |
| `DELETE /notifications/:id` | `AnnouncementController` |
| `GET /evaluation-questions` | `EvalutionController`, `FacultyFeedbackController`, `TeacherEvaluationController` |
| `POST /evaluation-questions` | `EvalutionController` |
| `PUT /evaluation-questions/:id` | `EvalutionController` |
| `DELETE /evaluation-questions/:id` | `EvalutionController` |
| `GET /evaluation-results` | `EvalutionController`, `TeacherEvaluationController`, `FeedbacksController`, `FacultyFeedbackController` |
| `POST /evaluation-results` | `FacultyFeedbackController` |
| `GET /study-plans` | `EvalutionController`, `SchedulesController`, `FeedbacksController`, `TeacherHomeController`, `TeacherEvaluationController`, `ScheduleStudentController`, `FacultyFeedbackController` |
| `GET /enrollments` | `ScoreController` |

---

## Error Handling

Every Dio call is wrapped in `try { ... } on DioException catch (e) { ... }`. The client distinguishes:

| Condition | Behaviour |
|---|---|
| `401 Unauthorized` | Clear token from `shared_preferences`, redirect to `/auth`. |
| `connectionError` | Show "Cannot connect to server" with a Retry button. |
| `connectionTimeout` / `receiveTimeout` | Show timeout warning. |
| Other `DioException` | Show `AppDialogs.showError` with the response body in a detail panel. |

The helper `AppDialogs.buildDioErrorDetail(e)` formats status, body, type, and URL for the dialog.