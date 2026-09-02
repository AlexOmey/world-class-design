# fal.ai video generation

Working reference for Technique 5. Verified against fal's own model pages on 2 September 2026. Model slugs and prices move fast — **re-check the model page before relying on any row here**, and see [Verifying before you build](#verifying-before-you-build).

---

## 1. Setup — adding your fal API key

### Step 0 — check whether it's already configured

```bash
[ -n "$FAL_KEY" ] && echo "set in env" || \
  grep -ls '^FAL_KEY=' .env.agents .env ~/.config/fal/env 2>/dev/null || \
  echo "not configured"
```

If that prints `not configured`, walk the user through the rest. **Never guess or fabricate a key, and never proceed with the video technique without one** — falling back to CSS gradients is the exact failure Technique 5 exists to prevent. Say it's missing and continue with the rest of the design work.

### Step 1 — create the key

1. Sign in at **https://fal.ai** and open **https://fal.ai/dashboard/keys**.
2. **Add key** → scope **`API`**. That's enough to call hosted models; `ADMIN` is only needed to deploy your own code, so don't use it here.
3. Copy the key — fal shows it **once**. It looks like `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx:xxxxxxxx…`.
4. Add credit at **https://fal.ai/dashboard/billing**. New accounts have no free video tier. **Load a small amount first** — see the spend warning below.

### Step 2 — store it

The fal key here is a **personal design-time credential**, not a project secret. It belongs to you and gets used across every project you design in. Store it once, user-level.

**User-level (recommended for this skill):**

```bash
mkdir -p ~/.config/fal
printf 'FAL_KEY=%s\n' "$YOUR_KEY" > ~/.config/fal/env
chmod 600 ~/.config/fal/env
```

Load it only in the shell that runs a generation:

```bash
set -a; . ~/.config/fal/env; set +a
```

Sourcing on demand keeps the key out of unrelated processes. You *can* put that line in `~/.zshrc` for convenience, but then every process you launch inherits it — including `npm`/`pnpm` postinstall scripts, which is a live supply-chain exposure. Prefer on-demand.

**Project-local (`.env.agents`)** — use this instead only when the key is genuinely project-scoped: a team key, a client's key, or a per-project budget you want to keep separate.

```bash
printf 'FAL_KEY=%s\n' "$YOUR_KEY" >> .env.agents
grep -qxF '.env.agents' .gitignore 2>/dev/null || echo '.env.agents' >> .gitignore
chmod 600 .env.agents
```

Then add a line to the project's `CLAUDE.md` / `AGENTS.md`:

> `.env.agents` holds development-only API keys the coding agent may read and use. These must never be committed or shipped in product code.

> ### ⚠️ Do not put this key in the app's own env file
> Not `.env.local`, not `.env`, not `.env.production` — the files your framework loads at build and runtime.
>
> Those files define **what the application runs with**. This key is for **what the agent uses while designing**. Conflating them means the key travels with the app: it gets picked up by `vercel env pull`/`push`, synced to a hosting dashboard, inherited by the running server, and shipped to an environment that has no reason to hold it. In Next.js specifically, `.env.local` is loaded into the server runtime — a non-`NEXT_PUBLIC_` var won't reach the browser bundle, but it is still live credential in production for a capability production doesn't use.
>
> Separating agent keys from app keys is the entire point of the `.env.agents` convention. Keep that boundary.

**Do not** paste the key into a prompt, commit it, or hardcode it in page code. Read it from the file at call time.

### Step 3 — verify before spending

Call a **free** model. `fal-ai/imageutils/rembg` costs $0 and proves the key works for the thing you actually need it for:

```bash
set -a; . ~/.config/fal/env; set +a
curl -s -w '\nHTTP %{http_code}\n' -X POST https://fal.run/fal-ai/imageutils/rembg \
  -H "Authorization: Key $FAL_KEY" -H "Content-Type: application/json" \
  -d '{"image_url":"https://picsum.photos/id/237/200/200.jpg"}'
```

`HTTP 200` plus an output URL means you're good. `401` means the key is wrong or revoked.

> **Don't use `https://api.fal.ai/v1/account/billing` as the smoke test.** An `API`-scoped key returns `403 authorization_error` there — that endpoint needs `ADMIN` scope. A `403` from it says nothing about whether your key can call models. Verified 2 Sep 2026.

### Step 4 — first real call

Run one cheap clip end-to-end (a 3s `fal-ai/pixverse/v6/image-to-video` is a few cents) before wiring anything into a design. Confirms auth, the queue flow, and output download all work while the blast radius is small.

### Rotating / revoking

Delete the key at https://fal.ai/dashboard/keys and remove it from `.env.agents`. Note the known bug ([fal#939](https://github.com/fal-ai/fal/issues/939)): revoking a key does not release its in-progress concurrency slots.

