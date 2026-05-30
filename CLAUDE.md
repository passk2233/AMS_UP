# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working in this repository.

---

## 1. Project Overview

**Project Name:** Academic Management System (AMS) — Mobile App
**Type:** Cross-platform mobile application for managing classrooms, schedules, room bookings, push notifications, and teacher evaluations across three user roles (Admin, Teacher, Student).

**You are an Expert Flutter Developer.** Your job is to implement the business logic below into the existing project. Preserve the existing folder structure under `lib/app/modules/...` — **never delete or restructure it**. Fill in logic, UI, and RESTful API integrations against the MySQL backend as specified.

---

## 2. Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter |
| State Management | GetX |
| Networking | RESTful API (GetConnect or Dio) |
| Database | **MySQL** (accessed *only* via Backend API — never direct from app) |
| Push Notifications | Firebase Cloud Messaging (FCM) — **for push only**, not as primary DB |
| Auth | API-based login returning JWT/token |

> **Hard rule:** The Flutter app must never connect directly to MySQL. All DB communication goes through the Backend REST API (`HTTP GET/POST/PUT/DELETE`). Firebase is used **only** for FCM push delivery.

---

## 3. Directory Structure

Keep the existing module-based layout:

```
lib/
└── app/
    └── modules/
        ├── admins/          # Admin role screens & controllers
        ├── teachers/        # Teacher role screens & controllers
        ├── student/         # Student role screens & controllers
        ├── data/
        │   ├── models/      # JSON-serializable models (id = int, not UUID string)
        │   ├── providers/   # API providers (per resource)
        │   └── services/    # FCMService, AuthService, base API client
        └── shared/          # Reusable widgets, dialogs (AppDialog), themes
```

When adding new features, **extend existing folders**; do not introduce parallel hierarchies.

---

## 4. Database Schema (Reference for Models)

The app consumes JSON from a backend that wraps these MySQL tables. Generate Dart models that mirror these shapes. **All IDs are `int`** (not String/UUID).

| Table | Key Columns |
|---|---|
| `users` | `id` (PK), `role` (ENUM: admin/teacher/student), `name`, `fcm_token`, `created_at` |
| `rooms` | `id` (PK), `name`, `capacity`, `status` |
| `schedules` (fixed class schedule) | `id` (PK), `room_id` (FK), `subject_id`, `teacher_id` (FK→users), `day_of_week`, `start_time`, `end_time` |
| `bookings` (room reservations) | `id` (PK), `user_id` (FK), `room_id` (FK), `booking_date`, `start_time`, `end_time`, `status` (ENUM: pending/approved/rejected), `reason` |
| `notifications` | `id` (PK), `sender_id` (FK), `target_role`, `target_user_id` (nullable FK), `title`, `body`, `created_at` |
| `evaluation_questions` | `id` (PK), `text`, `type` |
| `evaluation_results` | `id` (PK), `teacher_id` (FK), `student_id` (FK), `semester`, `scores_json` (JSON), `comments`, `created_at` |

---

## 5. Role-Based Business Logic

### 5.1 🔴 Admin Role — `lib/app/modules/admins/`

**Dashboard (`home`)**
- Call API to fetch count of pending bookings (`status = 'pending'`); display as a stat card.
- Show graph / summary of completed evaluations.

**Booking Approval (`approve`)**
- `GET` pending bookings.
- Approve / Reject buttons → `PUT` API to update status in MySQL.
- **Trigger:** Backend (not the app) sends FCM push to the requester's `fcm_token` immediately on status change.

**Announcements (`announcement`)**
- Form: Title + Body.
- **Targeting:** Everyone / Students only / Teachers only / Specific User ID or Group.
- On send → `POST` API → Backend inserts into `notifications` (history) → Backend uses Firebase Admin SDK to push FCM to matched tokens.
- Provide Notification History screen.

**Evaluations Management (`evalutions`)** *(note: existing folder spelled this way — keep it)*
- CRUD on `evaluation_questions` via API.
- View aggregate teacher scores (average computed from `evaluation_results`).

### 5.2 🔵 Teacher Role — `lib/app/modules/teachers/`

