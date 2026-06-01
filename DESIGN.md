---
name: AMS UP
description: "Academic management for the CEIT faculty: schedules, room bookings, announcements, evaluations, and grades across Admin, Teacher, and Student roles."
colors:
  faculty-teal: "#40b4cd"
  faculty-teal-fill: "#1f7e93"
  identity-navy: "#14385d"
  info-blue: "#3257cc"
  highlight-gold: "#f5c842"
  approved-emerald: "#067a59"
  pending-amber: "#f59e0b"
  reject-red: "#e53935"
  ink: "#1a1a2e"
  slate-gray: "#6b7280"
  surface-white: "#ffffff"
  mist-gray: "#f5f7fa"
typography:
  title:
    fontFamily: "Roboto, 'SF Pro Text', system-ui, sans-serif"
    fontSize: "24px"
    fontWeight: 700
    lineHeight: 1.2
  heading:
    fontFamily: "Roboto, 'SF Pro Text', system-ui, sans-serif"
    fontSize: "18px"
    fontWeight: 600
    lineHeight: 1.3
  subheading:
    fontFamily: "Roboto, 'SF Pro Text', system-ui, sans-serif"
    fontSize: "16px"
    fontWeight: 600
    lineHeight: 1.3
  body:
    fontFamily: "Roboto, 'SF Pro Text', system-ui, sans-serif"
    fontSize: "16px"
    fontWeight: 400
    lineHeight: 1.4
  label:
    fontFamily: "Roboto, 'SF Pro Text', system-ui, sans-serif"
    fontSize: "14px"
    fontWeight: 600
    lineHeight: 1.3
  caption:
    fontFamily: "Roboto, 'SF Pro Text', system-ui, sans-serif"
    fontSize: "12px"
    fontWeight: 400
    lineHeight: 1.3
rounded:
  button: "12px"
  card: "14px"
  dialog: "16px"
  chip: "20px"
spacing:
  xs: "4px"
  s: "8px"
  m: "16px"
  l: "24px"
  xl: "32px"
  xxl: "48px"
  screen: "20px"
components:
  button-primary:
    backgroundColor: "{colors.faculty-teal-fill}"
    textColor: "{colors.surface-white}"
    rounded: "{rounded.button}"
    padding: "0 24px"
    height: "48px"
  button-primary-disabled:
    backgroundColor: "#1f7e9380"
    textColor: "#ffffffd9"
    rounded: "{rounded.button}"
    height: "48px"
  button-secondary:
    backgroundColor: "transparent"
    textColor: "{colors.faculty-teal}"
    rounded: "{rounded.button}"
    height: "48px"
  button-signout:
    backgroundColor: "transparent"
    textColor: "{colors.reject-red}"
    rounded: "{rounded.card}"
    height: "48px"
  chip-selected:
    backgroundColor: "{colors.info-blue}"
    textColor: "{colors.surface-white}"
    rounded: "{rounded.chip}"
    padding: "10px 18px"
  chip-idle:
    backgroundColor: "{colors.surface-white}"
    textColor: "{colors.ink}"
    rounded: "{rounded.chip}"
    padding: "10px 18px"
  input:
    backgroundColor: "{colors.mist-gray}"
    textColor: "{colors.ink}"
    rounded: "{rounded.button}"
    padding: "14px 16px"
    height: "48px"
  card-surface:
    backgroundColor: "{colors.surface-white}"
    textColor: "{colors.ink}"
    rounded: "{rounded.card}"
    padding: "16px"
  dialog:
    backgroundColor: "{colors.surface-white}"
    textColor: "{colors.ink}"
    rounded: "{rounded.dialog}"
    padding: "24px"
  snackbar-success:
    backgroundColor: "{colors.approved-emerald}"
    textColor: "{colors.surface-white}"
    rounded: "{rounded.card}"
    padding: "14px 16px"
  snackbar-warning:
    backgroundColor: "{colors.pending-amber}"
    textColor: "{colors.ink}"
    rounded: "{rounded.card}"
    padding: "14px 16px"
---

# Design System: AMS UP

## 1. Overview

**Creative North Star: "The Campus Noticeboard"**

