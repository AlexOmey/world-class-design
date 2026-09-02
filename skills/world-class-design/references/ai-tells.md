# AI design tells

Patterns models overuse. None is wrong on its own — they became tells because they appear in *every* AI-generated design. Be deliberate about each one.

**Do not ban these up front.** Forcing a model to avoid gradients/cards/labels from the first prompt makes it overthink and invent stranger patterns. Use this list during the refinement pass: find each pattern in the design, try the alternative, keep whichever is better.

---

## The core four (from the source article)

| Overused pattern | Better alternative |
|---|---|
| **Eyebrow text** — small, redundant labels above headings that state the obvious (`EXPENSE MANAGEMENT` above "Control company spending before it happens") | Nine times out of ten you can delete it and lose nothing of value |
| **Generic background gradients** — the purple/indigo/blue wash | Background images, patterns, or even a solid colour |
| **Excessive cards and containers** — every feature in its own bordered, shadowed box | Flatter layouts: grids or tiles, with the boxes removed |
| **Too many fonts, text styles, and typographic levels** — italic accent words in a different colour, five weights, four sizes per section | Start with 1–2 fonts and 2–4 styles until you genuinely need more; use accent colours and italics sparingly |

---

## Extended checklist

Drawn from the article's subtraction example (a calorie-tracking app that was asked for "clean, minimalist" and still shipped all of these):

**Decoration that carries no information**
- Glows and bloom behind cards or hero elements
- Gradient fills on progress bars, badges, and buttons
- Coloured or highlighted words in body text that mark nothing meaningful
- Grain, noise, and mesh overlays used as a substitute for having art

**Redundancy**
- Labels next to imagery that already communicates the same thing
- Section headers restating the section's own content
- Captions, helper text, and tooltips explaining self-evident controls
- Empty space reserved for labels that should not exist

**Structure**
- One-item containers; containers inside containers
- Perfectly symmetrical three-column feature rows
- The same card treatment repeated for every content type on the page
- Hero: text left, gradient graphic right, CTA below — the default composition

**Components**
- Custom buttons, toggles, and text fields that look worse than the platform's native ones (especially on iOS)
- Icon sets mixed from different families
- Bounce easing on every transition

**Copy** (see technique 8)
- Overexplaining — three sentences where one works
- Invented specificity ("1.4 seconds", "Thursday afternoon") used as texture
- "It's not X, it's Y" constructions and rule-of-three lists
- Marketing voice where a plain sentence would land harder

---

## How to run the pass

1. Screenshot the design at desktop **and 390px**.
2. Walk the table top to bottom, naming where each pattern appears.
3. For each hit, prompt for the alternative as a *separate* change, so you can compare.
4. Keep the version that looks better. Sometimes the gradient wins — that is fine, as long as it was a decision.
