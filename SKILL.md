---
name: world-class-design
description: End-to-end process for getting distinctive, non-generic design out of AI coding agents — seed strings for real variety, ambitious briefs, a design-critic subagent scoring loop, image/video generation for texture, then subtractive polish. Use when starting a UI, landing page, app screen, or deck from a blank page and it must not look AI-generated, or when the user says "this looks like AI slop", "make this design unique", "why does my design look generic". Do NOT use for auditing an already-finished design (use a design-review skill) or for choosing a design system.
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Agent
  - AskUserQuestion
  - WebSearch
  - WebFetch
---

# World-Class Design

Adapted from [How to turn your AI into a world-class designer](https://www.lennysnewsletter.com/p/how-to-turn-your-ai-into-a-world) — Anshu Chimala (ex-Apple AI R&D), Lenny's Newsletter, 1 Sep 2026.

## The premise

An LLM picks the most probable next token. Great design is the *least* probable choice that still works. Left alone, a model returns the centre of its training distribution: purple gradient, text left, graphic right. Every technique here exists to push the model off that centre and then pull it back to something shippable.

Three stages, eight techniques:

| Stage | Goal | Techniques |
|---|---|---|
| **Discover** | Escape the default. Go broad. | 1. Seed strings · 2. Ambitious briefs |
| **Define** | Give it an identity. Go deep. | 3. Critic loop · 4. Image gen · 5. Video gen |
| **Deliver** | Make it shippable. Cut back. | 6. Subtract · 7. Kill AI tells · 8. Rewrite copy |

**The user's taste is the input that makes this work.** Techniques 2, 6 and 8 are checkpoints where you stop and ask them — do not auto-pilot through them. Pasting AI-generated ideas back into AI produces something anyone could have produced.

Full prompts: [references/prompt-library.md](references/prompt-library.md).
Tells checklist: [references/ai-tells.md](references/ai-tells.md).
fal.ai video: [references/fal-video.md](references/fal-video.md).

## Step 0 — Preflight (run this first, every time)

```bash
sh scripts/preflight.sh
```

Read-only, ~instant, safe to re-run. It probes the environment and exits:

| Exit | Meaning | What you do |
|---|---|---|
| **0** `READY` | All eight techniques available | Say one line — "preflight clean, all eight techniques available" — and **go straight to Stage 1**. Do not walk a configured user through setup. |
| **10** `DEGRADED` | Core works, enrichment missing | Name exactly what's unavailable, offer to fix it, and let them decline. Proceed either way. |
| **20** `BLOCKED` | Core dependency missing, or a **key is leaking into an app env file** | Stop. Fix, re-run preflight, then continue. |

Add `--verify` to confirm the fal key actually authenticates (one free API call, costs nothing). Worth doing on a genuine first run.

**Also check one thing the script cannot see:** can you screenshot the running design? Any browser automation (built-in browser tool, Playwright MCP, chrome-devtools MCP) or a simulator tool for native apps. Without it, Technique 3 — the highest-leverage step — cannot run. Say so plainly rather than substituting your own judgment for the critic's.

### Closing the gaps

**Do these yourself, no need to ask** — they're local, reversible, and non-destructive:

- `mkdir -p ~/.config/fal` and `chmod 600` on any key file
- adding `.env.agents` to `.gitignore`
- writing the dev-only-keys note into `CLAUDE.md` / `AGENTS.md`

**Ask first, then do it:** installing `ffmpeg` or `jq` via a package manager — it's a system change.

**You cannot do these; give exact steps and hand over.** They need a human at a dashboard with a payment method:

- creating a fal.ai account, issuing a key, loading credit → [references/fal-video.md § 1](references/fal-video.md#1-setup--adding-your-fal-api-key)
- creating an OpenAI/Gemini key, or holding a ChatGPT subscription for Codex CLI image generation

> **Never ask the user to paste an API key into the chat.** It lands in the transcript and any session log. Give them a command to run in their own terminal:
> ```bash
> mkdir -p ~/.config/fal && printf 'FAL_KEY=%s\n' 'PASTE_KEY_HERE' > ~/.config/fal/env && chmod 600 ~/.config/fal/env
> ```
> Then re-run `sh scripts/preflight.sh --verify` to confirm. If a user pastes a key anyway, write it to the file, `chmod 600`, and tell them to rotate it.

**If preflight reports `leak-risk`** — a `FAL_KEY` or `OPENAI_API_KEY` sitting in `.env`, `.env.local`, or `.env.production` — move it out, and tell the user to **rotate the key**, not just relocate it. Those files get committed, synced to hosting dashboards by `vercel env pull`/`push`, and inherited by the running app. Treat it as already exposed.

### Degrading honestly

When a capability is missing, say so and carry on with the rest. **Never paper over a gap**: no CSS gradients standing in for generated images, no self-assessment standing in for the critic, no invented API keys. A gradient substituted for real artwork reintroduces the exact tell this skill exists to remove.

---

## Copy integrity (applies to every stage)

**Copy is content, not design material.** The design adapts to the words; the words do not adapt to the design. Put this in every build and refine prompt — without it, agents rewrite freely and you lose the user's voice while they are looking at colours.

| Operation | Allowed? |
|---|---|
| Ship supplied copy verbatim | Yes — the default |
| Omit a supplied line entirely | Yes, if the design genuinely has no room |
| Truncate / trim a supplied line | Yes, sparingly, if length breaks the layout |
| Rewrite, paraphrase, or "punch up" | **No** |
| Invent new visible text | **No** |

**The leak is almost never the body copy — it's the chrome.** Agents faithfully paste the bio and then invent an eyebrow, a section label, a caption, a tagline, a CTA microcopy line, a footer slug. Observed in a single run: `The Weekly Dispatch`, `A decade on one thread`, `I ship AI products and write down what happens. Based in London, usually in an editor.` None were briefed.

That is two failures at once: it overwrites the user's voice, and invented eyebrow labels are the **first row of [ai-tells.md](references/ai-tells.md)** — the most reliable AI tell there is. So the rule: if the brief did not supply text for a slot, either reuse supplied text or leave the slot empty. Do not fill it.

**The seed must not reach the page.** "Don't reveal the string" is too narrow — the leak is the seed's *derived vocabulary* surfacing as rendered text. A run seeded toward weaving shipped a visible label reading `Warp & Weft · London`. Class names, CSS comments and file names may use the seed's vocabulary freely; **anything a visitor can read may not**.

**Report every deviation.** End each build with an explicit list of copy changed, trimmed, or omitted. Copy is the user's call under Technique 8 — an implementer may propose a cut, never decide one.

---

## Stage 1 — Discover

### Technique 1: Seed strings (always do this)

Never build the first version from a bare brief. Generate real entropy outside the model and use it as creative input:

```
Generate a long random alphanumeric string with a shell script.
Define the creative direction (colour, layout, typography, motion) from that
string — look past the surface for subpatterns, repeated runs, special numbers,
anything that suggests a direction. Use your judgment to make it look great.
Do not reveal the string in the design; it is inspiration only.
```

Asking a model to "be random" does not work — it predicts tokens that *sound* random. The randomness has to come from `head -c 64 /dev/urandom | base64` or similar.

**Vary the seed encoding across variants, and tell the model the seed has no medium of its own.** A base64 blob looks like machine output you would print and file, and models read that connotation as direction — in a real 3-variant run, three independent seeds produced three palettes but one genre (printed paper artifact). Use base64 / hex / decimals / random dictionary words across the batch, and add the medium-stripping line from [the prompt library](references/prompt-library.md#-the-medium-trap--read-this-before-running-variants). This is the single biggest failure mode of Technique 1.

**Run 3–4 variants in parallel**, each with its own seed and encoding, as independent subagents so the seeds do not contaminate each other. Present all of them to the user.

### Technique 2: Ambitious briefs

Vague briefs get median output. Name a concrete world:

- "bold pixel art, each section a still from a video game, still functions as a landing page"
- "isometric living 3D city, features are neighbourhoods"
- "radically asymmetric, dissonant colour and type, uncomfortable negative space — break the rules and still make it good"

To find one, run the three-step ideation ladder in the prompt library: broad shallow list → the user reacts to favourites in their own words → model sharpens → model writes the build prompt.

Ideas that sound like they will not work are the good ones. If a run fails, keep the prompt in the project and retry it when a stronger model ships.

### ⏸ Checkpoint 1
Show the user every variant. Ask which direction to take forward, and what they reacted against. Do not pick for them.

---

## Stage 2 — Define

### Technique 3: The design-critic loop (the highest-leverage step)

The building agent cannot judge its own work — it sees its code and its reasoning, not the page. Split the roles:

- **Implementer:** the current session or a cheaper-model subagent. Writes code.
- **Critic:** a *fresh* subagent on a bigger model, given **only the screenshot**. No code, no implementation notes, no earlier critiques, no score history.

Each iteration:
1. **Screenshot the current state**, using whatever browser automation you have. What matters is the artefact, not the tool: the whole page top to bottom at desktop width, and the same again at 390px. Most layout faults surface at 390px first.
2. Spawn the critic with the **exact same prompt every time** (verbatim text in the prompt library).
3. Apply its feedback.
4. Repeat.

**The critic captures its own screenshots.** You cannot hand an image to a subagent, so its prompt must tell it how to reach the page. This does not weaken the isolation — that comes from *forbidding it to read source code*, not from withholding the browser. Give it the URL and the capture instructions, nothing else.

If captures come back blank, truncated, or timed out, see [Troubleshooting screenshots](#troubleshooting-screenshots) at the end of this file before changing approach.

**Stop at 9/10, and never tell the critic that 9 is the target** — a critic that knows the bar will drift to meet it. Hold the threshold in the orchestrator.

Run 1–2 iterations first and check the score is actually climbing before committing to more. If it plateaus or oscillates, stop and show the user — a stuck score means the critic is now grading itself, not the page.

**A stateless critic will contradict itself. Plan for it.** Observed in a real run, same page, consecutive iterations:

> Iteration 1: *"The two-spot-ink conceit is skin-deep — the headline says print and everything else says Tailwind."*
> Iteration 2, after the implementer spread the effect: *"Misregistration is applied to everything. It's the AI-era pink-offset-shadow trope. Keep it on the hero name only."*

Fresh context is what keeps the critic honest, and it is also what lets it reverse its own instruction. Combined with "name the biggest gaps" — which guarantees a list whatever the quality — the score tracks *how much it can find*, not whether the page improved. That run scored 5/10 twice across a large, genuine improvement.

Three defences:

1. **Keep a settled-decisions list** outside the loop. When the user or you accept a direction, write it down and pass it to the critic as constraints: "these choices are settled, judge everything else." This preserves fresh context on *quality* while stopping it relitigating *direction*.
2. **Prefer the comparative prompt.** Ranking your screenshot against 4 professional references resists this failure far better than gap-counting, because the bar is external and fixed rather than regenerated each run. If you have references, use that variant — this is the concrete reason it's rated "Best" above.
3. **Diff against the previous screenshot yourself.** The critic cannot see that its new gap 3 was created by fixing its old gap 2. In the observed run, chasing "make it bleed off the trim" truncated the wordmark, and mobile wrapped it mid-word. Only the orchestrator can catch a regression like that — compare before and after every iteration, and treat a new fault in previously-fine territory as a stop signal, not a finding.

Grade the critic's own prompt on this scale:
- Bad: "judge whether this looks beautiful" — subjective, wild variance run to run.
- OK: "review the aesthetic being attempted, imagine how a top studio would execute it, score against that bar."
- Best: "here are 5 images — 4 professional references and 1 screenshot of ours. Rank them by polish and taste." Concrete, visual, objective.

If the user has reference screenshots, pass them as a **moodboard / baseline, not a target** — say so explicitly or the critic pushes toward a copy.

Cost note: in the source's runs the big critic model was under 10% of output tokens. Cheap model builds, expensive model judges.

### Technique 4: Image generation

Coding agents reach for gradients, blobs and CSS shapes because those are code. Those are exactly the tells. Generate real images instead.

Check for a route in this order:

1. **A built-in image generation tool** in the current agent, if it has one. Agents that have these routinely under-use them until told to.
2. **Codex CLI** — `command -v codex`. If present: "use the Codex CLI to generate images, billing my subscription rather than an API key." No marginal cost where the user has a ChatGPT subscription.
3. **An OpenAI or Gemini key** the user supplies. If they paste one, write it to a gitignored `.env.agents`, note in `CLAUDE.md`/`AGENTS.md` that it is dev-only, and never let it reach shipped code.

If none are available, say so and continue without images rather than silently falling back to gradients.

Verify results frame-by-frame in the browser — generated assets often land at the wrong crop or contrast.

### Technique 5: Video generation via fal.ai

The most underused technique in the set. Video models are not just for UGC ads — they produce motion and material effects (refraction, caustics, physical weight) that no amount of CSS will reach.

**Full working reference: [references/fal-video.md](references/fal-video.md)** — setup, API shape, current model slugs, keyframe parameter names, matting models, both pipelines. Read it before writing any fal code; several details are counter-intuitive and fal's own docs are wrong in at least one place.

Use fal.ai as the aggregator so one key reaches every model and the agent can pick per job.

**Before the first run, check for a key and onboard if it's missing:**

```bash
[ -n "$FAL_KEY" ] && echo "set in env" || \
  grep -ls '^FAL_KEY=' .env.agents .env ~/.config/fal/env 2>/dev/null || \
  echo "not configured"
```

If it prints `not configured`, walk the user through **[fal-video.md § 1 Setup](references/fal-video.md#1-setup--adding-your-fal-api-key)** — key from https://fal.ai/dashboard/keys with `API` scope, stored user-level at `~/.config/fal/env` (it's a personal design-time credential used across projects, not a project secret), verified with a free model call before any spend. Never fabricate a key, and never silently skip to CSS gradients instead; say the key is missing and carry on with the rest of the design work.

**Never put this key in the app's own env file** — not `.env.local`, `.env`, or `.env.production`. Those define what the *application* runs with; this key is for what the *agent* uses while designing. Mixing them ships a design-time credential to production via `vercel env pull`/`push` and hosting dashboards.

Two things to say before the user tops up:

1. **fal has no spend caps** — no per-key or per-account budget limit exists, so the usual "make a key with a tight spend limit" advice does not apply. The only real control is loading a small amount of prepaid credit.
2. **Video is the expensive step.** A single 30s Seedance 2.5 clip at 720p is roughly USD 14. Draft on a USD 0.05/s model, run the keeper once on the good one.

**Two workflows:**

- **Animated graphics that layer into the UI.** Render the clip over the page's *actual background colours* first — for glass, chrome or water this bakes correct refraction and cast shadows into the frames, which cannot be added later. Then matte the background out with `fal-ai/birefnet/v2/video` (free, and the only endpoint that returns a separate matte). Output **VP9/WebM or ProRes4444** — every MP4 path silently composites transparency to black, which is the usual cause of a black box around a matted clip.
- **Scroll-scrubbed state transitions.** Generate keyframe stills, interpolate video between each pair, and seed each next clip from the previous clip's **final frame** to keep the chain continuous. Scrub the timeline against scroll position rather than playing it. Keep clips 3–6s or the interaction feels unbuffered.

**Keyframe interpolation is where this usually breaks:** the first/last-frame parameter names differ per model (`start_image_url`/`end_image_url` vs `image_url`/`end_image_url` vs `image_url`/`tail_image_url`). Default to `fal-ai/kling-video/o1/image-to-video`, which is purpose-built for start→end and requires citing the frames as `@Image1`/`@Image2` in the prompt. Check the table in the reference before coding.

**Always download the outputs.** fal's hosted files expire, and they are public by default.

### ⏸ Checkpoint 2
Show the user before/after. Confirm the identity is theirs before polishing it.

---

## Stage 3 — Deliver

### Technique 6: Subtract

AI adds; it almost never removes, because deleting code is the risky choice. Most of the polish budget goes here. Walk the design and cut:

- decorative glows, background gradients, gradient progress bars
- coloured highlights on text that carry no meaning
- labels the adjacent image or layout already communicates
- containers and cards that hold one thing
- custom controls that look worse than the platform's native ones

Then rebuild toward: image-centric grid, no unnecessary containers, native components, smaller and tighter type. Restraint is what reads as premium.

### Technique 7: Kill AI tells

Pull up [references/ai-tells.md](references/ai-tells.md) and walk the design against each row.

**Do not ban these patterns up front.** A blanket ban makes the model overthink and invent stranger patterns. Check for them at refinement time, try the alternative, keep whichever is better.

### Technique 8: Rewrite copy by hand

Treat model-written copy as Lorem ipsum — structural placeholder, not content. It is the single biggest signal of slop, and it has nothing to do with the pixels.

Every line gets rewritten by a human in one voice. Human copy is nearly always shorter, plainer, and less eye-rolling.

If the project or user has a house-voice or de-AI-ing skill available, load it for this step. Otherwise apply the copy checklist at the end of [references/ai-tells.md](references/ai-tells.md).

### ⏸ Checkpoint 3
Hand the copy to the user. This step is theirs, not yours — flag it as the one thing you cannot do for them.

---

## Operating notes

- **Parallelism is the point.** Stage 1 variants and Stage 2 critic runs are independent — dispatch them concurrently in a single message.
- **Look at the render, not the diff.** A design fault is visible in a screenshot in one second and invisible in a code review for an hour.
- **Do not optimise the score.** The critic score finds faults; it does not grant permission to ship. Past a point, pushing the number makes the page worse. The user decides.
- **Keep the losers.** Save prompts that produced bad output in the project. Re-run them when a new model ships — that is how you know you are using the current ceiling.

---

## Troubleshooting screenshots

Use whatever browser your agent has. These are failure modes observed in practice, not a required setup — skip this section unless captures are actually misbehaving.

| Symptom | Cause | Fix |
|---|---|---|
| Screenshot times out; looks like a hang | The browser pane is not displayed, so the page stops compositing frames | Front the tab first, then retry |
| Capture is blank below the fold, fine at the top | Same compositing problem, at scroll offsets | Use a headless driver (Playwright, chrome-devtools) for below-the-fold sections |
| Screenshot file cannot be read back | A relative filename resolved inside the driver's own output directory | Pass an **absolute** path *inside the project root* — drivers are usually jailed to it, so a system temp or scratchpad path is rejected |
| Page looks half-faded or empty | Captured mid scroll-reveal animation | Wait ~3s after load before capturing |
| Design looks fine to you, critic disagrees wildly | You screenshotted a different state than it did | Pin both to the same URL and viewport |

A headless driver is generally the more reliable choice for an automated loop — no visible window to go stale. Whatever you use, confirm the first capture is actually a faithful picture of the page before you start trusting scores built on it.
