#!/usr/bin/env bash
# Tests for claude/hooks/pm-config.jq, the filter bin/pm uses to merge, validate and clamp .claude-pm.json files.
# Resolve the checkout before sourcing the helper: bin/dotfiles exports DOTFILES=~/.dotfiles when sourced.
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
FILTER="$REPO/claude/hooks/pm-config.jq"
FIX="$REPO/test/fixtures/pm"
readonly REPO FILTER FIX

source "$DOTFILES/test/helper.sh"

if [[ ! -f "$FILTER" ]]; then
  echo "ERROR: $FILTER is missing" >&2
  exit 1
fi
if [[ ! "$(type -P jq)" ]]; then
  echo "ERROR: jq is required" >&2
  exit 1
fi

e_header "$(basename "$0" .sh)"

# Fixtures are never named .claude-pm.json in the checkout; each case copies the ones it needs into a temp tree
# under the real name. The root is canonicalised, as the guard hands the filter canonical paths.
root="$(cd -P "$(mktemp -d)" && pwd -P)"
trap 'rm -rf "$root"' EXIT

ORIGIN=github.com/example-client/x
FORGEJO_ORIGIN=forgejo.example.com/example-client/x

# lay <dir> <fixture>: copy test/fixtures/pm/<fixture>.json to <dir>/.claude-pm.json.
function lay() { mkdir -p "$1" && cp "$FIX/$2.json" "$1/.claude-pm.json"; }

# pm <level> <origin> <origin_kind> <guard_files json> [file...]: the one call form bin/pm uses.
function pm() {
  jq -n --arg level "$1" --arg origin "$2" --arg origin_kind "$3" --argjson guard_files "$4" \
    -f "$FILTER" "${@:5}" </dev/null
}

# norm: the root is random, so replace it in every string; -S makes key order irrelevant.
function norm() {
  jq -S --arg root "$root" 'walk(if type == "string" then split($root) | join("<root>") else . end)'
}

# field <jq expression>: one value of the output, root-normalised, compact.
function field() { norm | jq -c "$1"; }

# golden <case> <level> <origin> <origin_kind> <guard_files json> [file...]: output equals expected-<case>.json.
function golden() {
  local name="$1"
  shift
  assert "$(pm "$@" | norm)" "$(jq -S . "$FIX/expected-$name.json")" "golden: $name"
}

# fails <label> <expected stderr fragment> <level> <origin> <origin_kind> <guard_files json> [file...]:
# exits non-zero (jq's 5 for error()) and the message holds the fragment.
function fails() {
  local label="$1" frag="$2" err rc
  shift 2
  err="$(pm "$@" 2>&1 >/dev/null)"
  rc=$?
  assert "$rc" "5" "$label: exits 5"
  assert "$([[ "$err" == *"$frag"* ]] && echo ok || echo "stderr was: $err")" "ok" "$label: stderr holds '$frag'"
}

# --- no files, and each level's defaults ---
golden nofiles-none "" "" none '[]'
golden nofiles-github personal "$ORIGIN" github '[]'
golden customer-defaults customer "$ORIGIN" github '[]'
assert "$(pm company "$ORIGIN" github '[]' | jq -c .tiers)" \
  '{"issue_create":"auto","label":"auto","comment":"auto","close":"auto","release_notes":"auto"}' "company defaults match personal"

# --- the merge ---
lay "$root/merge/a" far
lay "$root/merge/a/b" near
golden merge personal "$ORIGIN" github '[]' "$root/merge/a/.claude-pm.json" "$root/merge/a/b/.claude-pm.json"

# a nearer tracker replaces the farther one whole, so a Jira tracker never keeps a GitHub repo
lay "$root/replace/a" trk-github-repo
lay "$root/replace/a/b" trk-jira
golden replace personal "$ORIGIN" github '[]' "$root/replace/a/.claude-pm.json" "$root/replace/a/b/.claude-pm.json"
# and a kind-only nearer tracker takes the origin, not the farther file's repo
lay "$root/kindonly/a" trk-github-repo
lay "$root/kindonly/a/b" trk-github-kind
golden kindonly personal "$ORIGIN" github '[]' "$root/kindonly/a/.claude-pm.json" "$root/kindonly/a/b/.claude-pm.json"
# a farther Jira repo does not leak into a nearer kind-less-repo Jira tracker
lay "$root/jirajira/a" trk-jira
lay "$root/jirajira/a/b" trk-jira-norepo
assert "$(pm personal "$ORIGIN" github '[]' "$root/jirajira/a/.claude-pm.json" "$root/jirajira/a/b/.claude-pm.json" | jq -c .tracker)" \
  '{"kind":"jira","repo":""}' "a nearer repo-less Jira tracker replaces, not merges"

