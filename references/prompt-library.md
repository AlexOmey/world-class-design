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

**Why the shell script matters:** the model cannot generate randomness — asking it to "choose at random" returns tokens that sound random and aren't. `/dev/urandom` is outside the model.

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
