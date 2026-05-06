# Interaction Design

Applies to web frontends and other graphical UIs. Covers visual behavior and accessibility, since interaction design is about how something works for everyone, not just how it looks.

## Interaction Design

- **Three button states**: Every clickable element needs base, hover (lighter/tinted), and press (darker) states. Both active and inactive variants. Ideally enforced via component primitives that cannot be instantiated incomplete.
- **Hover gating**: Wrap hover styles in `@media (hover: hover)` to prevent sticky hover on touch devices.
- **Interactive color convention**: Hover mixes the base color ~15% toward a lighter/accent tint. Press mixes ~15% toward dark. Same transformation ratios for all interactive elements, applied relative to each element's own base color. Encoded in `color-mix()` mixins so the rule cannot drift per-component.
- **Mobile-first verification**: Compute pixel budgets at 375px (iPhone SE), 390px (iPhone 14), 768px (iPad). iOS constraints: 16px font floor on inputs, 44px tap targets, no vendor prefixes. Enforced at build or in review, not by recall.
- **Color system**: Derive all tints and shades from base colors via `color-mix()`. No hardcoded hex outside `:root` token definitions. This preserves runtime flexibility for dark mode. Enforced via lint or review.
- **CSS unit strategy**: Use `rem` for content-scaled values (font sizes, text-coupled spacing, tap targets, min-heights, border-radius). Use `px` for structural layout (grid column definitions, max-widths, media query breakpoints) and fine details (borders, shadows, outlines, focus rings). Use viewport units (`dvh`, `svh`, `vw`) for viewport-proportional spacing. Use `em` only for properties that must scale with the element's own font size (`letter-spacing`). Rationale: `rem` respects user font-size preferences (WCAG 1.4.4); structural layout stays in `px` because browser zoom (the primary accessibility mechanism) already scales it, and `rem` grid columns create tablet regressions when font-size overrides swell the sidebar. Do not set a custom root font-size (e.g., `62.5%`); rely on the browser default `16px` so `1rem` = `16px` and iOS Safari's auto-zoom floor on inputs is preserved.
- **Motion has personality, not just function**: Beyond signaling state changes, motion is a tool for delight: subtle bounces on success, satisfying eases on panel transitions, brief celebrations on completion. UIs should feel alive, not robotic. The discipline is restraint, every animation earns its place, but the goal is motion that feels intentional and human, not sterile motion-free interfaces. The accessibility rule (`prefers-reduced-motion`) governs *who* sees the motion; this rule governs *what* motion is worth shipping at all.

## Accessibility Primitives

Accessibility is correctness for users you may not have tested with. Build it in from the start; retrofitting is expensive and usually incomplete.

- **Semantic HTML first**: Use `<button>` for buttons, `<a href>` for navigation, `<nav>`/`<main>`/`<header>` for landmarks. ARIA is a patch for when semantic HTML cannot express the intent, not a replacement.
- **Keyboard navigation works for everything**: Every interactive element is reachable and operable via keyboard alone. Tab order follows visual order. Escape closes modals. Enter activates. Arrow keys navigate inside composite widgets.
- **Visible focus indicator on every focusable element**: Never `outline: none` without an explicit replacement. Focus rings must meet 3:1 contrast against the adjacent background.
- **Focus management on dynamic UI**: When opening a modal, move focus inside. When closing, return it to the trigger. When inserting content the user just requested, move focus to it. Focus is the keyboard user's cursor.
- **Color contrast ratios**: WCAG AA: 4.5:1 for body text, 3:1 for large text (18pt+, or 14pt+ bold) and UI components. Designs should meet these ratios. A shortfall blocks shipping only when the task or applicable standard requires it. Verify with a contrast checker, not by eye.
- **Color is never the only signal**: State changes use shape, icon, or text in addition to color. Red-green colorblindness affects ~8% of men.
- **Form labels are programmatically associated**: Every input has a `<label for="">` or `aria-labelledby`. Errors associate with their field via `aria-describedby` and use `role="alert"` for live announcement.
- **Motion is a legitimate design tool, but you must honor `prefers-reduced-motion`**: The OS exposes the user's preference as a CSS media query / JS signal; the browser does not auto-disable web animations. Wrap non-essential animations in `@media (prefers-reduced-motion: no-preference)` (or gate via `window.matchMedia('(prefers-reduced-motion: reduce)').matches`) so users who've opted out don't see them. The browser doesn't enforce the preference; you do. Pairs with the Interaction Design rule on motion's role.
- **Test with the keyboard, then with a screen reader**: Tab through the page with no mouse. Then run VoiceOver (Cmd+F5 on macOS) and listen. Issues invisible to the eye become obvious in audio.