# the order of the arguments is the order of precedence
assert "$(pm personal "$ORIGIN" github '[]' "$root/merge/a/b/.claude-pm.json" "$root/merge/a/.claude-pm.json" | jq -c '[.tiers.label, .limits.footer, .roadmap.status]')" \
  '["suggest","far footer","labels"]' "swapping the arguments swaps the winner"

# --- follow_ups ---
lay "$root/fu1/a" far
lay "$root/fu1/a/b" fu-backlog-only
assert "$(pm personal "$ORIGIN" github '[]' "$root/fu1/a/.claude-pm.json" "$root/fu1/a/b/.claude-pm.json" | field .follow_ups)" \
  '{"backlog":"<root>/fu1/a/b/only-backlog.md","in_flight":"<root>/fu1/a/far-flight.md"}' "follow_ups objects deep-merge, each path against its own file"
lay "$root/fu2/a" far
lay "$root/fu2/a/b" fu-string
assert "$(pm personal "$ORIGIN" github '[]' "$root/fu2/a/.claude-pm.json" "$root/fu2/a/b/.claude-pm.json" | field .follow_ups)" \
  '"<root>/fu2/a/b/notes/follow-ups.md"' "a nearer string replaces a farther object"
lay "$root/fu3/a" fu-string
lay "$root/fu3/a/b" fu-backlog-only
assert "$(pm personal "$ORIGIN" github '[]' "$root/fu3/a/.claude-pm.json" "$root/fu3/a/b/.claude-pm.json" | field .follow_ups)" \
  '{"backlog":"<root>/fu3/a/b/only-backlog.md"}' "a nearer object replaces a farther string"
lay "$root/fu4/a/b" fu-object
assert "$(pm personal "$ORIGIN" github '[]' "$root/fu4/a/b/.claude-pm.json" | field .follow_ups)" \
  '{"backlog":"<root>/fu4/a/b.md","in_flight":"<root>/fu4/a/b/c/f.md"}' "relative follow_ups resolve against their own directory, dots collapsed"
lay "$root/fu5" fu-abs
assert "$(pm personal "$ORIGIN" github '[]' "$root/fu5/.claude-pm.json" | field .follow_ups)" \
  '{"backlog":"/abs/backlog.md"}' "an absolute follow_ups path is kept"
lay "$root/fu6" empty-object
assert "$(pm personal "$ORIGIN" github '[]' "$root/fu6/.claude-pm.json" | jq -c 'has("follow_ups")')" "false" "follow_ups is absent when no file sets it"
assert "$(pm personal "$ORIGIN" github '[]' "$root/fu6/.claude-pm.json" | jq -c 'has("notes")')" "false" "notes is absent when no file sets it"
lay "$root/fu7" fu-object
assert "$(pm personal "$ORIGIN" github '[]' "$root/fu7/.claude-pm.json" | field .follow_ups.backlog)" '"<root>/b.md"' ".. above the root stops at the root"

# --- tier ceilings ---
lay "$root/cc/a" tiers-all-auto
golden customer-ceiling-github customer "$ORIGIN" github "[\"$root/cc/a/.claude-pm.json\"]" "$root/cc/a/.claude-pm.json"
lay "$root/ccf/a" tiers-all-auto
golden customer-ceiling-forgejo customer "$FORGEJO_ORIGIN" forgejo "[\"$root/ccf/a/.claude-pm.json\"]" "$root/ccf/a/.claude-pm.json"
lay "$root/ccj/a" cust-jira
golden customer-ceiling-jira customer "$ORIGIN" github "[\"$root/ccj/a/.claude-pm.json\"]" "$root/ccj/a/.claude-pm.json"
# a value below both the default and the ceiling is kept, not raised
lay "$root/low/a" cust-low
golden customer-low customer "$ORIGIN" github "[\"$root/low/a/.claude-pm.json\"]" "$root/low/a/.claude-pm.json"
# the tracker-kind ceiling at personal level
lay "$root/pj/a" personal-jira
golden personal-jira personal "$ORIGIN" github '[]' "$root/pj/a/.claude-pm.json"
# with level empty there is no level ceiling, so an asked auto stays
lay "$root/nolevel/a" tiers-all-auto
golden nolevel "" "$ORIGIN" github '[]' "$root/nolevel/a/.claude-pm.json"
# a company file asking for auto on a code host is not clamped
assert "$(pm company "$ORIGIN" github '[]' "$root/nolevel/a/.claude-pm.json" | jq -c '[.tiers.close, .adjustments]')" '["auto",[]]' "company is not clamped on a code host"