**Dashboard (`teacher_home`)**
- Today's teaching schedule via API (`schedules` JOIN `rooms` filtered by `teacher_id` + current day).
- Brief view of own room booking statuses.

**Schedules (`schedules`)**
- Full teaching schedule for the logged-in teacher.

**Room Booking** (shared booking flow)
- Teachers may book rooms outside their teaching hours.
- **Conflict check** runs on the backend before insert: SQL must verify the requested slot does **not** overlap with `schedules` or with `bookings` where `status = 'approved'`.

**View Own Evaluation Results (`teacher_evaluation`)**
- `GET /evaluations?teacher_id=currentUser.id` — see scores + comments for self only.
- **Privacy rule:** Never display `student_id` or any identifier of who submitted the evaluation. Do not even fetch it to the client.

### 5.3 🟢 Student Role — `lib/app/modules/student/`

**Dashboard (`student_home`)**
- Today's class schedule via `schedules` API.
- Badge notification if there is an evaluation pending (end-of-semester).

**Schedule (`schedule_student`)**
- Full class schedule.

**Room Booking (`Booking_student`)**
- Request a free room for an activity.
- `POST` with `status: pending` → awaits Admin approval.

**Faculty Evaluation (`faculty_feedback`)**
- **Semester-end gate:** Check `currentDate` falls within the configured end-of-semester window.
- Fetch list of teachers who taught this student → render as evaluation list.
- On submit → `POST` to `evaluation_results` → hide that teacher from the pending list.

---

## 6. Core System Logic

### 6.1 📅 Booking Validation Flow

When the user selects **room + date + start_time + end_time**:

1. App calls `POST /api/bookings/check-availability`.
2. Backend runs **two SQL queries**:
   - Conflict with `schedules` (fixed class)?
   - Conflict with `bookings` where `status = 'approved'`?
3. **If conflict** → API returns `HTTP 409 Conflict` → App shows `AppDialog` ("Room not available").
4. **If free** → App calls `POST /api/bookings` to create a new booking with `status = pending`.

Do not duplicate this validation on the client; let the backend be authoritative.

### 6.2 🔔 FCM Push Notifications — `fcm_service.dart`

**Initialization & Token Sync**
- Even though the primary DB is MySQL, push delivery still uses Firebase.
- On successful login: `FirebaseMessaging.instance.getToken()` → `PUT /api/users/fcm-token` to persist into `users.fcm_token`.
- Refresh the token on `onTokenRefresh`.

**Message Handlers**
- `FirebaseMessaging.onMessage` (foreground): show in-app Snackbar or Local Notification.
- `FirebaseMessaging.onBackgroundMessage` (background/terminated): wire a top-level handler.

**Sending side**
- The app **never sends FCM directly**. The backend triggers FCM through Firebase Admin SDK after the relevant DB write (booking approval, announcement, etc.).

---

## 7. Mobile UI/UX Standards

All generated screens must meet these standards. Treat them as non-negotiable.

### 7.1 Prime Directives

- **Mobile-first.** Design for 375×812 pt (iOS) / 360×800 dp (Android) baseline. Prioritize essential content; use progressive disclosure.
- **Accessibility (WCAG 2.1 AA):**
  - Contrast ≥ 4.5:1 for body text, ≥ 3:1 for large text / UI components.
  - Touch targets ≥ 44×44 pt (iOS) / 48×48 dp (Android), with ≥ 8 pt spacing between interactive elements.
  - Minimum legible body font size: 16 px.
- **Consistency over creativity.** Re-use patterns; don't invent new paradigms for standard interactions.
- **Context-aware.** A data-entry form is laid out differently from a feed — analyze screen purpose first.

### 7.2 Layout & Spacing

- **8-point grid** for all margins, padding, sizing (8, 16, 24, 32, 40, 48 …).
- **Screen horizontal margin:** 16 pt or 24 pt — pick one and apply consistently across the whole app.
- **Vertical rhythm:** 8/16 pt within a group; 32/48 pt between distinct sections.

### 7.3 Page Hierarchy

