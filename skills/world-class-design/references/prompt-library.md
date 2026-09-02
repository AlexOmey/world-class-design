# Prompt library

Copy-paste prompts for each technique. Adapted from Anshu Chimala's post; the wording is load-bearing, so change the subject matter but keep the structure.

---

## Technique 1 — Seed string variety

```
I want you to build me <THING>.

Follow this procedure:
1. Generate a long, random alphanumeric string using a shell script.
2. Define the creative direction (colour scheme, layout, typography, motion)
   based on the string. Look beyond the surface for subpatterns, special
   numbers, anything that inspires you.
3. Use your judgment to bring this direction to life and make it look great.

Don't reveal the string in the design. It's only for your inspiration.
```

Run 3–4 of these concurrently as independent subagents. Each gets its own seed and never sees the others.

**Append the right copy block to every build prompt** (see [Copy: two modes](../SKILL.md#copy-two-modes-by-stage)). Which one depends on the stage — using the fidelity block during exploration is the most common way to strangle Stage 1 variety, because locking the strings locks the structure.

**Exploration (Stages 1–2) — copy is scaffolding:**

```
COPY — EXPLORATION MODE:

- Treat existing copy as a message spec, not a script. You may rewrite
  headlines, merge or split or reorder sections, cut chrome, and change
  length and register. Restructuring the message is part of your proposal.
- What each section must still ACCOMPLISH is fixed; the sentences are not.
- FACTS ARE NEVER INVENTED OR ALTERED. Prices, plans, guarantees, refund
  terms, capabilities, integrations, model names, compliance claims,
  metrics, customer names and quotes come from the codebase or the
  approved source, verbatim. Cite where you got each one. If two sources
  disagree, STOP and report the conflict — do not pick one.
- The seed must not reach the page. Its derived vocabulary must not appear
  in ANY string a visitor can read. Class names, CSS comments and
  filenames may use it freely.
- End with a PROPOSED COPY list: everything you rewrote, cut, merged or
  wrote fresh, and the source of every fact. All of it is provisional and
  subject to approval.
```

**Fidelity (Stage 3) — copy is the user's:**

```
COPY — FIDELITY MODE:

- Every approved string ships VERBATIM. Do not rewrite, paraphrase,
  shorten or "punch up" copy to suit the layout. Adapt the design to the
  words, not the words to the design.
- If a line genuinely does not fit you may omit or trim it. You may not
  reword it. List anything you omit or trim.
- Do not invent copy silently. Functional labels the design needs are
  fine — "Pricing", "FAQ", a field's "Email". Decorative editorial is not:
  eyebrows that restate the heading, invented taglines, section kickers,
  footer slugs, made-up product names.
  The test: if a string carries VOICE it is the user's; if it carries
  FUNCTION it is the design's.
- If an approved string is itself an AI tell (an eyebrow that restates the
  heading, say), do NOT cut it. Flag it as a recommendation and let the
  user decide.
- FACTS ARE NEVER INVENTED OR ALTERED — same list as exploration mode.
- End with a PROPOSED COPY list for approval.
```

> ### What is the source article's, and what is this repo's
>
> **The four-step alphanumeric procedure above is the source article's, reproduced faithfully.** So is the derivation instruction — read subpatterns and special numbers out of the string.
>
> **Everything below this box is this repo's findings from running it**, not the author's advice: the medium trap, the alternative seed sources, the preference for word seeds, and the structural-archetype axis. Do not read "prefer word seeds" as his recommendation. He proposes an alphanumeric string and nothing else.
>
> **What the article claims** is that outputs become much more varied — different colour schemes, fonts and ideas. It does **not** claim the structure varies. So the finding that seeds leave the layout archetype untouched extends his claim rather than contradicting it; it measures against a bar he did not set.
>
> **The testing conditions also differ, and that probably matters.** The article demonstrates the technique greenfield: a generic productivity app, no existing site, no approved copy, no codebase. Every run behind the findings below was a *redesign of a live product* with an existing landing page, real copy and section components sitting in the same repo. That existing page is itself a strong attractor, and it is a plausible reason these runs collapsed harder than the article's did. Sample sizes are small on both sides — four outputs shown in the post, three to four per condition here.

**Why the shell script matters:** the model cannot generate randomness — asking it to "choose at random" returns tokens that sound random and aren't. `/dev/urandom` is outside the model.

### ⚠️ The medium trap — read this before running variants

A base64 seed carries an aesthetic of its own. It *looks like* machine output you would print and file, and models read that connotation as design direction. Observed in a real 3-variant run: three independent `/dev/urandom` base64 seeds produced three different palettes but **one genre** — printed paper artifact. Two of the three agents said so unprompted:

> "it's base64 — machine text you'd print out and file"
> "base64 itself = machine-encoded text → the overall conceit: this is a press proof sheet"

The entropy was real. The framing collapsed it.

**Changing the encoding alone does not fix this — it relocates the mode.** A follow-up run used hex, decimal and word seeds, plus an explicit ban on the paper genre. Result: hex → glazed ceramics, decimals → glazed ceramics, words → boreal earth and firelight. Two different numeric encodings independently landed on the *same* new genre. Banning one attractor moves the model to the next one; it does not create variety.

The reason: a numeric seed offers only **structure** — runs, ratios, clusters. The model must supply the semantics itself, and it draws them from the same prior every time. A **semantic seed supplies meaning from outside the model**, which is the entire point of seeding.

> **Prefer word seeds for direction. Use numeric seeds for detail.** The strongest combination is a word seed for the genre, and a numeric seed for proportions, spacing and palette derivation inside it.

Two further fixes, use both:

**1. Strip the medium in the prompt.** Add this line to the procedure:

```
Treat the string as abstract data. It has no medium, genre, or aesthetic of
its own — the fact that it looks like machine output must not influence the
direction. Read structure from it (runs, ratios, digit clusters, hex-legal
pairs), not connotation.
```

**2. Vary the encoding across variants**, so no single format's connotation dominates the batch:

```bash
head -c 32 /dev/urandom | base64                        # variant A
head -c 16 /dev/urandom | xxd -p                        # variant B — hex
od -An -tu1 -N16 /dev/urandom | tr -s ' ' ,             # variant C — decimals
shuf -n 8 /usr/share/dict/words | tr '\n' ' '           # variant D — words
```

The word-list seed is the strongest corrective: it has no machine-artifact connotation at all, and it pushes the model toward semantic rather than typographic association.

Technique reference: [String Seed of Thought, Sakana AI](https://sakana.ai).

---

## Technique 2 — Ambitious brief ideation ladder

**Step 1 — broad and shallow.** The point is to spark the user's imagination, not to pick a winner.

```
I want to come up with a bold, unique design language for my product.
Can you list as many ideas as you can, with short, high-level descriptions?
Go broad, not deep.
```

**Step 2 — the user reacts.** They pick favourites and describe their reaction in their own words. This is where the taste enters; a model cannot supply it. Example of the shape of a good reaction:

```
Industrial Control Panel:
- I'm imagining something tactile. Clicky, satisfying buttons, nice sounds.
- Initially I pictured something cartoony or skeuomorphic, but this feels
  tacky to me. Avoid that.
- Instead I want consistent components and little touches that land this look
  without going overboard.
- Gray gradients would look boring. Need more texture. Maybe incorporate some
  colour while retaining the control panel feel?

Can you sharpen this one based on my tastes?
```

**Step 3 — convert to a build prompt.**

```
Can you write a concise prompt that an AI agent could use to build an initial
POC page with this?
```

**Example finished briefs:**

- "Build me a landing page for my productivity app, with a bold pixel art theme and stunning graphics. Each section should feel like a still from a video game, yet somehow it should all function as a landing page."
- "Build me a landing page for my productivity app, set in an isometric living 3D city, where different features are somehow represented by neighbourhoods or buildings."
- "Build me a landing page for my productivity app, with a radically asymmetric layout, dissonant colours and typography, and uncomfortable negative space. Break all the rules but still make it look good."

---

## Technique 3 — Design critic loop

### Orchestrator prompt (to the implementing agent)

```
I want you to improve this design. To figure out what to focus on, use a
<BIG MODEL> subagent as a design critic.

Follow this procedure at each iteration:
1. Capture a screenshot of the current design.
2. Invoke the critic in a fresh context, with just the screenshot — not the
   code, implementation details, or earlier iterations/critiques.
3. Ask it to evaluate the aesthetic the design is going for, imagine how a top
   design studio would execute this aesthetic, then outline the biggest gaps.
4. It should provide a score out of 10 indicating how close the current design
   is to that studio-level quality bar.

Provide this guidance to the critic in its prompt:
- Think high-level about overall structure and composition, and also look at
  the fine details.
- Watch out for patterns that feel overdone, excessive, or otherwise obviously
  AI-generated, and penalise them.
- Provide tight, specific feedback, not vague prose.
- Be bold and opinionated, not safe or easy.

Your work is only complete when the critic independently deems it 9/10 or
higher. Do not put that criterion in the critic prompt; keep it objective in
its scoring. Use the same critic prompt each time.
```

### Critic prompt (verbatim, unchanged every iteration)

```
You are a design critic. You are looking at a screenshot of an in-progress
design. You have no information about how it was built and you do not need any.

1. Identify the aesthetic this design is reaching for.
2. Imagine how a top design studio would execute that aesthetic.
3. Name the biggest gaps between what you see and that execution.
4. Score the design out of 10 for how close it is to that studio-level bar.

Rules for your critique:
- Cover both the high-level structure and composition, and the fine details.
- Penalise patterns that feel overdone, excessive, or obviously AI-generated.
- Be tight and specific. No vague prose, no compliments padding the list.
- Be bold and opinionated. Do not fall back on what is safe or easy.
```

In Claude Code, dispatch this with the `Agent` tool and `model: "fable"` (or `"opus"`), one call per iteration, so each critic starts clean.

### Better critic prompt when references are available

```
Here are 5 images: 4 are professional designs, 1 is a screenshot of our
product. Rank all 5 by polish and taste level, and explain each placement.
Treat the professional examples as a baseline and a moodboard, not a target —
do not tell us to copy them.
```

Concrete and objective beats evocative. Use this variant whenever the user can supply reference screenshots.

### Loop hygiene

| Rule | Reason |
|---|---|
| Fresh context per critique | A critic that remembers its last note defends it |
| Screenshot only, never code | Code makes it grade effort instead of output |
| Identical prompt every time | Otherwise scores are not comparable across iterations |
| Stopping threshold stays with the orchestrator | A critic that knows the bar drifts to meet it |
| Test 1–2 iterations before committing to more | Confirms it converges instead of burning tokens |
| Big model critic, small model implementer | Critic was <10% of output tokens in the source's runs |

---

## Technique 4 — Image generation

```
The design is pretty plain. Add more personality using image generation.
Consider shaders or 3D effects in combination with images to create more
interesting visuals.

For image generation, use <the key in .env.agents / the Codex CLI>.
Verify that your work looks right frame-by-frame in the browser.
```

**Routing, in preference order:**

1. **Codex CLI**, if `command -v codex` finds it — "Use the Codex CLI to generate images. Make sure it's billing my subscription, not an API key." No marginal cost where the user has a ChatGPT subscription.
2. **`.env.agents`** — gitignored file holding an OpenAI/Gemini key with a tight spend limit, noted in `CLAUDE.md`/`AGENTS.md` as dev-only, never shipped.
3. **Nothing available** — say so. Do not silently fall back to CSS gradients; that is the exact failure this technique exists to prevent.

---

## Technique 5 — Video generation

Use an aggregator (fal.ai) so one key reaches many models and the agent can pick.

**Read [fal-video.md](fal-video.md) first** — slugs, queue-API gotchas, keyframe parameter names and matting formats. Never paste the key into the prompt; put it in a gitignored `.env.agents` and reference it.

### Animated graphic with a transparent background

```
Replace the image on this page with a looping video clip that does something
more interesting. <describe the motion>.

To get convincing refraction effects, render the video over the page
background colours FIRST (so refraction, caustics and cast shadows bake into
the frames), then remove the background with a video matting model.

Read references/fal-video.md for the API and model slugs. The fal key is in
.env.agents — read it from there, don't echo it.

Requirements:
- Matte with fal-ai/birefnet/v2/video and output VP9/WebM, so alpha survives.
  Do not output MP4 — it composites transparency to black.
- Verify the loop is seamless; if the last frame doesn't meet the first,
  interpolate back to the first frame and concatenate.
- Download the output immediately; fal's hosted files expire.
- Check the result in the browser before calling it done.
```

### Scroll-scrubbed state transitions

```
Build a demo page for <SUBJECT> that uses a video model to create interactive
transitions between screens. Each screen shows <SUBJECT> in a different state,
with vertical motion appropriate for scrolling:
  1. <state one>
  2. <state two>
  3. <state three>

Generate the initial frame with image generation. Then generate a video clip
that starts from that frame and animates to the next state. Use the FINAL
FRAME of that video to seed the next transition so it continues seamlessly.
Scrub through the transitions as the user scrolls (scrub the timeline against
scroll position — do not autoplay).

Read references/fal-video.md for the API and model slugs. The fal key is in
.env.agents — read it from there, don't echo it.

Requirements:
- Use fal-ai/kling-video/o1/image-to-video for the interpolation; it takes
  start_image_url + end_image_url and needs the frames cited as @Image1 and
  @Image2 in the prompt.
- Keep each clip 3-6s and preload, or the scrub will feel unbuffered.
- Draft the prompt on a cheap model first, then run the keeper once.
- Download every output; fal's hosted files expire.
```

Extract a final frame to seed the next clip:
```bash
ffmpeg -sseof -0.1 -i clip1.mp4 -update 1 -q:v 2 last.png
```

---

## Technique 6 — Subtraction

```
This is over-designed. Dial it back:
- Simplify the layout into an image-centric grid
- Get rid of gradients, glows, and unnecessary containers
- Use native platform components instead of custom ones
- Aim for a truly minimalist aesthetic

Delete rather than restyle. If an element does not earn its place, remove it.
```

Note: asking for "clean and minimalist" up front does **not** produce this. The model still adds glows, gradient progress bars and redundant labels. The subtraction pass has to be a separate, explicit instruction after the design exists.

---

## Technique 8 — Copy rewrite

Model copy is placeholder. Rewrite by hand, then sanity-check the result.

If the project or user has skills for house voice, de-AI-ing prose, or plain technical writing, load the relevant one for this step — those beat any generic checklist. Otherwise use the copy rows in [ai-tells.md](ai-tells.md).

The human version is nearly always shorter, plainer, and drops the "it's not X, it's Y" constructions, the three-item lists, and the invented specificity ("Thursday afternoon", "1.4 seconds") that model marketing copy reaches for.