# with level empty neither ceiling applies, the tracker-kind one included
lay "$root/nl-jira" personal-jira
assert "$(pm "" "$ORIGIN" github '[]' "$root/nl-jira/.claude-pm.json" | jq -c '[.tracker.kind, .tiers.label, .tiers.comment, .tiers.issue_create, .adjustments]')" \
  '["jira","auto","suggest","auto",[]]' "level empty: a jira tracker does not cap tiers"
mkdir -p "$root/nl-none"
cat > "$root/nl-none/.claude-pm.json" <<'JSON'
{"tracker":{"kind":"none"},"tiers":{"label":"auto"}}
JSON
assert "$(pm "" "$ORIGIN" github '[]' "$root/nl-none/.claude-pm.json" | jq -c '[.tracker.kind, .tiers.label, .tiers.close, .adjustments]')" \
  '["none","auto","auto",[]]' "level empty: a none tracker does not cap tiers"
# company level on a non-code-host tracker: every tier capped at draft, reason is the tracker kind
cat > "$root/nl-jira/.claude-pm.json" <<'JSON'
{"tracker":{"kind":"jira","repo":"ACME"},"tiers":{"issue_create":"auto","label":"auto","comment":"auto","close":"auto","release_notes":"auto"}}
JSON
assert "$(pm company "$ORIGIN" github '[]' "$root/nl-jira/.claude-pm.json" | jq -c '[(.tiers | map(.) | unique), .adjustments[0], (.adjustments | length)]')" \
  '[["draft"],"tiers.issue_create: auto -> draft (tracker kind jira)",5]' "company + jira: every tier capped at draft, reason tracker kind jira"

# linear, local and none cap at draft at every level; local drops its repo
for kind in linear local; do
  lay "$root/kind-$kind" "trk-$kind"
  assert "$(pm personal "$ORIGIN" github '[]' "$root/kind-$kind/.claude-pm.json" | jq -c '[.tracker.kind, .tiers.issue_create, .tiers.release_notes]')" \
    "[\"$kind\",\"draft\",\"draft\"]" "tracker kind $kind caps tiers at draft"
done
assert "$(pm personal "$ORIGIN" github '[]' "$root/kind-local/.claude-pm.json" | jq -c .tracker)" '{"kind":"local","repo":""}' "a local tracker's repo is empty"
lay "$root/kind-none" trk-none
assert "$(pm personal "$ORIGIN" github '[]' "$root/kind-none/.claude-pm.json" | jq -c '[.tracker, .tiers.label]')" '[{"kind":"none","repo":""},"draft"]' "an explicit none tracker"
assert "$(pm customer "$ORIGIN" github "[\"$root/kind-linear/.claude-pm.json\"]" "$root/kind-linear/.claude-pm.json" | jq -c '[.tiers.close, .tiers.comment]')" \
  '["off","draft"]' "customer defaults still apply below the non-code-host ceiling"

# --- the customer restriction ---
lay "$root/restrict/a" outside
lay "$root/restrict/a/b" inside
golden restrict customer "$ORIGIN" github "[\"$root/restrict/a/b/.claude-pm.json\"]" "$root/restrict/a/.claude-pm.json" "$root/restrict/a/b/.claude-pm.json"
# below customer level the same file's tier, tracker and limits all count
assert "$(pm personal "$ORIGIN" github "[\"$root/restrict/a/b/.claude-pm.json\"]" "$root/restrict/a/.claude-pm.json" | jq -c '[.tracker.kind, .limits.max_writes_per_run, .vocabulary.labels]')" \
  '["jira",9,["x"]]' "a file outside guard_files counts below customer level"