AMS UP is the trusted board where the real schedule, the real notice, and the real result get posted. Everything on it should read as posted by the faculty and current: this is tomorrow's class, this booking really was approved, this grade really stands. The system carries warm authority. It is official and credible, but it belongs to a campus, not a bank. Authority comes from clarity and calm, never from heavy chrome or cold formality.

The build is calm and utilitarian. Surfaces are white cards floating a few millimetres off a cool mist-gray scaffold on a single soft shadow, corners are gently rounded (12 to 14px), and one bright Faculty Teal marks everything you can act on. Color is rationed: teal means act, amber/emerald/red report state, and everything else is ink on white. The interface is built to be glanced at. Most sessions are ten-second checks, so the answer sits at the top of every screen and depth waits until it is asked for.

This system explicitly rejects four looks. It is not **dated enterprise / ERP** (no cluttered gray forms, dense unscannable tables, or 9px text). It is not **childish / gamified** (no mascots, candy colors, confetti, or badge-spam, because grades and evaluations are serious to the people they belong to). It is not **generic AI SaaS** (no purple gradients, decorative glassmorphism, or endless identical icon-heading-text card grids). It is not **stiff corporate / banking** (no cold dark-navy severity). Credible, not severe.

**Key Characteristics:**
- One bright accent (Faculty Teal) carries every primary action, focus ring, active tab, and link.
- White cards on cool mist-gray, lifted by a single 6 percent shadow. Flat by default, never glassy.
- Status is a fixed three-color language: amber pending, emerald approved, red rejected.
- System fonts only, on a fixed 16px-floor scale tuned for Lao script and English fallback.
- Every screen ships four real states: loading skeleton, teaching empty state, plain-language error with retry, and toast/dialog success.

## 2. Colors

A cool, bright palette: one teal lead, a family of supporting blues, a strict three-color status set, and near-black ink on white over cool mist-gray. Warmth lives in a single gold highlight and in the rounded, soft-shadowed shapes, not in the background.

### Primary
- **Faculty Teal** (`#40b4cd`): The one action color. Text-field focus border, active bottom-nav tab, links, selected avatars, icon tints, and brand moments. Bright blue-green that reads official but friendly. If something on screen can be tapped to act or is the current location, it is this teal.
- **Faculty Teal — on-fill** (`#1f7e93`): The darker tone of the same hue, used only as the *fill* behind white text or icons — primary buttons, FABs, the filled confirm button, and the info toast. White-on clears AA at 4.70:1, where white on the bright `#40b4cd` is only 2.43:1 and fails. Two tones, one teal: bright for accents and focus, darker for white-on-fill. It is not a new color, and it never appears as teal text or a border.

### Secondary
- **Info Blue** (`#3257cc`): The single support accent. Admin-context surfaces (announcements, evaluations), informational / in-progress state, notification highlights, the default selected filter chip and gradient stat banner, and the data-viz mid band. A confident true-blue, verified AA both as a white-text fill and as blue text on white (6.2:1). It replaced the former four near-identical blues (`#4c4ddc`, `#4a68ff`, `#4a80f0`, `#3a3bbf`).

### Tertiary
- **Identity Navy** (`#14385d`): The launch and app-icon color (adaptive icon background and native splash). The brand's deepest, most formal note; it appears only at launch. Reserve it for identity moments; never a second body color, or the app tips toward the banking look the brand rejects.
- **Highlight Gold** (`#f5c842`): The single warm accent, used sparingly on hero banners and highlight chips. Never for body text or on a white surface (contrast fails).

### Status (semantic, never decorative)
- **Approved Emerald** (`#067a59`): Approved bookings, success dialogs and toasts, positive captions. Darkened from the former bright `#10b981` so it carries white text and reads as legible green text on white (AA 5.3:1). The two former duplicate greens (`#27ae60`, `#4caf50`) folded into this one.
- **Pending Amber** (`#f59e0b`): Bookings awaiting approval, warning dialogs and toasts. Always pair with dark Ink (`#1a1a2e`) text and icons on a filled amber surface — white on amber is only 2.15:1 and fails; ink on amber is 7.94:1.
- **Reject Red** (`#e53935`): Rejected bookings, destructive actions (sign out, delete), error dialogs and field errors, nav badges.

