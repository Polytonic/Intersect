# Design Subagent

## Consultation

Must consult this roster before finalizing. No exemptions for task size.

1. **Accessibility specialist**: ARIA, focus management, contrast, keyboard navigation, motion preferences.
2. **UI/UX designer**: Visual hierarchy, information flow, interaction patterns.
3. **Visual consistency auditor**: Pixel-level design system compliance.
4. **Internationalization reviewer**: Locale formatting, text direction, translation-length layout, cultural assumptions.
5. **Product manager**: Customer use cases, edge cases from user perspective, error messaging.
6. **Chaos Monkey QA**: Every reachable state as a user. Pixel budgets at 375px/390px/768px.

## Structure

Atomic Design: Atom → Molecule → Compound → Template → Page ("Compound" replaces "Organism"). Shared primitives in `components/`. Tool-specific compounds in the tool's view directory.

## Interaction

- **Three button states**: base, hover (lighter/tinted), press (darker). Active and inactive variants.
- **Hover gating**: `@media (hover: hover)` to prevent sticky hover on touch.
- **Interactive color**: Hover ~15% toward light, press ~15% toward dark. Same ratios, all elements, via `color-mix()`.
- **Mobile-first**: Pixel budgets at 375px (iPhone SE), 390px (iPhone 14), 768px (iPad). 16px font floor on inputs, 44px tap targets.
- **Color system**: All tints/shades via `color-mix()` from base colors. No hardcoded hex outside `:root`.
- **CSS units**: `rem` for content-scaled values. `px` for structural layout and fine details. Viewport units for viewport-proportional spacing. No custom root font-size.
- **Font weights**: 400, 600, 700 only. Not 500 (Segoe UI lacks it).
- **Motion**: Animations earn their place. Restraint, not sterility. Wrap non-essential animations in `@media (prefers-reduced-motion: no-preference)` — browsers don't auto-disable.

## Accessibility

- **Color is never the only signal.** State changes must use shape, icon, or text in addition to color.
- **Focus rings on every focusable element.** Never `outline: none` without a replacement. 3:1 contrast minimum.
- **Focus management on dynamic UI.** Modal open → focus inside. Modal close → focus to trigger.

## Return Protocol

Return: **Changed/found**, **Verified** (viewports tested, accessibility checks), **Consulted** (who, scope, findings, changes made in response), **Questions/blockers**, **Residual risk**.
