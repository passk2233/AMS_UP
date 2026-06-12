---
target: all pages — AMS UP Flutter app (admin/teacher/student)
total_score: 26
p0_count: 0
p1_count: 3
timestamp: 2026-06-03T11-43-12Z
slug: all-pages-ams-up-flutter-app-admin-teacher-student
---
# Critique — All pages (AMS UP Flutter app: admin / teacher / student)

**Method note.** This is a Flutter/Dart codebase, so the standard browser + `detect.mjs` markup scan does not apply. Assessment B was run as a deterministic *code* audit (ripgrep against DESIGN.md's measurable rules: banned hex, contrast pairings, the 4px-stripe ban, shadow rule, the 16px/12px type floors) across all 31 views + the shared widget layer. No live render was performed (the app needs the Go/MariaDB backend + an emulator), so contrast figures are computed from the committed color values, not screenshots.

## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 3 | Excellent state coverage (16 skeleton variants, retry, badges); weakened only by failing-contrast status pills |
| 2 | Match System / Real World | 2 | Lao-first everywhere except booking status pills (raw lowercase English API enums) + BookingCard "Approve/Reject/(Student)" + grade_noti jargon |
| 3 | User Control & Freedom | 3 | Confirmation dialogs, cancel, back, filter-clear, disabled-submit guards |
| 4 | Consistency & Standards | 2 | Two parallel component vocabularies (shared system vs raw Material in booking); inconsistent status-color language |
| 5 | Error Prevention | 3 | Client conflict pre-check + inline warnings, past-time guards, bounded pickers, required markers |
| 6 | Recognition Rather Than Recall | 3 | Labeled bottom nav, labels-above-field, filter chips, purpose presets, today/tomorrow badges |
| 7 | Flexibility & Efficiency | 3 | Quick-action shortcuts, filter chips, pull-to-refresh, remember-me; no power accelerators (fine on mobile) |
| 8 | Aesthetic & Minimalist | 2 | Calm shared system undercut by the rainbow subject palette, 4-color transcript strip, off-brand purple |
| 9 | Error Recovery | 3 | Plain-language AppErrorState + retry everywhere; raw codes tucked in an optional detail panel, not shown by default |
| 10 | Help & Documentation | 2 | Tooltips + helper slots + teaching empty states; no onboarding (acceptable for the domain) |
| **Total** | | **26/40** | **Acceptable — strong bones, craft is inconsistent** |

## Anti-Patterns Verdict

**Does this look AI-generated? No — and that is the headline.** The project has a committed, documented identity (teal-led, mist-gray scaffold, a closed amber/emerald/red status vocabulary, Lao-first copy), genuine four-state coverage on every data screen, and thoughtful domain logic. It passes the *brand*-slop test easily. It does not fully pass the *product*-slop test ("would a user fluent in the category trust every component") — they would pause at the booking screens (which look like a different app), the rainbow class cards, amber numbers that are hard to read, and raw English status enums.

**Deterministic scan (Dart audit):**
- **0** retired hex values (`#4c4ddc/4a68ff/4a80f0/3a3bbf/10b981/27ae60/4caf50`) — the palette consolidation held. ✅
- **0** deprecated `.withOpacity(` — fully migrated to `.withValues`. ✅
- **26** off-token Material named colors across 7 files — `Colors.purple` (×4), `Colors.teal`, `Colors.green/orange/red` as status, `Colors.indigo`. These reintroduce the retired hues *by name* (`Colors.green` IS `#4caf50`).
- **98** raw `Colors.grey.shadeXXX` uses across 21 files; many are text below the `#6B7280` floor.
- **~30** `fontSize: 11` occurrences (below the stated 12px floor), worst when paired with `grey.shade400` (≈1.9:1) in `evalutions_view` and `announcement_*`.
- Gradients are all same-hue tonal or the sanctioned teal→blue brand bar — **no SaaS purple gradient**. ✅

**Visual overlays:** none — browser injection is not applicable to Flutter source, so no `[Human]`-tab overlay is available. The findings below cite `file:line` instead.

## Overall Impression

This is a well-architected design system with a few screens that did not get the memo. The shared layer (`app_colors`, `app_typography`, `AppSurfaceCard`, `AppTextField`, `AppDialogs`, `AppLoading`'s 16 skeleton variants, `AppBottomNav`) is genuinely good — tokenized, AA-aware in its comments, Lao-localized. The failure mode is not "no designer," it's "two designers": the polished system, and a handful of high-traffic flows (booking, parts of evaluations/score) that bypass it with raw Material widgets and off-token colors. The single biggest opportunity: **make the screens obey the system that already exists.** Most fixes are swapping a literal for a token, not inventing anything.

The most damaging thread runs straight at the product's core promise — "confidence in the data." The app's most important numbers and states (admin pending/approved hero, student GPA, grade letters, booking status) are rendered in the two color pairings DESIGN.md explicitly flags as failing AA: white-on-bright-teal (#40b4cd, 2.43:1) and amber-as-text (#f59e0b, ~2.2:1). The system predicted this exact mistake; the hero screens commit it anyway.

## What's Working

1. **Every state is genuinely designed.** `AppLoading` ships 16 content-shaped skeletons (`dashboard`, `adminApprove`, `score`…), `AppErrorState` gives plain-Lao messages + "ລອງໃໝ່" retry, `AppEmptyState` teaches the next action, and `booking_student_view` even varies its empty copy/CTA by whether the list is truly empty vs filter-empty. This is the rarest thing to get right and it is right.
2. **The auth screen is exemplary.** [auth_view.dart](lib/app/modules/auth/views/auth_view.dart) is fully tokenized, Lao-first, responsive (max-width clamp for tablet/web), 48dp targets, password toggle with tooltip, loading state on submit. Ship it as-is.
3. **Error prevention in the booking flow is thoughtful.** Client-side conflict + past-time pre-checks with inline warnings, disabled submit until valid, a 24-hour time picker, and date bounds — real care for a high-stakes action.

## Priority Issues

### [P1] Key numbers & status render in AA-failing color pairings
**Why it matters:** This hits the product's whole reason to exist — trusting the data — and it lands on the highest-value elements. White text sits on the bright `AppColors.primary` (#40b4cd, 2.43:1) on the admin dashboard hero [dashboard_profile_cart.dart:45](lib/app/widgets/dashboard_profile_cart.dart) and the GPA cell of the transcript strip [score_view.dart:66](lib/app/modules/student/score/views/score_view.dart); amber (#f59e0b, ~2.2:1) is used as *text* for the GPA stat value [home_page.dart:85](lib/app/modules/student/student_home/views/home_page.dart), grade letters incl. **F** [score_view.dart:302](lib/app/modules/student/score/views/score_view.dart), and 2 of 4 booking stat tiles [booking_student_view.dart:152](lib/app/modules/student/Booking_student/views/booking_student_view.dart). DESIGN.md names both pairings as failures and provides the fixes.
**Fix:** Swap `AppColors.primary` → `AppColors.primaryFill` (#1f7e93, 4.70:1) anywhere white text/icons sit on a teal fill or gradient; for amber, either use ink-on-amber (as `AppSnackbar.warning` already correctly does) or render the *number* in `textPrimary` and reserve amber for a small badge.
**Suggested command:** `/impeccable colorize`

### [P1] The booking flow bypasses the design system
**Why it matters:** Booking is a primary task for both students and teachers, and it looks like a different app. [booking_student_view.dart](lib/app/modules/student/Booking_student/views/booking_student_view.dart) and its twin [booking_view.dart](lib/app/modules/teachers/booking/views/booking_view.dart) use raw `Card` / `ListTile` / `ChoiceChip` / `ActionChip` and bare `TextField`s with `border: OutlineInputBorder()` — which *explicitly overrides* the app's themed filled inputs — instead of `AppSurfaceCard` / `AppFilterChipRow` / `AppTextField`. Status is mapped to off-token `Colors.green/red/orange` whose 11px pill text fails contrast (~2.0–2.6:1), and the pill prints the **raw lowercase English API string** (`Text(status)` → "pending"/"approved") in a Lao-first UI.
**Fix:** Rebuild both booking lists on `AppSurfaceCard` + the existing `BookingCard`/status-pill vocabulary; route the create form's fields through `AppTextField`; map status to the three tokens via a single `statusColor()`/`statusLabelLao()` helper.
**Suggested command:** `/impeccable polish`

### [P1] A decorative rainbow palette collides with the closed status vocabulary
**Why it matters:** `_TodaysClasses._palette` rotates `Colors.purple, statsBlue, emerald, amber, red, Colors.teal` across class cards [teacher_home_view.dart:287](lib/app/modules/teachers/teacher_home/views/teacher_home_view.dart), echoed in [schedule_student_controller.dart:220](lib/app/modules/student/schedule_student/controllers/schedule_student_controller.dart) and [schedules_controller.dart:315](lib/app/modules/teachers/schedules/controllers/schedules_controller.dart). DESIGN.md makes amber/emerald/red a *closed status vocabulary* — so a green or amber class card reads as "approved"/"pending" when it means nothing. `Colors.purple` is the exact "generic AI SaaS" hue the brand rejects, and because `AppClassCard` paints its **title** in this color [app_cards.dart:425](lib/app/widgets/app_cards.dart), amber/Material-teal titles also fail contrast.
**Fix:** Drop the rainbow. Tint all class cards with one neutral brand accent (Faculty Teal/Info Blue) as `home_page.dart` already does, or derive a tint from a non-semantic hue ramp that excludes the status three. Delete `Colors.purple`/`Colors.teal`/`Colors.indigo` entirely.
**Suggested command:** `/impeccable colorize`

### [P2] Pervasive grey-below-floor text and sub-12px type
**Why it matters:** Legibility erodes app-wide. 98 `Colors.grey.shadeXXX` uses and ~30 `fontSize: 11` instances; the worst combine both — e.g. `fontSize: 11, color: Colors.grey.shade400` (≈1.9:1, effectively invisible) recurs in [evalutions_view.dart:676](lib/app/modules/admins/evalutions/views/evalutions_view.dart) and [announcement_history_view.dart:526](lib/app/modules/admins/announcement/views/announcement_history_view.dart). The shared `AppEmptyState` subtitle itself uses `grey.shade400` at 13px [app_empty_state.dart:52](lib/app/widgets/app_empty_state.dart). DESIGN.md sets `#6B7280` as the lightest text and a hard 12px floor.
**Fix:** Replace text greys with `AppColors.textSecondary`; lift any `fontSize: 11` carrying real content to 12 (caption). Keep grey only for decorative icons/hairlines.
**Suggested command:** `/impeccable audit`

### [P2] Status semantics are inconsistent within and across cards
**Why it matters:** The product's trust principle depends on status being *honest and legible*. Today the language contradicts itself: in `BookingCard` an approved booking shows an **emerald left border but a blue check icon** [booking_cart.dart:191](lib/app/widgets/booking_cart.dart); its role pill uses off-palette `Colors.blue.shade50`/`Colors.orange.shade*` [booking_cart.dart:248](lib/app/widgets/booking_cart.dart); and on the grades screen a failing **F is amber** (same as C/D) with no red [score_view.dart:298](lib/app/modules/student/score/views/score_view.dart).
**Fix:** One status mapping shared across booking cards, lists, and grade badges: emerald=approved/pass, amber=pending, red=rejected/fail. Give F red. Retire the blue "approved" icon and the raw blue/orange role pills.
**Suggested command:** `/impeccable clarify`

## Persona Red Flags

**Sam (accessibility / low vision):** The GPA, the grade letters, and most booking status pills fall below 4.5:1 (amber ≈2.2:1, `Colors.green` ≈2.3:1, `Colors.orange` ≈2.0:1). Booking status is also conveyed by color + a raw word alone with no icon differentiation. `grey.shade400` 13px empty-state subtitles are invisible. This is the persona the current build fails hardest.

**Noi (Lao-first student — project persona):** Opens the app for a 10-second check and meets English where everything else is Lao: the booking status pill says "pending" not "ລໍຖ້າ", and `grade_noti` shows "Database transcript data synchronized" [grade_noti.dart:92](lib/app/modules/student/student_noti/views/grade_noti.dart). The rainbow class cards give her color cues that mean nothing.

**Casey (distracted mobile, one thumb):** Well served structurally — bottom FAB for "ຈອງໃໝ່", bottom nav, pull-to-refresh, bottom-sheet form. Hurt by the 11px metadata and low-contrast numbers that are hard to parse at a glance in a hallway.

## Minor Observations
- Admin app bar shadow is `Color(0x40000000)` (25% black) [admin_app_bar.dart:35](lib/app/widgets/admin_app_bar/admin_app_bar.dart) — ~3× the 8% Soft-Shadow Rule cap.
- Semester chip uses `elevation: selected ? 4 : 0` [score_view.dart:128](lib/app/modules/student/score/views/score_view.dart) — a Material elevation tier the system bans.
- `white70` 12px labels on the stats banner [app_cards.dart:343](lib/app/widgets/app_cards.dart) sit ~3.2:1 on info-blue — fine on blue, risky if the banner ever uses a lighter fill.
- Login header + footer caption render over a photo background [auth_view.dart:95](lib/app/modules/auth/views/auth_view.dart) — contrast depends on the asset; verify on-device.
- `AppFilterChipRow` defaults `activeColor` to the deprecated `statsBlue` alias [app_buttons.dart:337](lib/app/widgets/app_buttons.dart); resolves correctly to Info Blue but the chip doc comment still cites the retired `#4a68ff`.

## Questions to Consider
- The shared `BookingCard` already encodes status correctly — why do the booking *lists* re-implement it with raw Material instead of reusing it?
- If amber/emerald/red are a closed status language, what non-semantic hue should "category/subject" use so a class card never looks like a booking state?
- Grades are emotional. Should an F look visually distinct (red) from a C, or is the uniform warm treatment intentional to soften it?