- **App Bar (top):** clear title; left = back/menu; right = primary screen action (Edit / Save / Search).
- **Body:** most important info at top; vertical scroll only (no horizontal scroll except carousels).
- **Bottom:** sticky full-width primary CTA where applicable; bottom tab bar limited to **3–5** top-level destinations.

### 7.4 Components

**Forms**
- Large tap areas; labels **above** the field.
- Set the right keyboard type per input (numeric, email, phone).
- Scroll the active field into view when the keyboard appears.
- Inline validation; human-readable error messages adjacent to the field.

**Buttons / CTAs**
- **Primary:** solid, high contrast — **one per screen** usually.
- **Secondary:** outlined or subtle background.
- **Tertiary:** text-only or icon-only.
- Place primary CTAs in the **bottom half** (thumb-reachable).

**Lists / Cards**
- Lists for dense data, cards for grouped/mixed-media content.
- The **whole row/card** is the tap target — not just the text.

**Imagery**
- Optimize for size; always provide a placeholder/skeleton while loading.

### 7.5 Visual Language

- **Primary/brand color:** used sparingly on primary actions and active states.
- **Backgrounds:** white or very light gray (light mode); dark gray/black (dark mode).
- **Text:** near-black (e.g., `#1A1A1A`) for primary, medium gray for secondary. **Never** pure `#000000` on pure `#FFFFFF`.
- **Semantic colors:** success = green, warning = yellow/orange, error = red.
- **Typeface:** system fonts (SF Pro on iOS, Roboto/Inter on Android) or one highly legible sans-serif.
- **Type scale:** Title 24/Bold · Heading 18/Semibold · Body 16/Regular · Caption 12/Regular.

### 7.6 Required Screen States

Every screen must define all four states — never ship only the "happy path":

- **Loading:** skeleton screens or spinners; never a blank screen.
- **Empty:** explain why it's empty + suggest an action ("You have no messages. Tap here to start a new chat.").
- **Error:** plain language ("Network connection lost."), never `Error 404`. Provide retry.
- **Success / feedback:** button press states, brief toast/snackbar on save.

---

## 8. Implementation Roadmap

Work in this order:

1. **Models & API services.** Update `lib/app/modules/data/models/` to match the MySQL JSON shapes (`id: int`). Build a base API client (GetConnect/Dio) and `FCMService`.
2. **Auth flow.** API login → store JWT → on success, push the device FCM token via `PUT /api/users/fcm-token`.
3. **Admin features.** Dashboard stats, booking approval queue, announcement composer + history.
4. **Student & Teacher features.** Role dashboards and schedule views (from `schedules` API).
5. **Booking logic.** Booking form + handle `409 Conflict` response via `AppDialog`.
6. **Evaluation logic.** Student submission form; teacher/admin result views via API.

---

## 9. Conventions & Hard Rules

- ✅ **Always** route data access through Backend REST API.
- ✅ **Always** treat IDs as `int`, never UUID strings.
- ✅ **Always** generate loading / empty / error variants for every screen.
- ✅ **Always** use 8-pt spacing and 44/48 pt minimum touch targets.
- ✅ Use `AppDialog` (existing shared widget) for blocking error/info dialogs.
- ❌ **Never** delete or restructure the existing `lib/app/modules/...` layout.
- ❌ **Never** connect directly from Flutter to MySQL.
- ❌ **Never** trigger FCM sends from the client — only the backend pushes.
- ❌ **Never** expose `student_id` to teachers in evaluation results.
- ❌ **Never** invent new UI patterns where a standard mobile pattern fits.
- ❌ **Never** use pure black on pure white.

---

## 10. Generation Workflow (per screen)

When asked to build a screen, follow these steps before writing code:

1. **Analyze intent** — what is the user actually trying to do here?
2. **Pick an archetype** — list / form / detail view / dashboard.
3. **Map data + actions to components** — inputs, buttons, cards.
4. **Apply the 8-pt grid** to spacing and sizing.
5. **Check accessibility** — touch targets, contrast, font size.
6. **Design the alternate states** — loading, empty, error.
7. **Wire the API** — controller (GetX) → provider → JSON model.