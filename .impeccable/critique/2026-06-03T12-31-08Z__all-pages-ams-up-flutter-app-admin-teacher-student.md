---
target: all pages — AMS UP Flutter app (admin/teacher/student)
total_score: 29
p0_count: 0
p1_count: 0
timestamp: 2026-06-03T12-31-08Z
slug: all-pages-ams-up-flutter-app-admin-teacher-student
---
# Critique (re-run) — All pages (AMS UP Flutter app: admin / teacher / student)

Re-run after the colorize / clarify / typeset / audit / booking-rebuild passes. Same method as the baseline: deterministic Dart audit (ripgrep against DESIGN.md's measurable rules) + design re-review. `flutter analyze` clean throughout (49 pre-existing info lints, 0 introduced).

## Design Health Score

| # | Heuristic | Score | Δ | Key Issue (now) |
|---|-----------|-------|---|-----------------|
| 1 | Visibility of System Status | 3 | — | Strong; status now AA + Lao + consistent across cards/lists |
| 2 | Match System / Real World | 3 | +1 | Booking status + grade-notification localized; raw English enums gone |
| 3 | User Control & Freedom | 3 | — | Confirmation dialogs, cancel, back, filter-clear |
| 4 | Consistency & Standards | 3 | +1 | Booking now on shared components; one status helper; palette consolidated. Residual: form floating-labels vs label-above standard; announcement audience `ChoiceChip` |
| 5 | Error Prevention | 3 | — | Conflict pre-check, past-time guards, bounded pickers |
| 6 | Recognition Rather Than Recall | 3 | — | Labeled nav, labels above fields, consistent chips |
| 7 | Flexibility & Efficiency | 3 | — | Quick-actions, filters, pull-to-refresh |
| 8 | Aesthetic & Minimalist | 3 | +1 | Rainbow palette + off-brand purple gone; color rationed; ink numbers |
| 9 | Error Recovery | 3 | — | Plain-Lao error states + retry everywhere |
| 10 | Help & Documentation | 2 | — | Still minimal (no onboarding); acceptable for the domain |
| **Total** | | **29/40** | **+3** | **Good (was 26 / Acceptable)** |

## Anti-Patterns Verdict

**Deterministic scan — before → after:**
- Retired hex values: 0 → 0
- Off-palette Material colors (`purple/teal/green/orange/indigo`): 26 → **0**
- Off-palette role-pill colors (`blue/orange.shade`): present → **0**
- `fontSize: 11` (below the 12px floor): ~30 → **0**
- Raw `Card` / `ChoiceChip` / `OutlineInputBorder` in booking: many → **0**
- `.withOpacity` (deprecated): 0 → 0
- `Colors.grey.shadeXXX`: 98 → 84 (remainder is decorative: idle nav icons, input borders, dividers)

**LLM assessment:** The "two designers" tell — a polished system beside screens that ignored it — is essentially resolved. Booking (student + teacher) now speaks the same component and color language as the rest of the app. No AI-slop signature remains; the single off-brand purple is gone and color is rationed to the documented roles.

## What's Resolved (the three P1s + the two P2s)

1. **AA contrast on key data** — admin hero, GPA cell, grade badges (F now red), booking stat tiles, and the approve-view "select all" link no longer use white-on-bright-teal or amber-as-text.
2. **Booking flow on the design system** — both views: rows → `AppSurfaceCard`, filters → `AppFilterChipRow` (Info-Blue selected, AA, 48 dp), form fields → themed filled inputs. Status via shared `BookingStatusStyle` (solid AA pills + Lao labels; raw English enums gone).
3. **Rainbow palette** — all class/schedule cards use one neutral accent; `Colors.purple/teal` removed; the status vocabulary is closed again.
4. **Grey-below-floor + sub-12px text** — shared empty/error widgets + 13 screens lifted to the 12px floor with on-token text colors.
5. **Status semantics** — one mapping across booking cards, lists, and grade badges; approved is emerald everywhere (the blue check is gone).

## Remaining (minor)

- **[P2] Reject-red as small text** (`#e53935` ≈ 4.0:1) on the "rejected" status label and field errors — a system-token limit, not a per-screen miss. Consider a darker on-surface red, or icon + ink, for sub-14px red.
- **[P2] Announcement composer still uses raw `ChoiceChip`** (audience targeting, 2 instances) — the one non-booking screen that hasn't moved to `AppFilterChipRow`.
- **[P3] `fontSize: 10`** remains in 12 spots — most are legit (nav captions, badges) but a few (evaluation meta, day badges, grade qualitative label) are content below the floor.
- **[P3] Booking form uses floating `labelText`** rather than the app's label-above `AppTextField` standard (a deliberate trade-off to stay coherent with the room dropdown).
- **[P3] Icon-on-light-tint** (amber/teal glyphs on a 10% wash in stat cards / quick actions) sits below 3:1 for UI components.
- **[unverified] Login** header/footer over a photo — confirm contrast on-device.
- **[P3] Score transcript strip** — four edge-to-edge saturated cells is loud; fine as a transcript header, but a candidate for `quieter`.

## Questions to Consider
- Is the reject-red worth darkening at the token level (it recurs anywhere red is small text), or handled case-by-case?
- Should the announcement audience selector move to `AppFilterChipRow` for full chip consistency?
- Booking can't be runtime-verified here — does the filter index↔key mapping and the filled-input bottom sheet behave on-device?
