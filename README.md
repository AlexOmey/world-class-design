# world-class-design

A Claude Code skill for getting distinctive, non-generic design out of AI coding agents.

Left alone, an LLM returns the centre of its training distribution — purple gradient, text left, graphic right, eyebrow label above every heading. This skill is a process for pushing the model off that centre and then pulling it back to something shippable.

Adapted from [How to turn your AI into a world-class designer](https://www.lennysnewsletter.com/p/how-to-turn-your-ai-into-a-world) by **Anshu Chimala** (ex-Apple AI R&D), Lenny's Newsletter, 1 September 2026. The three-stage structure and the eight techniques are his; this repo turns them into an executable skill with preflight checks, agent-side instructions, and a worked fal.ai reference.

## Install

```bash
git clone <this-repo> ~/.claude/skills/world-class-design
```

Then invoke it in Claude Code with `/world-class-design`, or just describe the problem — it triggers on things like "this looks like AI slop" or "why does my design look generic".

Works in any agent that reads `SKILL.md`-style skills; the preflight script is plain POSIX `sh`.

## First run

```bash
sh scripts/preflight.sh --verify
```

Reports what's available and exits `0` ready / `10` degraded / `20` blocked. Nothing is required beyond `curl` — image and video generation are enrichments, and the skill degrades honestly without them rather than substituting gradients.

## The process

| Stage | Goal | Techniques |
|---|---|---|
| **Discover** | Escape the default. Go broad. | 1. Seed strings · 2. Ambitious briefs |
| **Define** | Give it an identity. Go deep. | 3. Critic loop · 4. Image gen · 5. Video gen |
| **Deliver** | Make it shippable. Cut back. | 6. Subtract · 7. Kill AI tells · 8. Rewrite copy |

The two that carry most of the weight:

- **Seed strings (1).** Asking a model to "be random" doesn't work — it predicts tokens that *sound* random. Real entropy from `/dev/urandom`, interpreted as creative direction, produces genuinely different output every run.
- **The critic loop (3).** A building agent can't judge its own work; it sees its code and its reasoning, not the page. A separate subagent on a bigger model, given *only a screenshot* in a fresh context, scores it out of 10. Cheap model builds, expensive model judges — in the source's runs the critic was under 10% of output tokens.

**The user's taste is the input that makes this work.** Techniques 2, 6 and 8 are explicit checkpoints where the skill stops and asks. Pasting AI-generated ideas back into AI produces something anyone could have produced.

## Layout

```
SKILL.md                      the process, checkpoints, and degradation rules
scripts/preflight.sh          capability probe — read-only, POSIX sh
references/prompt-library.md  verbatim prompts for all eight techniques
references/ai-tells.md        overused-pattern → better-alternative checklist
references/fal-video.md       fal.ai setup, API, model slugs, both video pipelines
```

## A note on the fal.ai reference

`references/fal-video.md` was verified against fal's own model pages on **2 September 2026**. Model slugs, prices and parameter names move fast, and fal's namespace is inconsistent (newer partner models drop the `fal-ai/` prefix). The file ends with a "verify before you build" section and flags what could not be confirmed. Re-check the model page before writing pipeline code.

Three things in there that cost real time to discover:

- fal's own queue documentation is **wrong** about URL construction — submit takes the full model slug, status/result take only `owner/alias`.
- Every MP4 output path silently composites transparency to black. Only VP9/WebM and ProRes4444 carry alpha.
- **fal has no spend caps.** No per-key or per-account budget limit exists. The only real control is loading a small amount of prepaid credit.

## Credits

Process and techniques: [Anshu Chimala](https://substack.com/@anshuc). Skill implementation and fal.ai reference: this repo.