> ### ⚠️ fal has no spend caps
> Common advice — "create a key with a tight spend limit" — **does not apply to fal**. There is no per-key or per-account budget cap, and no per-key rate limit. Key scopes are `API`/`ADMIN` only. It's prepaid credits with an account lock when the balance runs low, and credits expire 365 days after purchase.
>
> **The only real spend control is loading a small amount of credit.** Top up deliberately rather than keeping a large balance. Video is the most expensive thing in this skill: a single 30s Seedance 2.5 clip at 720p is roughly $14.
>
> Check the balance at **https://fal.ai/dashboard/billing**. The `GET /v1/account/billing` API needs an `ADMIN`-scoped key — an `API` key gets `403` — so don't script the balance check with the key you use for generation.

**Concurrency:** new accounts start at **2 concurrent requests** (rises to 40 with spend). Over-limit returns `429 concurrent_requests_limit`. Do not fan out ten clips in parallel on a fresh account.

**Clients** (optional — plain curl is fine):
```bash
pip install fal-client          # imports as fal_client
npm install --save @fal-ai/client
```
`@fal-ai/serverless-client` is deprecated (renamed at 1.0.0). Anything referencing it is 2024-era.

---

## 2. API shape

Auth header is **`Authorization: Key $FAL_KEY`** — `Key`, not `Bearer`.

### Sync (fast models only)
```bash
curl -X POST https://fal.run/fal-ai/kling-video/o1/image-to-video \
  -H "Authorization: Key $FAL_KEY" -H "Content-Type: application/json" \
  -d '{"prompt":"@Image1 ... @Image2","start_image_url":"https://...","end_image_url":"https://..."}'
```
Body is the raw input object — no `input:` envelope (that key is JS-SDK-only).

### Queue (use this for video — generations take minutes)

> **The #1 gotcha.** Submit uses the **full** model slug. Status / result / cancel use **only `owner/alias`** — everything after the first two segments is dropped. **fal's own queue docs page shows this wrong.**

```bash
# submit — FULL slug
curl -X POST https://queue.fal.run/bytedance/seedance-2.5/image-to-video \
  -H "Authorization: Key $FAL_KEY" -H "Content-Type: application/json" \
  -d '{"prompt":"...","image_url":"https://..."}'
# -> {"request_id":"...","status_url":"...","response_url":"...","cancel_url":"..."}

# status / result — owner/alias ONLY
curl "https://queue.fal.run/bytedance/seedance-2.5/requests/$REQ/status?logs=1" -H "Authorization: Key $FAL_KEY"
curl "https://queue.fal.run/bytedance/seedance-2.5/requests/$REQ"               -H "Authorization: Key $FAL_KEY"
```

**Safest practice: use the `status_url` / `response_url` strings returned by submit, verbatim.** Only reconstruct a URL when resuming from a bare `request_id`. (`workflows/` and `comfy/` are namespace prefixes and keep three segments.)

Status values: `IN_QUEUE` → `IN_PROGRESS` → `COMPLETED`. There is **no terminal `FAILED`** — errors surface when you fetch the result, so always read the result body rather than trusting status alone.

### Passing input images
```python
url = fal_client.upload_file("frame.png")     # -> https://v3b.fal.media/files/b/...
```
```ts
const url = await fal.storage.upload(file);
```
Any public URL works. Base64 data URIs work for small images but fal warns off anything beyond a few KB — **never data-URI a video**.

---

## 3. Keyframe interpolation (first frame → last frame)

This is the technique that powers scroll-scrubbed transitions. **Parameter names are not consistent across models** — this is the single most common source of silent failures.

| Model | First frame param | Last frame param |
|---|---|---|
| `fal-ai/kling-video/o1/image-to-video` — **purpose-built for this** | `start_image_url` | `end_image_url` |
| `fal-ai/wan-flf2v` — both required | `start_image_url` | `end_image_url` |
| `bytedance/seedance-2.5/image-to-video` | `image_url` | `end_image_url` |
| `bytedance/seedance-2.0/image-to-video` | `image_url` | `end_image_url` |
| `fal-ai/kling-video/v3/pro/image-to-video` | `start_image_url` | `end_image_url` |
| `fal-ai/kling-video/o3/pro/image-to-video` | `image_url` | `end_image_url` |
| `fal-ai/kling-video/v2.1/pro/image-to-video` | `image_url` | `tail_image_url` |
| `fal-ai/vidu/start-end-to-video` | `start_image_url` | `end_image_url` |
| `fal-ai/pixverse/v6/transition` | `first_image_url` | `end_image_url` |

