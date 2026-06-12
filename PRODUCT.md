# Product

## Register

product

## Users

AMS UP serves three roles inside CEIT (the College of Engineering and Information Technology), a Lao-language-first academic faculty. The app is mobile-first (Flutter, iOS + Android), primary language Lao with English fallbacks, and each role gets its own bottom-nav shell.

- **Students** — the largest audience. They open the app between classes for ten-second checks: tomorrow's timetable, whether a room booking was approved, a new announcement, grades and live GPA. At semester end they complete faculty evaluations. Context: on a phone, often in a hallway, low patience for friction.
- **Teachers** — view their teaching schedule, request rooms outside teaching hours, and read their own evaluation results (aggregated and anonymous). Context: planning the day, occasional room needs, a private look at honest feedback.
- **Administrators (faculty staff)** — the operational hub. They clear the pending room-booking queue (approve / reject), broadcast announcements to everyone or a targeted audience, manage evaluation questions, and review aggregate teacher scores. Context: processing requests and communicating on behalf of the faculty.

## Product Purpose

AMS UP runs the day-to-day academic operations of the CEIT faculty in one role-aware mobile app: timetables, room reservations with an approval workflow, push announcements (Firebase Cloud Messaging), anonymous teacher evaluations, and grades / GPA. It is the front end for a Go (Golang) REST API backed by MariaDB; the app never touches the database directly.

It replaces fragmented manual processes (paper room requests, in-person notices, hand-collected evaluations) with a single source of truth each role can trust. Success looks like each role finishing its core job in a few taps and believing the result: a student checks the real schedule and books a free room without asking anyone, an admin empties the pending queue and reaches exactly the right audience with one message, a teacher sees candid feedback without ever learning who wrote it. The product's value is confidence in the data, so the design's job is to make that data correct, current, and legible.

## Brand Personality

**Trustworthy. Clear. Current.**

The voice is plain, direct, and respectful: sanctioned university software, not a marketing campaign and not a game. Confident without being stiff. Labels say what will happen ("Approve booking", "Submit evaluation"), errors speak in plain language, and nothing on screen oversells.

The emotional goal carries a deliberate tension worth holding onto. Users should feel the app is **official and reliable** (this is the real schedule, the grade really posted, the approval really went through) while it still feels **light and modern to use**. That is warm authority: institutional credibility without enterprise drudgery, and without the cold heaviness of a bank. The faculty is a campus, not a financial institution. When a choice is between more corporate and more human, choose human.

## Anti-references

This should not look or feel like any of these:

- **Dated enterprise / ERP.** No cluttered gray forms, dense unscannable tables, tiny text, or 2010s university-admin-panel density. Glanceable beats exhaustive.
- **Childish / gamified.** No cartoon mascots, candy-bright palettes, confetti, or badge-spam. Grades and evaluations are serious to the people they belong to.
- **Generic AI SaaS.** No purple gradients, decorative glassmorphism, or endless identical icon-heading-text feature-card grids. Avoid the template look.
- **Stiff corporate / banking.** No cold, heavy, dark-navy formality that reads as a financial institution. Credible, not severe.

## Design Principles

1. **Earned trust over decoration.** The real value is that the data is right and the state is honest: this *is* the schedule, the grade truly posted, the approval truly went through. Spend design effort on accuracy, legible status, and clear confirmation, not ornament. This includes protecting the people who rely on it: evaluation results are aggregated and anonymous, and a student's identity never surfaces to a teacher (designed out, not merely hidden).
2. **Warm authority.** Official and credible, never cold or playful. Institutional confidence comes from clarity and calm, not from dark formality or gimmicks. When in doubt, more human, less corporate.
3. **Role-true, not one-size.** Admin is an operations console (queues, broadcasts, aggregates); Teacher and Student are quick-glance utilities. Optimize each shell for its role's real context and primary task rather than forcing one shared layout onto all three.
4. **Glanceable first.** Most sessions are ten-second checks: next class, booking status, new announcement. Put the answer at the top of every screen and reserve depth and secondary actions for when they are actually needed.
5. **Every state is designed.** Loading, empty, error, and success are first-class, never the happy path plus afterthoughts. A blank, spinning, or cryptic screen erodes trust in official data faster than any aesthetic flaw, so each state gets a real, reassuring treatment with a clear way forward.

## Accessibility & Inclusion

- **WCAG 2.1 AA.** Contrast at least 4.5:1 for body text and 3:1 for large text and UI components (placeholder text held to the same 4.5:1, not a faint gray). Touch targets at least 48 dp with at least 8 dp between interactive elements. Minimum body text size 16 px.
- **Mobile baseline.** Design for 360 × 800 dp (Android) and 375 × 812 pt (iOS); vertical scroll only, no horizontal scroll outside intentional carousels.
- **Lao-first localization.** Lao is the primary UI language with English fallbacks. Lao script stacks tall diacritics and does not break words on spaces, so line-height and wrapping need headroom; English fallback strings are often longer, so layouts must flex without clipping or overflow. Test copy in both at every breakpoint.
- **Light mode is the shipped default.** Dark mode is not yet implemented (a future addition, not a current requirement). Never pure black on pure white.
- **Reduced motion.** Honor the platform reduce-motion setting; keep motion purposeful, with a crossfade or instant fallback for every animation.
- **Anonymity as inclusion.** Keeping evaluators unidentifiable is what makes honest feedback safe to give; treat it as an accessibility-grade guarantee, not a nice-to-have.
