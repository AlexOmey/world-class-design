#!/bin/sh
# world-class-design — capability preflight
#
# Reports which parts of the pipeline can run in this environment.
# Read-only: probes and prints, never installs or writes. Safe to re-run.
#
#   sh scripts/preflight.sh              # local probes only, no network
#   sh scripts/preflight.sh --verify     # also spends $0 to confirm the fal key works
#
# Exit codes:
#   0  ready — Discover, Define and Deliver all runnable
#   10 degraded — core works, some enrichment unavailable (image and/or video)
#   20 blocked — a core dependency is missing
#
# Output lines are stable and greppable: "OK ", "GAP ", "-- " (optional, absent).

VERIFY=0
[ "$1" = "--verify" ] && VERIFY=1

gaps_core=0
gaps_img=0
gaps_vid=0
gaps_opt=0

ok()   { printf 'OK   %-12s %s\n' "$1" "$2"; }
gap()  { printf 'GAP  %-12s %s\n' "$1" "$2"; }
note() { printf '%-4s %-12s %s\n' '--' "$1" "$2"; }   # '--' must not lead the format string

# Read a KEY=value from a dotenv-style file without sourcing it.
read_env_key() {
  # $1 = key name, $2 = file
  [ -f "$2" ] || return 1
  sed -n "s/^[[:space:]]*$1[[:space:]]*=[[:space:]]*//p" "$2" | tail -n1 | tr -d '"'\''' | tr -d '\r'
}

find_key() {
  # $1 = env var name. Echoes "source" on success.
  _name="$1"
  _v=$(eval "printf '%s' \"\${$_name:-}\"")       # POSIX indirect read; ${!v} is a bashism
  if [ -n "$_v" ]; then echo "environment"; return 0; fi
  for _f in ./.env.agents "$HOME/.config/fal/env" ./.env; do
    _v=$(read_env_key "$_name" "$_f" 2>/dev/null)
    if [ -n "$_v" ]; then echo "$_f"; return 0; fi
  done
  return 1
}

echo "world-class-design — preflight"
echo "------------------------------"

# ---------- core ----------
if command -v curl >/dev/null 2>&1; then
  ok "curl" "$(command -v curl)"
else
  gap "curl" "required for every API call — install curl"
  gaps_core=$((gaps_core+1))
fi

if [ -d .git ] || git rev-parse --git-dir >/dev/null 2>&1; then
  ok "git" "inside a repo — secrets must stay gitignored"
else
  note "git" "not a git repo (fine; no .gitignore protection needed)"
fi

# ---------- image generation (technique 4) ----------
img_route=""
if command -v codex >/dev/null 2>&1; then
  img_route="codex CLI ($(command -v codex))"
elif src=$(find_key OPENAI_API_KEY); then
  img_route="OPENAI_API_KEY from $src"
elif src=$(find_key GEMINI_API_KEY); then
  img_route="GEMINI_API_KEY from $src"
elif src=$(find_key GOOGLE_API_KEY); then
  img_route="GOOGLE_API_KEY from $src"
fi

if [ -n "$img_route" ]; then
  ok "image-gen" "$img_route"
else
  gap "image-gen" "no route — technique 4 unavailable. See SKILL.md 'Technique 4'."
  gaps_img=1
fi

# ---------- video generation (technique 5) ----------
if fal_src=$(find_key FAL_KEY); then
  ok "fal-key" "found in $fal_src"

  if [ "$VERIFY" = "1" ]; then
    if [ "$fal_src" = "environment" ]; then
      FALK=$(eval 'printf "%s" "${FAL_KEY:-}"')
    else
      FALK=$(read_env_key FAL_KEY "$fal_src")
    fi
    code=$(curl -s -o /dev/null -w '%{http_code}' -X POST https://fal.run/fal-ai/imageutils/rembg \
      -H "Authorization: Key $FALK" -H "Content-Type: application/json" \
      -d '{"image_url":"https://picsum.photos/id/237/200/200.jpg"}' 2>/dev/null)
    case "$code" in
      200) ok "fal-auth" "verified with a free call (HTTP 200)" ;;
      401) gap "fal-auth" "HTTP 401 — key is wrong or revoked. Reissue at https://fal.ai/dashboard/keys"
           gaps_vid=1 ;;
      403) gap "fal-auth" "HTTP 403 on a model call — unexpected; check the key's scope is API"
           gaps_vid=1 ;;
      "")  note "fal-auth" "no response — offline? skipping verification" ;;
      *)   note "fal-auth" "HTTP $code — inconclusive, try a manual call" ;;
    esac
  else
    note "fal-auth" "not verified (re-run with --verify to confirm, costs \$0)"
  fi
else
  gap "fal-key" "not configured — technique 5 unavailable. See references/fal-video.md section 1."
  gaps_vid=1
fi

# ---------- helpers ----------
if command -v ffmpeg >/dev/null 2>&1; then
  ok "ffmpeg" "$(command -v ffmpeg)"
else
  gap "ffmpeg" "needed to extract seed frames for scroll transitions — brew install ffmpeg"
  gaps_opt=$((gaps_opt+1))
fi

command -v jq >/dev/null 2>&1 && ok "jq" "$(command -v jq)" \
  || note "jq" "absent — queue polling is easier with it (brew install jq)"

# ---------- secret hygiene ----------
if [ -f .env.agents ]; then
  if git rev-parse --git-dir >/dev/null 2>&1; then
    if git check-ignore -q .env.agents 2>/dev/null; then
      ok "gitignore" ".env.agents is ignored"
    else
      gap "gitignore" ".env.agents is NOT ignored — add it before committing anything"
      gaps_core=$((gaps_core+1))
    fi
  fi
  perms=$(stat -f '%Lp' .env.agents 2>/dev/null || stat -c '%a' .env.agents 2>/dev/null)
  [ "$perms" = "600" ] || note "perms" ".env.agents is mode $perms — chmod 600 recommended"
fi

if [ -f "$HOME/.config/fal/env" ]; then
  perms=$(stat -f '%Lp' "$HOME/.config/fal/env" 2>/dev/null || stat -c '%a' "$HOME/.config/fal/env" 2>/dev/null)
  [ "$perms" = "600" ] || note "perms" "~/.config/fal/env is mode $perms — chmod 600 recommended"
fi

# A key in an app env file is only a leak if the APP doesn't use it. Plenty of
# products legitimately call OpenAI or Gemini at runtime — never block those.
app_uses_var() {
  _v="$1"
  if git rev-parse --git-dir >/dev/null 2>&1 &&
     git grep -qI "$_v" -- ':!*.env*' ':!*.md' 2>/dev/null; then
    return 0
  fi
  grep -rqI --exclude-dir=node_modules --exclude-dir=.next --exclude-dir=.git \
    --exclude='.env*' --exclude='*.md' "$_v" . 2>/dev/null
}

for f in .env .env.local .env.production .env.development; do
  [ -f "$f" ] || continue
  for k in FAL_KEY OPENAI_API_KEY GEMINI_API_KEY; do
    grep -qE "^[[:space:]]*$k[[:space:]]*=" "$f" 2>/dev/null || continue
    if app_uses_var "$k"; then
      note "app-key" "$k in $f is referenced by your source — an app key, correct where it is"
    else
      gap "stray-key" "$k is in $f but nothing in your source reads it."
      printf '                  If you put it there for the design agent, move it: app env files\n'
      printf '                  ship to production via vercel env push and hosting dashboards.\n'
      gaps_opt=$((gaps_opt+1))
    fi
  done
done

echo "------------------------------"

# ---------- verdict ----------
if [ "$gaps_core" -gt 0 ]; then
  echo "BLOCKED: fix the core gaps above before running the pipeline."
  exit 20
fi

if [ "$gaps_img" -gt 0 ] || [ "$gaps_vid" -gt 0 ] || [ "$gaps_opt" -gt 0 ]; then
  echo "DEGRADED: Discover + Define(critic) + Deliver will run."
  [ "$gaps_img" -gt 0 ] && echo "  - technique 4 (image generation) unavailable"
  [ "$gaps_vid" -gt 0 ] && echo "  - technique 5 (video generation) unavailable"
  [ "$gaps_opt" -gt 0 ] && echo "  - some helpers missing (see GAP lines)"
  echo "  Offer to set these up; do not silently substitute CSS gradients for real assets."
  exit 10
fi

echo "READY: all eight techniques available."
exit 0