**Default to Kling O1** — it is the model designed for start/end interpolation. It requires you to cite the frames in the prompt as `@Image1` (start) and `@Image2` (end), and `prompt` is required. Duration 3–10s, images ≤10 MB and ≥300px, aspect ratio 0.40–2.50.

**No last-frame support** (don't try): Veo 3.1 image-to-video, Wan 2.5 preview, Happy Horse, PixVerse v6 `image-to-video` (use `/transition` instead).

`fal-ai/wan-flf2v` is Wan **2.1**. There is no Wan 2.2 FLF2V on fal — `fal-ai/wan/v2.2-a14b/flf2v` returns 404.

---

## 4. Model landscape

**Slug namespaces are inconsistent.** Newer partner models drop the `fal-ai/` prefix (`bytedance/`, `alibaba/`, `minimax/`, `google/`, `xai/`, `veed/`, `bria/`), but `fal-ai/bria/background/remove` and `fal-ai/topaz/...` break even that rule. **Never infer a slug — read it off the model page.** Trap: legacy Seedance 1.0 is `fal-ai/bytedance/seedance/...` while 2.x is `bytedance/seedance-2.x/...`.

### Image-to-video (the usual entry point for design work)

| Slug | Price | Max duration |
|---|---|---|
| `bytedance/seedance-2.5/image-to-video` | ~$0.473/s @720p | 30s |
| `bytedance/seedance-2.0/image-to-video` | ~$0.303/s @720p | 15s |
| `fal-ai/kling-video/v3/pro/image-to-video` | $0.112/s no-audio | 3–15s |
| `fal-ai/kling-video/o3/pro/image-to-video` | $0.112/s | 3–15s |
| `alibaba/happy-horse/image-to-video` | $0.14/s @720p | 3–15s |
| `fal-ai/veo3.1/fast/image-to-video` | $0.10/s | 4/6/8s |
| `fal-ai/pixverse/v6/image-to-video` | $0.06/s | 1–15s |

### Text-to-video

| Slug | Price | Max | Notes |
|---|---|---|---|
| `bytedance/seedance-2.5/text-to-video` | ~$0.473/s @720p | 30s | longest single-pass take |
| `fal-ai/wan/v2.7/text-to-video` | $0.10/s @720p | 15s | good value |
| `fal-ai/ltx-2.3/text-to-video` | $0.08/s @1080p | 10s | **24/25/48/50 fps** options |
| `minimax/h3/text-to-video` | ~$0.08/s | 15s | 480p–4K (upscaled above 1080p) |
| `fal-ai/pixverse/v6/text-to-video` | $0.06/s @720p | 15s | cheapest usable |
| `xai/grok-imagine-video/text-to-video` | $0.05/s @480p | 6s | cheap drafts |

### Picking one

- **Physical realism / temporal consistency** (fal publishes no benchmark, so this is directional): **Happy Horse 1.0** leads Artificial Analysis without-audio; **Seedance 2.0** tops image-to-video; **Seedance 2.5** has the longest coherent take; **Kling O3 Pro** for identity persistence across shots; **Veo 3.1** for colour science and 4K rather than physics.
- **Draft cheap, finish expensive.** Iterate the prompt on PixVerse or Grok at $0.05–0.06/s, then run the keeper once on Seedance or Kling. Same logic as the critic loop: cheap model does the grunt work.
- **Seedance 2.5 specifics:** native 30s single pass (no stitching), 24fps, aspect ratios `auto,21:9,16:9,4:3,1:1,3:4,9:16`. Native audio is on by default and **free** — unusual, most models surcharge audio. Billed by tokens at $0.0214/1k, so wider aspect ratios cost more per second.
  ⚠️ Its API schema lists 1080p but fal's own explainer says 720p is the ceiling and only prices 480p/720p. **Test before relying on 1080p.**

**Pricing is per second of output** for nearly everything. Exceptions: Seedance 2.x is token-billed, Hailuo 2.3 Pro is per-generation, `wan-flf2v` uses billing units. Get authoritative numbers from the API, not scraped pages (several render price client-side):
```bash
curl -H "Authorization: Key $FAL_KEY" \
  "https://api.fal.ai/v1/models/pricing?endpoint_id=bytedance/seedance-2.5/image-to-video"
```

---

## 5. Background removal — the alpha channel decides everything

This is the step that makes a generated clip layer into a UI instead of reading as a video.

> **Every MP4 path silently composites transparent regions to black.** Only **VP9/WebM**, **ProRes4444/MOV**, and VEED's dual-H264 trick carry an alpha channel. If your matted clip has a black box around it, this is why.

| Slug | Output | Price |
|---|---|---|
| `fal-ai/birefnet/v2/video` | VP9 / ProRes4444 / X264 / GIF. **`output_mask: true` returns a separate matte video** — the only endpoint that does | **free** (compute-sec) |
| `fal-ai/ben/v2/video` | WebM VP9 alpha (MP4 has none) | $0.001/megapixel (w×h×frames) |
| `veed/video-background-removal` | VP9 alpha or dual H264 | $0.0225/30 frames |
| `veed/video-background-removal/fast` | same | $0.012/30 frames |
| `veed/video-background-removal/green-screen` | chroma-key + spill suppression | $0.025/30 frames |
| `pixelcut/video-background-removal` | webm_vp9 default | $0.022/30 frames |
| `bria/video/background-removal/v3` | most format options, `preserve_audio` | $0.05/s |
| `fal-ai/sam2/video` | promptable segmentation | free |

**Start with `fal-ai/birefnet/v2/video`** — it's free, outputs real alpha, and can hand back a separate matte you can composite yourself.

❌ `fal-ai/video-background-removal` does not exist (404).

**Image background removal** (for stills feeding the pipeline): `fal-ai/birefnet/v2` (free, has a matting mode), `fal-ai/imageutils/rembg` (free), `fal-ai/evf-sam` (**text-prompted** — "the crystal"; $0.005), `fal-ai/bria/background/remove` ($0.018, commercially-clean weights).

**Also useful:** `fal-ai/topaz/upscale/video`, `fal-ai/seedvr/upscale/video` (temporally consistent), `fal-ai/rife/video` (frame interpolation — cheaper than regenerating at higher fps).

---

## 6. The two design workflows

### A. Animated graphic that layers into the UI

The article's crystal example. The ordering matters and is counter-intuitive:

1. **Render the clip over the page's actual background colours.** Not over green, not over transparent. For glass, chrome, water or anything refractive, this bakes correct refraction, caustics and cast shadows into the frames — you cannot add them afterwards.
2. **Matte out the background** with `fal-ai/birefnet/v2/video`, output VP9/WebM so alpha survives.
3. **Layer it** in the UI over the same background it was rendered against. The refraction now reads as genuine.

For a non-refractive subject, rendering on a flat key colour and using `veed/video-background-removal/green-screen` is cheaper and cleaner.

4. **Loop it.** Ask for a seamless loop in the prompt, and verify — if the last frame doesn't meet the first, run a short `fal-ai/kling-video/o1/image-to-video` interpolation from last frame back to first and concatenate.

### B. Scroll-scrubbed state transitions

Underused and very effective. Chain of keyframes, each transition a separate clip:

1. Generate **state 1** as a still (image gen — Technique 4).
2. Interpolate **state 1 → state 2** with a first/last-frame model (Kling O1). If you only have state 1, generate the clip forward and grab its final frame as state 2.
3. **Seed the next transition from the previous clip's final frame** — this is what keeps the chain visually continuous. Extract it: `ffmpeg -sseof -0.1 -i clip1.mp4 -update 1 -q:v 2 last.png`
4. Repeat for each transition.
5. In the page, **scrub the video timeline against scroll position** rather than playing it. Preload; decode-on-scrub is janky if the file isn't buffered.

Keep clips short (3–6s). Scrubbing a 30s clip means downloading 30s of video before the interaction feels right.

---

## 7. Gotchas

- **Output files expire.** No published TTL — fal says "configurable". **Download every asset you intend to keep**, immediately. Per-request control:
  ```bash
  -H 'X-Fal-Object-Lifecycle-Preference: {"expiration_duration_seconds": 3600}'
  ```
- **Don't hardcode the CDN host.** Both `v3.fal.media` and `v3b.fal.media` are in play — read the URL from the response. Legacy `fal.media` is disabled. **Output files are public by default.**
- **Request payloads are retained 30 days** in dashboard history. Opt out with `X-Fal-Store-IO: 0`.
- **You are not charged** for 5xx errors, queue time, or cold starts. You *can* be charged for client errors once GPU work has started.
- Useful headers: `X-Fal-No-Retry: 1`, `x-fal-queue-priority: low|normal`, `x-fal-request-timeout: <sec>`.
- Known bug ([fal#939](https://github.com/fal-ai/fal/issues/939)): revoking a key does not release its in-progress concurrency slots.

---

## Verifying before you build

Slugs, prices and parameter names in this file were correct on 2 Sep 2026 and **will drift**. Before writing pipeline code:

1. Open `https://fal.ai/models/<slug>/api` and read the actual input schema — especially the first/last frame parameter names.
2. Confirm price via the pricing API call above, not a scraped page.
3. Run one cheap clip end-to-end before wiring anything into the design.

Flagged as unverified at time of writing: fal publishes no generation-time figures for video models (don't promise the user a duration); the absence of spend caps is inferred from docs describing only prepaid credits; Seedance 2.5's 1080p support is contradicted between its schema and fal's own explainer.