### Neutral
- **Ink** (`#1a1a2e`): Primary text. A near-black with a faint indigo cast. Never pure `#000000`.
- **Slate Gray** (`#6b7280`): Secondary text, captions, metadata, placeholder labels. Holds 4.5:1 on white and on mist-gray; do not lighten it further for "elegance."
- **Surface White** (`#ffffff`): Cards, dialogs, bottom nav, chips at rest.
- **Mist Gray** (`#f5f7fa`): The app scaffold background and the fill of every text input. The cool, quiet ground that lets white cards lift.

### Named Rules
**The Teal-Leads Rule.** Faculty Teal is the only color that means "act" or "you are here." Primary buttons, focus, active nav, links. Nothing else borrows it, and primary actions use nothing else.

**The Status-Color Rule.** Amber, emerald, and red are a closed vocabulary for booking and action state. They report; they never decorate. A surface is never amber because amber looked nice.

**The One-Blue Rule.** The palette is Faculty Teal plus exactly one support blue (Info Blue `#3257cc`) and one status emerald. The former four-blue / three-green drift is consolidated. Never reintroduce a second support blue or revert to the retired `#4c4ddc` / `#4a68ff` / `#4a80f0` / `#3a3bbf` values, and never add a second green beside Approved Emerald.

## 3. Typography

**Display / Body / Label Font:** System default (Roboto on Android, SF Pro on iOS), expressed as `Roboto, "SF Pro Text", system-ui, sans-serif`.

**Character:** No custom typeface and no display face. Hierarchy is carried entirely by size and weight on one familiar sans, which is exactly right for a product surface: the type disappears into the task and renders fast and native in both Lao and English. There is no second family, and none is wanted.

### Hierarchy
- **Title** (700, 24px, line-height 1.2): The largest type. Dashboard headline numbers and the boldest screen statements. Page-level role titles render at 20px bold via the shared scaffold.
- **Heading** (600, 18px, line-height 1.3): Section headers, dialog titles, app-bar titles.
- **Subheading** (600, 16px, line-height 1.3): Card headers and grouped-content labels.
- **Body** (400, 16px, line-height 1.4): Default reading text and input text. Keep prose blocks to 65 to 75 characters per line.
- **Label** (600, 14px, line-height 1.3): Field labels (rendered above the input), button captions, dense list metadata.
- **Caption** (400, 12px, line-height 1.3): Helper text, timestamps, field errors, the smallest type that ships.

### Named Rules
**The 16px Floor Rule.** Body and input text never drop below 16px. 14px is reserved for labels and dense metadata, 12px for captions only. Nothing smaller than 12px ships, ever.

**The Lao Headroom Rule.** Line-height stays at or above 1.3 on headings and 1.4 on body so Lao stacked diacritics never clip. Test every heading and label in Lao and in the longer English fallback at 360dp width; if it overflows or truncates a real word, the copy or the size is wrong, not the viewport.

## 4. Elevation

Flat by default, lifted by a single soft shadow. The system uses no Material elevation tiers and no stacked shadows. Every Material surface sets `elevation: 0`; depth is one diffuse low-opacity shadow that makes a white card read as resting just above the mist-gray ground. Active and branded elements are the only things that glow, and they glow in their own hue.

### Shadow Vocabulary
- **Surface Rest** (`box-shadow: 0 2px 8px rgba(0,0,0,0.06)`): The default card lift. `AppSurfaceCard`, stat cards, class cards, icon bubbles.
- **Nav Lift** (`box-shadow: 0 -2px 12px rgba(0,0,0,0.08)`): An upward shadow that separates the bottom navigation from scrolling content.
- **Chip Rest** (`box-shadow: 0 2px 6px rgba(0,0,0,0.06)`): Idle filter chips.
- **Accent Glow** (`box-shadow: 0 2px 8px rgba(64,180,205,0.30)` and the stats banner `0 4px 12px <accent>/0.30`): The only colored shadow. A selected filter chip and the gradient stat banner cast a tint of their own color. Neutral surfaces never do this.