# an unlisted file's spelling must match exactly: a different spelling of a listed path is outside
assert "$(pm customer "$ORIGIN" github "[\"$root/restrict/a/b/../b/.claude-pm.json\"]" "$root/restrict/a/b/.claude-pm.json" | jq -c .limits.footer)" \
  '"Drafted with Claude"' "guard_files compares paths as spelled"

# --- redact duplicates within one file ---
mkdir -p "$root/redup"
cat > "$root/redup/.claude-pm.json" <<'JSON'
{"redact":["b","a","b","c","a"]}
JSON
assert "$(pm personal "$ORIGIN" github '[]' "$root/redup/.claude-pm.json" | jq -c .redact)" '["b","a","c"]' "redact duplicates in one file collapse, first-seen order"

# --- follow_ups that hold nothing are absent ---
for body in '{"follow_ups":{}}' '{"follow_ups":{"other":"x"}}'; do
  mkdir -p "$root/fue" && printf '%s\n' "$body" > "$root/fue/.claude-pm.json"
  assert "$(pm personal "$ORIGIN" github '[]' "$root/fue/.claude-pm.json" | jq -c 'has("follow_ups")')" "false" "follow_ups $body is absent"
done
assert "$(pm personal "$ORIGIN" github '[]' "$root/fue/.claude-pm.json" | jq -c .warnings)" "[\"$root/fue/.claude-pm.json: unknown key follow_ups.other\"]" "the unknown follow_ups key still warns"

# --- a malformed origin is rejected the same way with or without a tracker file ---
fails "malformed origin, no tracker file" "pm-config: origin gitea/o/r" personal "gitea/o/r" github '[]'
lay "$root/origin-kindonly" trk-github-kind
lay "$root/origin-repo" trk-github-repo
assert "$([[ -f "$root/origin-kindonly/.claude-pm.json" && -f "$root/origin-repo/.claude-pm.json" ]] && echo ok)" "ok" "the origin cases' tracker files exist"
fails "malformed origin, kind-only tracker file" "pm-config: origin gitea/o/r" personal "gitea/o/r" github '[]' "$root/origin-kindonly/.claude-pm.json"
fails "malformed origin, tracker file with its own valid repo" "pm-config: origin gitea/o/r" personal "gitea/o/r" github '[]' "$root/origin-repo/.claude-pm.json"
assert "$(pm personal "gitea/o/r" none '[]' | field .tracker.kind)" '"none"' "an origin is not checked when origin_kind is none"

# --- the tracker default ---
assert "$(pm personal "$ORIGIN" github '[]' | field .tracker)" '{"kind":"github","repo":"github.com/example-client/x"}' "default tracker: github"
assert "$(pm personal gitlab.example.com/example-client/g/x gitlab '[]' | field .tracker)" '{"kind":"gitlab","repo":"gitlab.example.com/example-client/g/x"}' "default tracker: gitlab"
assert "$(pm personal "$FORGEJO_ORIGIN" forgejo '[]' | field .tracker)" '{"kind":"forgejo","repo":"forgejo.example.com/example-client/x"}' "default tracker: forgejo"
assert "$(pm personal "other.example.com/example-client/x" none '[]' | field .tracker)" '{"kind":"none","repo":""}' "default tracker: kind none"
assert "$(pm personal "" github '[]' | field .tracker)" '{"kind":"none","repo":""}' "default tracker: a code-host kind with no origin"
assert "$(pm personal "" none '[]' | field .tracker)" '{"kind":"none","repo":""}' "default tracker: nothing known"
lay "$root/trk-gh" trk-github-kind
assert "$(pm personal "$ORIGIN" github '[]' "$root/trk-gh/.claude-pm.json" | field .tracker)" '{"kind":"github","repo":"github.com/example-client/x"}' "a github tracker without repo takes the origin"
lay "$root/trk-gl" trk-gitlab-kind
assert "$(pm personal gitlab.example.com/example-client/g/x gitlab '[]' "$root/trk-gl/.claude-pm.json" | field .tracker.repo)" '"gitlab.example.com/example-client/g/x"' "a gitlab tracker without repo takes a subgroup origin"
lay "$root/trk-sub" trk-gitlab-subgroups
assert "$(pm personal "" none '[]' "$root/trk-sub/.claude-pm.json" | field .tracker.repo)" '"gitlab.example.com/example-client/group/sub/name"' "a gitlab repo may hold subgroups"
fails "gitlab tracker, github origin" "$root/trk-gl/.claude-pm.json" personal "$ORIGIN" github '[]' "$root/trk-gl/.claude-pm.json"
fails "github tracker, no origin" "tracker.repo is required" personal "" none '[]' "$root/trk-gh/.claude-pm.json"
# the error names the nearest file that sets the tracker, not a farther one
lay "$root/near-err/a" trk-github-repo
lay "$root/near-err/a/b" trk-gitlab-kind
err="$(pm personal "$ORIGIN" github '[]' "$root/near-err/a/.claude-pm.json" "$root/near-err/a/b/.claude-pm.json" 2>&1 >/dev/null)"
assert "$([[ "$err" == *"$root/near-err/a/b/.claude-pm.json: "* ]] && echo ok || echo "stderr was: $err")" "ok" "the tracker error names the nearest file"

