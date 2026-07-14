# Liquid Glass on the Web — Cross-Project Design Reference

> Distilled 2026-07-11 (SuitabilityGate session) from Apple's released Liquid Glass specs
> (WWDC25 introduction + WWDC26 refinements, HIG + developer docs) and preliminary web research.
> **Consumers:** SuitabilityGate (`refs/UI_MODERNIZATION_DIRECTIVE.md` §1a/§1b/§3a/§5b applies it),
> gazer-universe, and any future UI-heavy project.
> **Scope:** what Apple's material actually specifies, what translates to the web, what does not,
> and the honest-UX patterns that ride along. Stack-agnostic (plain CSS/JS + any spring library).

---

## 1. What Apple's Liquid Glass actually is (released spec, condensed)

**Optical model** — the material *lenses* (bends and concentrates light) rather than blurs
(scatters). Behaviors: real-time refraction of the content behind it; **specular highlights** that
respond to device motion / interaction; **adaptive tint** (text on glass adjusts color/brightness/
saturation to the backdrop; the system flips light/dark variants per underlying content); shadows
that adapt opacity to what they fall on.

**Motion model** — "gel-like" interactive response: scale on press, **touch-point illumination
that radiates to nearby glass**, shimmer; elements inside a `GlassEffectContainer` **morph
together** when within a spacing threshold; spring animations (`.bouncy()`), typical transition
**0.3–0.4s**.

**Variants**

| Variant | Use | Transparency |
|---|---|---|
| Regular | Default for navigation/controls | Medium; fully adaptive |
| Clear | Floating controls over media-rich backdrops only; needs a dimming layer (~0.3 black) and bold bright content above | High |

**Design rules (HIG, the part most people skip):**

1. **Navigation layer ONLY.** Glass floats above content; never apply it to content itself
   (lists, tables, media, data).
