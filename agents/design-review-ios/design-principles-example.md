# iOS App Design Principles (HIG + WCAG AA)

Use this checklist to guide automated iOS design reviews. It focuses on Apple’s Human Interface Guidelines (HIG) and WCAG AA accessibility requirements.

## Core Philosophy
- Users first: clarity, predictability, and speed
- Native feel: align with iOS conventions and components
- Consistency: typography, spacing, colors, and motion
- Accessibility: VoiceOver, Dynamic Type, contrast, and motion

## Layout & Structure
- Safe areas respected on all devices and orientations
- Comfortable margins and readable line lengths
- Content adapts to compact/regular width classes
- No clipped/overlapping content at any Dynamic Type size

## Navigation
- Clear hierarchy with consistent entry/exit points
- Back navigation is obvious and reliable
- Tab bars/Navigation bars use system conventions
- Deep links open the correct context and restore state

## Controls & Touch Targets
- Minimum target size ≥ 44×44 pt
- Clear affordances and feedback; destructive actions confirmed
- Gestures are discoverable with alternative buttons

## Typography
- Use iOS text styles (Dynamic Type)
- Maintain typographic hierarchy (title, headline, body, footnote)
- Adequate line height and spacing

## Color & Contrast
- Text contrast ≥ 4.5:1 (WCAG AA)
- Accessible colors in light/dark mode
- Semantic colors for status (success, warning, error, info)

## Motion & Feedback
- Motion purposeful and quick (150–300ms); respects Reduce Motion
- Haptics used sparingly and meaningfully
- Transitions communicate spatial and hierarchy changes

## Accessibility
- Labels, traits, and actions present/accurate
- VoiceOver order logical; groups related elements
- Focus lands on meaningful elements after navigation
- Images/controls have descriptive labels; decorative images ignored

## Forms & Input
- Clear labels, helper text, error messages
- Appropriate keyboards and return key actions
- Inline validation and accessible error announcements

## States & Robustness
- Loading, empty, and error states are informative and consistent
- Offline/poor network handling without dead-ends
- Background/foreground transitions preserve context

## Performance & Quality
- Fast launch and responsive interactions
- Crisp assets on all scales; no layout jank
- Console free of errors/warnings during primary flows