# --- roadmap ---
assert "$(pm personal "$ORIGIN" github '[]' | jq -c '[.roadmap.status, .adjustments]')" '["derived",[]]' "roadmap default is derived"
for status in derived labels project; do
  lay "$root/rm-$status" "rm-$status"
  assert "$(pm personal "$ORIGIN" github '[]' "$root/rm-$status/.claude-pm.json" | jq -c '[.roadmap.status, .adjustments]')" "[\"$status\",[]]" "roadmap.status $status on github"
done
lay "$root/rmf/a" rm-project
golden roadmap-forgejo personal "$FORGEJO_ORIGIN" forgejo '[]' "$root/rmf/a/.claude-pm.json"
assert "$(pm personal gitlab.example.com/example-client/x gitlab '[]' "$root/rm-project/.claude-pm.json" | jq -c '[.roadmap.status, .adjustments]')" \
  '["labels",["roadmap.status: project -> labels (no projects on gitlab)"]]' "project resolves to labels on gitlab"
lay "$root/rm-jira" trk-jira
assert "$(pm personal "$ORIGIN" github '[]' "$root/rm-jira/.claude-pm.json" "$root/rm-project/.claude-pm.json" | jq -c '[.roadmap.status, .adjustments]')" \
  '["labels",["roadmap.status: project -> labels (no projects on jira)"]]' "project resolves to labels on jira"
assert "$(pm customer "$ORIGIN" github '[]' "$root/rm-project/.claude-pm.json" | jq -c '[.roadmap.status, .adjustments]')" '["project",[]]' "project is kept on github at customer level too"
assert "$(pm customer "$FORGEJO_ORIGIN" forgejo '[]' "$root/rm-project/.claude-pm.json" | jq -c .roadmap.status)" '"labels"' "project resolves on forgejo at customer level too"
lay "$root/rm-bad" err-roadmap-status
fails "roadmap.status invalid" "roadmap.status" personal "$ORIGIN" github '[]' "$root/rm-bad/.claude-pm.json"

# --- adjustments list only what a file asked for ---
assert "$(pm customer "$ORIGIN" github '[]' | jq -c .adjustments)" '[]' "customer defaults are not adjustments"
assert "$(pm personal "" none '[]' | jq -c .adjustments)" '[]' "defaults capped by a none tracker are not adjustments"

# --- boundaries that are valid ---
lay "$root/boundary" ok-boundary
assert "$(pm personal "$ORIGIN" github '[]' "$root/boundary/.claude-pm.json" | jq -c '[.limits.max_writes_per_run, .schedule, .redact]')" \
  '[0,{"a":"daily 00:00","b":"mon,fri 23:59","c":"weekdays 08:30","d":"sun 12:00"},["x"]]' "zero writes, edge times and listed days are valid"
lay "$root/emptyfile/a" empty
lay "$root/emptyfile/b" near
assert "$(pm personal "$ORIGIN" github '[]' "$root/emptyfile/a/.claude-pm.json" "$root/emptyfile/b/.claude-pm.json" | jq -c .limits.footer)" '"near footer"' "documents the raw filter: an empty file yields no value and is skipped (bin/pm rejects empty files before calling it)"