2. **No glass-on-glass.** One floating glass layer above content; nested glass = prohibited
   (glass cannot sample other glass — that's why the container exists).
3. **4.5:1 minimum contrast** for text on glass; avoid glass over busy/colorful/animated
   backdrops without mitigation (gradient fade, tint, dimming).
4. **Tint conveys meaning, not decoration.** Reserve color for semantic intent.
5. WWDC26 walked back default transparency (+ gave users a clear↔tinted slider) — i.e. Apple
   itself corrected toward legibility. Design conservative-first.

## 2. Web translation — the three tiers (and the verdicts)

| Tier | Technique | Verdict |
|---|---|---|
| **Frost** (= Apple's "Regular") | `backdrop-filter: blur(Npx) saturate(~140%)` + translucent surface color (~72–78% opacity) + 1px top-edge inset highlight ("lit rim") + hairline translucent border | **DEFAULT.** Universal browser support, zero deps, GPU-cheap, contrast controllable. |
| **Refraction hero** | SVG `feDisplacementMap` via `backdrop-filter: url(#lens)` on ONE static decorative element | **One flourish max.** Chromium-only; Safari/Firefox silently fall back to plain blur — so declare frost first and layer the `url()` variant behind a capability check; the fallback must look intentional. Never on functional/dynamic UI. |
| **WebGL glass libraries** (liquidGL, liquid-glass-js) | WebGL shaders; liquidGL refracts an html2canvas *snapshot*; liquid-glass-js opens a WebGL context per element | **REJECTED.** Snapshot approach breaks on dynamic UIs (stale pixels unless every DOM change is re-registered); per-element contexts hit the ~16-context browser cap; Safari instability; unpredictable text contrast kills WCAG-AA. Do not re-litigate without new evidence. |

**Prerequisite for any glass: an ambient backdrop.** Glass is invisible over a flat background.
Give the canvas 2–3 large, *static*, very subtle radial glows (brand-tinted, via `color-mix`) so
frost has something to blur. Static = still honors a "nothing floats/loops" motion budget.

**Tokens, not hex.** All glass values (surface translucency, blur radius, saturation, rim
highlight, border) live as design tokens in the one themable file, e.g.:

```css
--glass-surface: color-mix(in srgb, var(--color-surface) 72%, transparent);
--glass-line:    color-mix(in srgb, var(--color-line) 60%, transparent);
--glass-highlight: rgba(233, 241, 237, 0.07);
--glass-blur: 18px;  --glass-saturate: 140%;

.glass {
  background: var(--glass-surface);
  -webkit-backdrop-filter: blur(var(--glass-blur)) saturate(var(--glass-saturate));
  backdrop-filter: blur(var(--glass-blur)) saturate(var(--glass-saturate));
  border: 1px solid var(--glass-line);
  box-shadow: inset 0 1px 0 var(--glass-highlight);
}
```

## 3. The HIG rules, translated to web practice

- **Glass = chrome only:** sidebars, topbars (sticky, so content visibly scrolls under — the
  everyday proof the glass is real), auth/login cards, popovers/menus. **Never** on data surfaces:
  tables, result cards' semantic fills, audit/ledger blocks, anything whose legibility is the
  product.
- **No glass-on-glass:** anything sitting ON a `.glass` surface (chips, badges, inputs' inner
  elements) uses **solid tinted fills**. Frosted pills only directly on canvas/content.
- **Contrast:** spot-check text-on-glass against the *worst-case* backdrop (a glow hotspot), not
  the average.
- **Reduced transparency wins:** if in doubt, more tint. Apple's own trajectory.

## 4. Motion — the "Apple springy feel" without a single new dependency

Apple's marketing pages (e.g. macbook-air) are mostly **scroll-driven canvas image sequences** —
marketing-page tech; wrong tool for an app UI. What actually transfers is **springs on state
changes + control micro-interactions**. Any spring library works (`motion`/framer has first-class
springs matching Apple's model).

- Define **named presets once**, import everywhere — never ad-hoc spring numbers:
  `springGentle { stiffness ~260, damping ~26 }` (entrances/layout; settles ≈0.35s — inside
  Apple's released 0.3–0.4s window) · `springSnappy { stiffness ~420, damping ~30 }`
  (press/toggles/thumbs).
- **Toy threshold:** max ONE visible overshoot, fast settle, small amplitudes (press 0.98, hover
  1.02, entrance y:8→0). If a motion draws attention to itself twice, dial it down.
- **Signature micro-interaction:** segmented-control thumb as one element sliding between options
  (`layoutId` spring) — delivers Apple's "morph" feel without the infeasible glass-morphing.
- Everything gated on `prefers-reduced-motion`.

**Interactive highlights (Apple's specular/touch-illumination, web equivalent):**

- *Pointer-tracked specular:* soft radial highlight following the cursor — one `mousemove` →
  CSS custom property (`background: radial-gradient(… at var(--mx) var(--my), …)`), GPU-cheap,
  degrades to a static sheen. **Scope to 1–2 hero elements**; everywhere = toy.
- *Press-point illumination:* the press glow originates at the press coordinates and radiates.

## 5. Honest in-flight state — the "working border" pattern

For "show the system is acting" on the triggering control itself:

- **Flowing conic-gradient border** — `@property --angle` animated 0→360deg on a pseudo-element,
  plus a *blurred twin* underneath so the light blooms (the 3D feel). Compositor-friendly.
  `@property` is Baseline (Chromium, Safari 16.4+, Firefox 128+); fallback = static bright border.
- **Indeterminate flow, never a fake fill.** No invented percentages (the "frozen at 99%" trap).
  A traveling light says "working" without claiming "60% done".
- **Only while genuinely busy.** <1s ops need no indicator (loading-UX consensus); never add
  artificial delay to show the effect off. This is the ONE sanctioned looping animation in an
  otherwise nothing-loops motion budget.
- **Cancel must tell the truth:** clear text ("Stop waiting" / "Cancel", not a bare ×), instant
  feedback, `AbortError` treated as a non-error. Distinguish *stop waiting* (client aborts the
  watch; server work may still complete — e.g. an audit write that cannot be un-rung) from *true
  cancellation* (needs server support). For normally-fast ops, reveal Cancel only after ~2s
  in-flight (progressive disclosure) — a cancel that can never be meaningfully clicked is fake UI.

## 6. Deliberately NOT taken from Apple's spec (web reality)

- **Element morphing between glass surfaces** (`GlassEffectContainer` blending) — Metal-rendered;
  web equivalent needs the rejected WebGL tier. The `layoutId` thumb slide is the feel-equivalent.
- **Vibrant adaptive text on glass** (per-pixel backdrop sampling) — blend-mode approximations
  have unpredictable contrast → breaks the AA floor. Use static ink chosen to pass by construction.
- **Clear variant** — only for media-rich backdrops with a dimming layer; most app UIs have none.
- **Device-motion highlights** — no accelerometer on desktop web; pointer-tracking is the
  equivalent (§4).

## 7. Limitations & mitigations

- `backdrop-filter: url(#svg-filter)` (refraction) renders in Chromium only → keep it to one
  decorative hero with an intentional-looking frost fallback; verify both renders with screenshots.
- Glass over animated/busy backdrops is a contrast hazard → static ambient glows only, spot-check
  hotspots.
- Many stacked `backdrop-filter` layers can cost paint time on low-end GPUs → glass for chrome
  only (which the HIG demands anyway) keeps the count ≤3–4 per screen.

## SAFE EXTENSIONS

- New glass surfaces that are *chrome* (drawers, toasts, command palettes) — same `.glass` recipe.
- Additional spring presets for new interaction classes, still named + centralized.
- Per-brand re-tinting: everything routes through tokens; swap the token file, glass follows.

## REGRESSIONS TO AVOID

- Adding a WebGL glass library "because one element needs real refraction" — that's how the
  snapshot/context-cap/a11y failures re-enter. One SVG hero is the ceiling.
- Glass creeping onto content/data surfaces, or nesting glass — re-read §3.
- Determinate progress bars without real progress data; cancel affordances that overpromise.
- Spring values inlined per-component (drift → inconsistent feel; the system stops feeling like
  one material).
