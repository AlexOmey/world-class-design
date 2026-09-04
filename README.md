# world-class-design

A Claude Code skill for getting distinctive, non-generic design out of AI coding agents.

Left alone, an LLM returns the centre of its training distribution — purple gradient, text left, graphic right, eyebrow label above every heading. This skill is a process for pushing the model off that centre and then pulling it back to something shippable.

Adapted from [How to turn your AI into a world-class designer](https://www.lennysnewsletter.com/p/how-to-turn-your-ai-into-a-world) by **Anshu Chimala** (ex-Apple AI R&D), Lenny's Newsletter, 1 September 2026. The three-stage structure and the eight techniques are his; this repo turns them into an executable skill with preflight checks, agent-side instructions, and a worked fal.ai reference.

## What state this is in

**v0.5.0, and honest about it.** This has been run end to end on two real products — a personal site and a live SaaS landing page — across roughly 30 design variants, and every technique has been executed at least once rather than only described. Most of what's here that isn't in the source article came from things going wrong: a video pipeline that looked broken when it worked, a preflight that blocked any project using OpenAI, seed guidance that pointed at the wrong lever entirely.

What that means for you:

- **The findings rest on small samples.** The seed result is 14 runs; the critic plateau is two pages. Directional, not settled.
- **`references/fal-video.md` will rot.** It's a dated snapshot of a fast-moving API, and it says so.
- **It is not a magic button.** Techniques 2, 6 and 8 stop and ask you. A run where nobody exercises taste produces something anyone could have produced.

## Install

This repo is both a plugin and its own marketplace, so it installs in two commands inside Claude Code:

```
/plugin marketplace add AlexOmey/world-class-design
```
```
/plugin install world-class-design@world-class-design
```

Then invoke it with `/world-class-design`, or just describe the problem — it triggers on things like "this looks like AI slop" or "why does my design look generic".

**Working on the skill itself?** Point Claude Code at your checkout instead of installing:

```bash
claude --plugin-dir /path/to/world-class-design
```

### Codex

Codex implements the same [Agent Skills standard](https://agentskills.io), so this repo works there too:

```bash
codex plugin marketplace add AlexOmey/world-class-design
codex plugin add world-class-design@world-class-design
```

The `@marketplace` suffix is required — `codex plugin add <name>` alone errors with *"plugin requires --marketplace"*. Verified working on codex-cli 0.146.0.

Invoke with `$world-class-design`, or let it trigger on its description. Working inside a clone needs nothing at all — the `.agents/skills` symlink makes it auto-discovered. To install it globally without plugin machinery:

```bash
git clone https://github.com/AlexOmey/world-class-design.git
mkdir -p ~/.agents/skills && ln -s "$PWD/world-class-design/skills/world-class-design" ~/.agents/skills/world-class-design
```

Note Codex scans `~/.agents/skills`, **not** `~/.codex/skills`.

### Any other agent

The skill is plain Markdown at `skills/world-class-design/SKILL.md` and works in anything that reads `SKILL.md`-style skills. Copy that directory wherever your tool expects skills to live. The preflight script is POSIX `sh` with no dependencies.

**One substitution to make outside Claude Code:** Technique 3 needs a *fresh context on a bigger model* for the design critic. Claude Code gets that from its subagent tool with a model override; elsewhere, shell out to a clean session (`codex exec …`, `claude -p …`) to get the same isolation. That isolation is the mechanism — without it the critic grades its own work.

## First run

```bash
sh skills/world-class-design/scripts/preflight.sh --verify
```

Reports what's available and exits `0` ready / `10` degraded / `20` blocked. Nothing is required beyond `curl` — image and video generation are enrichments, and the skill degrades honestly without them rather than substituting gradients.

## The process

| Stage | Goal | Techniques |
|---|---|---|
| **Discover** | Escape the default. Go broad. | 1. Seed strings · 2. Ambitious briefs |
| **Define** | Give it an identity. Go deep. | 3. Critic loop · 4. Image gen · 5. Video gen |
| **Deliver** | Make it shippable. Cut back. | 6. Subtract · 7. Kill AI tells · 8. Rewrite copy |

The two that carry most of the weight:

- **Seed strings (1).** Asking a model to "be random" doesn't work — it predicts tokens that *sound* random. Real entropy from `/dev/urandom`, read as creative direction, reliably escapes the default. It does **not** on its own produce structural variety: 14 runs across five seed sources all landed in the same register. The lever is the *derivation instruction* — how you tell the model to read the seed — not the seed itself. The skill documents this at length.
- **The critic loop (3).** A building agent can't judge its own work; it sees its code and its reasoning, not the page. A separate subagent on a bigger model, given *only a screenshot* in a fresh context, scores it out of 10. Cheap model builds, expensive model judges. **Treat the score as triage, not progress** — it plateaued at a flat number across genuine improvement on two different pages. Measure whether the previous findings disappeared instead.

**The user's taste is the input that makes this work.** Techniques 2, 6 and 8 are explicit checkpoints where the skill stops and asks. Pasting AI-generated ideas back into AI produces something anyone could have produced.

## Layout

```
.claude-plugin/                  Claude Code plugin + marketplace manifests
.codex-plugin/plugin.json        Codex plugin manifest
.agents/skills -> ../skills      Codex skill discovery
.agents/plugins/marketplace.json Codex marketplace catalogue
skills/world-class-design/
  SKILL.md                       the process, checkpoints, degradation rules
  scripts/preflight.sh           capability probe — read-only, POSIX sh
  references/prompt-library.md   verbatim prompts for all eight techniques
  references/ai-tells.md         overused-pattern → better-alternative checklist
  references/fal-video.md        fal.ai setup, API, model slugs, video pipelines
```

## A note on the fal.ai reference

> **The fal.ai reference is a dated snapshot.** Model slugs, prices and parameter names in `references/fal-video.md` were correct on **3 September 2026** and will rot. The file flags what it could not confirm and ends with a verification procedure — follow it before writing pipeline code rather than trusting the tables.

It was written from fal's own model pages on 2 September 2026, then **corrected against a real execution the next day** — nine of its claims were wrong, including advice that would have led you to conclude a working video pipeline had failed. fal's namespace is also inconsistent: newer partner models drop the `fal-ai/` prefix.

Three things in there that cost real time to discover:

- fal's own queue documentation is **wrong** about URL construction — submit takes the full model slug, status/result take only `owner/alias`.
- Every MP4 output path silently composites transparency to black. Only VP9/WebM and ProRes4444 carry alpha.
- **fal has no spend caps.** No per-key or per-account budget limit exists. The only real control is loading a small amount of prepaid credit.

## Credits

Process and techniques: [Anshu Chimala](https://substack.com/@anshuc). Skill implementation and fal.ai reference: this repo.

## Editing this skill

**Never write `$` followed by a digit in `SKILL.md`.** The skill loader performs
positional-argument substitution when the skill is invoked with arguments, so
`$0` is replaced by the caller's argument text — `"costs $0"` renders as
`"costs Redesign the landing page"`. Write currency as `USD 0.05` instead.
Environment variables like `$FAL_KEY` are unaffected. Reference files under
`references/` are read as plain files and are not substituted.
