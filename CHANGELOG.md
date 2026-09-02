# Changelog

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
