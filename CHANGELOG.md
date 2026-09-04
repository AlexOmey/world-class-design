# Changelog

## 0.5.0 — unreleased

Corrections from an independent end-to-end run on a second product
(~18 agents, six rounds, one live codebase) by a session with no context
from the skill's development.

### Added
- **Checkpoint 0: agree the scope before building.** Surface treatment,
  layout, IA or copy — the user's answer, before any brief. Checkpoint 1
  lands after variants are built, so scope was being decided silently and
  nothing downstream repaired it.
- Techniques 1 and 2 **compose**. A strong user concept fixes material and
  constraints; the seed still drives structure. Treating them as
  alternatives removes the only mechanism for escaping the default,
  exactly when a confident brief makes that hardest to notice.
- In brownfield work, **the existing page is a stronger anchor than any
  moodboard**. Builders get a copy inventory, palette and material spec —
  never the current page.
- Technique 4: judge images at true render size and again at ~35%; prefer
  canonical forms; generate the subject filling its frame and composite
  yourself.
- Codex CLI output is RGB on white with no alpha — composite with
  `mix-blend-mode: multiply` rather than requesting transparency.
- For parallel variants, put copy in one shared component every variant
  imports; structural prevention beats instruction.
- Restate standing rules in every subagent brief.

### Fixed
- **The comparative critic is centripetal.** It was recommended
  unconditionally; it pulls work toward its references by construction, so
  it is right for polish against a known bar and wrong when the goal is
  divergence.
- **The `naturalWidth` resolution check was wrong** and produced a
  confidently-reported bug that did not exist. Chromium downscales decoded
  bitmaps, so the value under-reports and varies run to run. Use a fresh
  `new Image()` decode or curl the URL.
- Tall-page captures fail three ways silently — the ~16,384 device-px
  `fullPage` ceiling, page-tall blend layers dropping sections, and fixed
  layers rendering once. Above ~8,000 CSS px, viewport chunks are the only
  trustworthy method.

## 0.4.0 — unreleased

### Fixed
- Codex install, verified end to end for the first time. Three bugs, all
  found by running the documented commands rather than trusting them:
  `codex plugin add <name>` needs an `@marketplace` suffix; the marketplace
  manifest's `source` must be the string `"./"`, not an object, which
  otherwise fails with "plugin not found in marketplace"; and Codex reads
  `.agents/plugins/marketplace.json`, not the `.claude-plugin` path.
  Confirmed installed and enabled on codex-cli 0.146.0, with all three
  references and the preflight script packaged and runnable.

### Added
- Variants must be verified with a production build, not just a dev server.
  A prerender or static-export crash is invisible to both a dev server and
  a type-check.
- README now flags the fal.ai reference as a dated snapshot with a
  verification procedure.

## 0.3.0 — unreleased

First end-to-end run: all eight techniques executed against two real
codebases, ~20 variants built, one page taken through every stage.

### Verified
- Technique 4 (Codex image generation) and Technique 5 (fal.ai video) both
  work. The fal reference was wrong in nine places and is corrected.
- The comparative critic prompt beats gap-counting on every axis and is now
  the recommended variant.
- The settled-decisions list stops a critic contradicting itself between
  iterations.

### Corrected
- Seed guidance. The lever is the *derivation instruction*, not the seed
  source: fourteen runs across five seed types all produced an artifact or
  instrument register, and only changing how the model reads the seed broke
  the pattern. Four of those were the source procedure verbatim on a
  greenfield app, which rules out this being an artifact of redesigning live
  products.
- Copy fidelity is a stage rule, not a global one. Locking strings locks
  structure.
- The default layout is a diagnostic, not something to ban.
- The critic score is triage, not progress — measure gap turnover.
- Preflight no longer blocks projects that legitimately use OpenAI or Gemini.

### Added
- Facts have provenance: sourced-from-code is not cleared-to-publish.
- Technique 4 may not generate anything a visitor would read as evidence.
- An asset placed where nobody can see it is an asset you did not buy.
- Codex support: `.agents/skills`, `.codex-plugin/`, marketplace manifest.

## 0.2.0 — unreleased

### Added
- Codex support. Codex implements the same Agent Skills standard
  (agentskills.io), so `SKILL.md` ports unchanged — but it scans
  `.agents/skills`, which this repo did not have. Adds a `.agents/skills`
  symlink for zero-config repo pickup, `.codex-plugin/plugin.json`, and
  `.agents/plugins/marketplace.json`, so `codex plugin marketplace add` works
  the same way `/plugin marketplace add` does in Claude Code.
- README documents the one substitution needed outside Claude Code: the
  design critic needs a fresh context on a bigger model, which other tools
  reach by shelling out to a clean session rather than via a subagent tool.

## 0.1.1 — unreleased

### Fixed
- Preflight hard-blocked projects that legitimately use OpenAI or Gemini at
  runtime. The leak check assumed any `OPENAI_API_KEY` in `.env.local` was a
  stray design-time key; a real product referencing it in ten source files got
  `BLOCKED` on a completely correct setup. The check now greps the codebase:
  a key the source reads is reported as an app key and passes, a key nothing
  reads warns (exit 10) instead of blocking. Found by running the skill against
  a second, unfamiliar project.

## 0.1.0 — unreleased

First packaged version. Adapted from Anshu Chimala's "How to turn your AI into a
world-class designer" (Lenny's Newsletter, 1 September 2026).

Everything below was found by running the skill against a real Next.js project
rather than by reasoning about it.

### Added
- Three-stage process (Discover / Define / Deliver), eight techniques, three
  human checkpoints.
- `scripts/preflight.sh` — POSIX capability probe. Exits 0 ready / 10 degraded /
  20 blocked. Flags API keys leaking into app env files.
- `references/fal-video.md` — fal.ai setup and video pipelines, verified against
  fal's model pages on 2 September 2026.
- Copy-integrity rules. Agents pasted supplied copy faithfully then invented
  eyebrows and captions around it — which is both a voice violation and the
  single most reliable AI design tell.

### Fixed
- `$0` in SKILL.md was clobbered by skill-loader argument substitution, so
  dollar amounts rendered as the caller's arguments. Currency is now written as
  `USD`.
- Seed strings converged on one genre. Three independent base64 seeds produced
  three palettes but all three were "printed paper artifact" — agents read the
  seed's medium as a design brief. Fixed by varying encoding and explicitly
  stripping the medium.
- Critic-loop guidance now covers the plateau: a stateless critic can reverse
  its own prior instruction, so the score tracks what it can find rather than
  whether the page improved.

### Known limitations
- The seed-encoding fix has not been isolated from the accompanying blocklist;
  a clean experiment is still outstanding.
- fal.ai model slugs and prices are a point-in-time snapshot and will drift.