### Named Rules
**The Soft-Shadow Rule.** One shadow per surface, black at 6 to 8 percent, blur 6 to 12, y-offset 2. No second shadow layer, no shadow darker than 8 percent, no Material elevation. If a card looks like it has a hard drop shadow, it is wrong.

**The Colored-Glow Rule.** Only an active element (selected chip) or a branded banner (gradient stats) earns a shadow tinted in its own hue at ~30 percent. A resting neutral card never glows.

## 5. Components

The component voice is calm and utilitarian: large tap targets (48dp minimum), soft rounded surfaces, restrained shadow, one bright accent. Every interactive control ships its full state set; loading and disabled are designed, not afterthoughts.

### Buttons
- **Shape:** Gently rounded (12px), full-width by default, 48dp tall (the minimum touch target).
- **Primary:** Solid on-fill Faculty Teal (`#1f7e93`) with white text (AA 4.70:1; the bright `#40b4cd` accent is reserved for focus, nav, links, and icon tints and is never the fill under white text), no elevation, 24px horizontal padding, 16px/600 label. One primary per screen. Disabled drops background to 50 percent and text to 85 percent. Loading swaps the leading icon for an 18px 2px-stroke spinner and blocks re-tap.
- **Secondary:** Outlined, 1.2px Faculty Teal border, teal label, transparent fill. Same height and radius. For "Cancel," "Back," and alternatives beside a primary.
- **Tertiary:** Text-only, teal, 14px/600, for inline "more" / "skip."
- **Sign-out / Destructive:** Outlined Reject Red (`#e53935`), 14px radius, bold red label with a logout glyph. The only red button.

### Chips (filter row)
- **Style:** Horizontal scrolling pills, 20px radius, 18px/10px padding, 48dp minimum height, animating over 200ms.
- **Selected:** Filled in the active color (default Dashboard Blue `#4a68ff`), white bold 13px label, Accent Glow shadow in the active hue.
- **Idle:** White fill, ink label at normal weight, Chip Rest shadow. Single-selection; the parent owns the index.

### Cards / Containers
- **Corner Style:** 14px radius (`AppSurfaceCard`, the base surface everywhere).
- **Background:** Surface White on the Mist Gray scaffold.
- **Shadow Strategy:** Surface Rest only (see Elevation). Tappable cards add an InkWell ripple clipped to the radius.
- **Status accent:** `AppClassCard` and booking cards carry a 4px colored left edge plus a tinted leading-icon badge (the icon's color at 10 percent, 10px radius) to encode category or status. This left edge is a legacy status cue; for new surfaces prefer a status pill or the tinted icon and do not widen or decorate it (see Don'ts).
- **Internal Padding:** 14 to 16px typical; the stats banner and profile header run 15px.

### Inputs / Fields
- **Style:** Label sits above the field (14px/600, with a red ` *` when required). Field is filled Mist Gray (`#f5f7fa`), 12px radius, 48dp minimum height, 16px/14px content padding, 16px body text, teal cursor.
- **Focus:** Border shifts to Faculty Teal at 1.5px. Resting border is a hairline `grey.200`; disabled is `grey.100`.
- **Error:** Border turns Reject Red, with a 12px red caption directly beneath. Helper text uses the same slot when there is no error. Keyboard type is set per input (numeric, email, phone); multiline fields auto-promote to the multiline keyboard.

### Navigation (bottom tab bar)
- **Style:** White bar with the upward Nav Lift shadow, inside a `SafeArea`, 3 to 5 destinations spaced evenly.
- **States:** Selected tile gets a Faculty Teal background tint at 8 percent, teal 24px icon, and a 10px/600 teal caption. Idle is transparent with a `grey.400` icon and caption. Transitions animate over 200ms. Unread counts render as a Reject Red corner badge (`99+` cap).

### Dialogs (signature)
- The blocking-feedback signature: a rounded white card (16px radius, 24px padding) with a circular icon badge at the top (the flavor color at 10 percent, 48px glyph), a 18px/600 title, a centered 14px muted message, and a footer.
- **Four flavors share one shell:** success (emerald check), warning (amber), error (red, with an optional monospace detail panel for raw API errors), and confirmation (cancel outline + filled confirm). Lao button copy by default.