# --- validation errors name the file ---
errs=(
  "err-array|must hold a JSON object"
  "err-null|must hold a JSON object"
  "err-string|must hold a JSON object"
  "err-two-objects|more than one JSON value"
  "err-tier-yes|tiers.label"
  "err-tier-number|tiers.label"
  "err-tiers-notobj|tiers must be an object"
  "err-schedule-8am|schedule.standup"
  "err-schedule-hour24|schedule.a"
  "err-schedule-minute60|schedule.a"
  "err-schedule-day|schedule.a"
  "err-schedule-trailing|schedule.a"
  "err-schedule-number|schedule.a"
  "err-schedule-notobj|schedule must be an object"
  "err-roadmap-notobj|roadmap must be an object"
  "err-repo-ownername|tracker.repo"
  "err-repo-onesegment|tracker.repo"
  "err-repo-nodot|tracker.repo"
  "err-repo-empty|tracker.repo"
  "err-repo-number|tracker.repo must be a string"
  "err-kind|tracker.kind"
  "err-nokind|tracker.kind"
  "err-tracker-notobj|tracker must be an object"
  "err-limit-negative|limits.max_writes_per_run"
  "err-limit-fraction|limits.max_writes_per_run"
  "err-limit-string|limits.max_writes_per_run"
  "err-footer|limits.footer"
  "err-limits-notobj|limits must be an object"
  "err-redact-empty|redact"
  "err-redact-notarray|redact"
  "err-followups-number|follow_ups"
  "err-followups-empty|follow_ups"
  "err-vocab-number|vocabulary.labels"
  "err-vocab-notarray|vocabulary.priority"
  "err-notes|notes"
  "err-decisions-empty|decisions_dir"
  "unk-bad|tiers.label"
)
for e in "${errs[@]}"; do
  name="${e%%|*}"
  lay "$root/e/$name" "$name"
  fails "$name" "$root/e/$name/.claude-pm.json: " personal "$ORIGIN" github '[]' "$root/e/$name/.claude-pm.json"
  assert "$(pm personal "$ORIGIN" github '[]' "$root/e/$name/.claude-pm.json" 2>&1 >/dev/null | grep -c "${e#*|}")" "1" "$name: names ${e#*|}"
done
# the error names the file that holds the bad value, not a valid one before or after it
lay "$root/which/a" near
lay "$root/which/b" err-tier-yes
lay "$root/which/c" far
err="$(pm personal "$ORIGIN" github '[]' "$root/which/a/.claude-pm.json" "$root/which/b/.claude-pm.json" "$root/which/c/.claude-pm.json" 2>&1 >/dev/null)"
assert "$([[ "$err" == *"$root/which/b/.claude-pm.json: tiers.label"* ]] && echo ok || echo "stderr was: $err")" "ok" "the middle file is the one named"
# a bad value outside guard_files at customer level is still an error: files are validated before they are filtered
fails "invalid value in an unlisted customer file" "tiers.label" customer "$ORIGIN" github '[]' "$root/e/err-tier-yes/.claude-pm.json"

# --- bad arguments ---
fails "bad level" "level must be" bogus "$ORIGIN" github '[]'
fails "bad origin_kind" "origin_kind must be" personal "$ORIGIN" svn '[]'
fails "guard_files not an array" "guard_files" personal "$ORIGIN" github '"x"'
fails "guard_files with a number" "guard_files" personal "$ORIGIN" github '[1]'
cd "$root/e/err-kind" || exit 1
fails "a relative config path" ".claude-pm.json: config file paths must be absolute" personal "$ORIGIN" github '[]' .claude-pm.json
cd "$REPO" || exit 1

# --- unknown keys warn and are dropped ---
lay "$root/unk/a" unk
golden unknown personal "$ORIGIN" github '[]' "$root/unk/a/.claude-pm.json"
assert "$(pm personal "$ORIGIN" github '[]' "$root/merge/a/.claude-pm.json" | jq -c .warnings)" '[]' "warnings is empty when nothing is unknown"
# a dropped unknown key never reaches the merge: a nearer file's typo must not hide the farther file's value
lay "$root/unk2/a" far
lay "$root/unk2/a/b" unk
assert "$(pm personal "$ORIGIN" github '[]' "$root/unk2/a/.claude-pm.json" "$root/unk2/a/b/.claude-pm.json" | jq -c '[.tiers.comment, (.warnings | length)]')" \
  '["draft",7]' "a typo in a nearer file leaves the farther file's value alone and warns once per key"

test_done