### State widgets (signature)
The "every state is designed" principle is shipped as four reusable widgets, and they are the most distinctive thing in this system:
- **Loading:** `AppLoading` renders a content-shaped skeleton (16+ named variants such as `dashboard`, `schedule`, `adminApprove`) that mirrors the real layout. Never a bare spinner mid-content; pull-to-refresh stays available while loading.
- **Empty:** A centered 56px muted icon, a 15px/500 slate title, and an optional subtitle plus a teal CTA. The copy teaches the next action, it does not just say "nothing here."
- **Error:** A centered `cloud_off` icon, a 15px plain-language message (never a status code), and a teal retry button labelled "ລອງໃໝ່."
- **Success:** A top snackbar in the semantic color, auto-dismissing in 3 seconds, for non-blocking confirmations. Icon and text are white on the emerald and on-fill teal toasts, but switch to dark Ink (`#1a1a2e`) on the amber warning toast, where white would fail contrast (2.15:1).

## 6. Do's and Don'ts

### Do:
- **Do** use Faculty Teal for every primary action, focus ring, active tab, and link, and nothing else for those — one accent, one meaning. The bright accent (`#40b4cd`) carries focus rings, active tabs, links, and icon tints; the darker on-fill tone (`#1f7e93`) is the fill wherever white text or icons sit on solid teal (buttons, FABs), so contrast clears AA.
- **Do** keep status to the three-color set: Pending Amber (`#f59e0b`), Approved Emerald (`#067a59`), Reject Red (`#e53935`). Report state with them; never decorate with them.
- **Do** float white cards on Mist Gray with the single Surface Rest shadow (`0 2px 8px rgba(0,0,0,0.06)`). Flat at rest.
- **Do** hold body and input text at 16px and keep Slate Gray (`#6b7280`) as the lightest text that touches a background. Verify 4.5:1.
- **Do** ship all four states on every data screen: skeleton, teaching empty state, plain-language error with retry, and toast/dialog success. Reuse `AppLoading`, `AppEmptyState`, `AppErrorState`, `AppSnackbar`, `AppDialogs`.
- **Do** put labels above fields, set the right keyboard per input, and test copy in Lao and the English fallback at 360dp.
- **Do** keep every tap target at 48dp with at least 8dp between controls.

### Don't:
- **Don't** build **dated enterprise / ERP** screens: no cluttered gray forms, dense unscannable tables, or sub-12px text. Glanceable beats exhaustive.
- **Don't** go **childish / gamified**: no mascots, candy-bright colors, confetti, or badge-spam. Grades and evaluations are serious.
- **Don't** ship **generic AI SaaS**: no purple gradients, no decorative glassmorphism, no endless identical icon-heading-text card grids.
- **Don't** drift **stiff corporate / banking**: keep Identity Navy (`#14385d`) to launch and identity only; it is not a second body color.
- **Don't** widen the 4px card left-stripe, apply it decoratively, or add it to new surfaces. It is a legacy status cue; encode status with a pill, badge, or tinted leading icon instead.
- **Don't** reintroduce a second support blue or a second green. The palette is Faculty Teal + one Info Blue (`#3257cc`) + one Approved Emerald (`#067a59`); the retired `#4c4ddc` / `#4a68ff` / `#4a80f0` / `#3a3bbf` / `#10b981` / `#27ae60` / `#4caf50` values must not come back.
- **Don't** stack shadows, darken a shadow past 8 percent, or use Material elevation tiers. One soft shadow per surface.
- **Don't** put white text or icons on the bright Faculty Teal accent (`#40b4cd`, 2.43:1) or on Pending Amber (`#f59e0b`, 2.15:1): white-on-teal-fill must use the darker on-fill tone (`#1f7e93`), and amber fills always carry dark Ink. And don't use gradient text, pure `#000000` on pure `#ffffff`, or Highlight Gold for text on white (all fail contrast).
- **Don't** drop a bare spinner into the middle of content where a content-shaped `AppLoading` skeleton belongs.
