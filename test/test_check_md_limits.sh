#!/usr/bin/env bash
# Resolve the checker before sourcing the helper: bin/dotfiles exports
# DOTFILES=~/.dotfiles when sourced, so afterwards this would test whatever tree
# lives there rather than the one this file was launched from.
CHECKER="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/bin/check-md-limits"
readonly CHECKER

source "$DOTFILES/test/helper.sh"

if [[ ! -x "$CHECKER" ]]; then
  echo "ERROR: $CHECKER is missing or not executable" >&2
  exit 1
fi

e_header "$(basename "$0" .sh)"

# The line-length and file-length cases are mostly regressions: each is a
# violation the checker once missed while exiting 0. Counting is easy to get
# right; not noticing is the failure mode worth guarding, and every guard here
# is one an unterminated fence, comment, ToC or front-matter block once defeated.
# The ratchet and invocation cases cover behaviour rather than past bugs.

LONG_LINE="$(printf 'A%.0s' {1..300})"
readonly LONG_LINE

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT
mkdir -p "$workdir/bin"
cp "$CHECKER" "$workdir/bin/"
git -C "$workdir" init -q .

# Writes a markdown file, then reports what the checker says about it: "clean",
# or the first word of each finding, so a test asserts on outcome not wording.
function check_file() {
  local name="$1" content="$2" output rc
  printf '%s' "$content" > "$workdir/$name"
  git -C "$workdir" add -A >/dev/null 2>&1
  output="$(cd "$workdir" && bin/check-md-limits "$name" 2>&1)" && rc=0 || rc=$?
  # The exit status is the tool's whole contract with hooks/pre-commit and CI:
  # printing an error while exiting 0 would open both gates silently, so every
  # assertion carries it.
  if [[ -z "$output" ]]; then
    echo "clean/$rc"
  else
    echo "$(echo "$output" | grep -oE '^(ERROR|NOTE|SKIP|DROP)' | head -1)/$rc"
  fi
}

function repeat_lines() {
  local count="$1" i
  for (( i = 0; i < count; i++ )); do echo "filler"; done
}

e_header "line length"

assert "$(check_file plain.md "# T

$LONG_LINE
")" "ERROR/1" "a long line is caught"

assert "$(check_file exactly-150.md "# T

$(printf 'B%.0s' {1..150})
")" "clean/0" "a line of exactly 150 characters is allowed"

assert "$(check_file over-by-one.md "# T

$(printf 'B%.0s' {1..151})
")" "ERROR/1" "a line of 151 characters is not"

assert "$(check_file fenced.md "# T

\`\`\`
$LONG_LINE
\`\`\`
")" "clean/0" "a long line inside a closed fence is exempt"

assert "$(check_file unclosed-fence.md "# T

\`\`\`
code
$LONG_LINE
")" "ERROR/1" "an unterminated fence does not exempt the rest of the file"

assert "$(check_file frontmatter.md "---
description: $LONG_LINE
---

body
")" "clean/0" "front matter is exempt from the cap"

assert "$(check_file thematic-break.md "---

Intro after a horizontal rule.
$LONG_LINE
")" "ERROR/1" "a leading --- with no closing --- is a thematic break, not front matter"

assert "$(check_file table.md "# T

| $LONG_LINE |
")" "clean/0" "a table row is shortened rather than wrapped, so it is exempt"

assert "$(check_file url.md "# T

See [x](https://example.com/$LONG_LINE)
")" "clean/0" "a long URL is subtracted from the measured length"

assert "$(check_file url-prose.md "# T

$LONG_LINE [x](https://example.com/y)
")" "ERROR/1" "prose around a short URL is still measured"

assert "$(check_file table-comment.md "# T

| a | <!-- |
$(repeat_lines 30)
| b | --> |
$(repeat_lines 180)")" "ERROR/1" "a marker in a table cell does not pair with a far-off closer"

assert "$(check_file code-span-comment.md "# T

Wrap the block in \`<!--\` first.
$(repeat_lines 15)
Close it with \`-->\`.
$(repeat_lines 190)")" "ERROR/1" "a comment marker inside an inline code span is text, not a comment"

assert "$(check_file fenced-toc.md "# T

\`\`\`
<!-- START doctoc -->
\`\`\`
$(repeat_lines 400)
<!-- END doctoc -->
")" "ERROR/1" "a doctoc marker shown inside a fence does not pair with a real one"

assert "$(check_file yaml-comment.md "---
# a yaml comment
description: $LONG_LINE
---

body
")" "clean/0" "front matter with a YAML comment is still front matter"

assert "$(check_file quoted-key.md "---
\"quoted-key\": $LONG_LINE
---

body
")" "clean/0" "front matter with a quoted key is still front matter"

assert "$(check_file separator.md "---

Intro after a thematic break.
$LONG_LINE

---

more
")" "ERROR/1" "a --- separator further down does not make the opening --- front matter"

assert "$(check_file inline-comment.md "# T

An inline <!-- comment --> sits in this sentence.
$(repeat_lines 400)
<!-- and a later marker --> closes nothing.
")" "ERROR/1" "a comment mentioned mid-sentence does not elide the rest of the file"

assert "$(check_file prose-toc.md "# T

The <!-- START doctoc --> marker opens a table of contents.
$(repeat_lines 400)
The <!-- END doctoc --> marker closes it.
")" "ERROR/1" "doctoc markers named in prose do not pair into a real ToC block"

assert "$(check_file span-toc.md "# T

Use \`<!-- START doctoc -->\` to open.
$(repeat_lines 400)
\`<!-- END doctoc -->\` closes it.
")" "ERROR/1" "doctoc markers inside code spans do not pair either"

assert "$(check_file code-span-lines.md "# T

$(for i in $(seq 1 250); do echo "\`code $i\`"; done)")" "ERROR/1" \
  "lines that are entirely one code span are still content"

# 214 lines: over the cap only because the 30-line span is left counted. Blank
# it wrongly and the file lands at 183, under the cap, and this assertion fails.
assert "$(check_file long-pairing.md "# T

An <!-- opener with no real closer nearby.
$(repeat_lines 30)
A stray --> far below.
$(repeat_lines 180)")" "ERROR/1" \
  "a pairing spanning more than 20 lines is two markers, not a comment"

assert "$(check_file short-pairing.md "# T

<!--
$(repeat_lines 15)
-->
$(repeat_lines 70)")" "clean/0" "a pairing within the 20-line span is a real comment"

# Delimiter-blind pairing makes this (3,4) and (5,7), putting the long line
# inside a fence. Pairing on character and length makes it (3,5), leaving the
# long line in the open where it belongs.
assert "$(check_file mixed-fence.md "# T

\`\`\`
~~~
\`\`\`
$LONG_LINE
\`\`\`
")" "ERROR/1" "a ~~~ inside a backtick fence does not close it"

assert "$(check_file nested-fence.md "# T

\`\`\`\`
\`\`\`
$LONG_LINE
\`\`\`
\`\`\`\`
")" "clean/0" "a three-backtick fence inside a four-backtick one is content"

assert "$(check_file prose-frontmatter.md "---

Note: a document that opens with a horizontal rule.

- $LONG_LINE

---

body
")" "ERROR/1" "a blank line means this is prose between separators, not front matter"

assert "$(check_file listy-frontmatter.md "---
name: x
paths:
  - \"**/*.md\"
description: $LONG_LINE
---

body
")" "clean/0" "front matter with an indented list is still front matter"

assert "$(check_file generated-toc.md "<!-- START doctoc -->
- [$LONG_LINE](#x)
<!-- END doctoc -->

# T

body
")" "clean/0" "a generated ToC line is not reported: nobody can wrap it"

e_header "file length"

assert "$(check_file short.md "# T

$(repeat_lines 20)")" "clean/0" "a short file passes"

assert "$(check_file over-cap.md "# T

$(repeat_lines 250)")" "ERROR/1" "a file over its hard cap fails"

assert "$(check_file unterminated-comment.md "# T
<!-- oops
$(repeat_lines 400)")" "ERROR/1" "an unterminated HTML comment does not exempt the rest of the file"

# 109 lines with the comment counted, 92 without: clean only if it is discounted.
assert "$(check_file commented.md "# T

<!--
$(repeat_lines 15)
-->
$(repeat_lines 90)")" "clean/0" "a closed HTML comment does not count toward the length"

assert "$(check_file unterminated-toc.md "<!-- START doctoc -->
$(repeat_lines 400)")" "ERROR/1" "an unterminated doctoc marker does not elide the rest of the file"

assert "$(check_file badge-gallery.md "# T

$(for _ in {1..400}; do echo '![b](https://example.com/y.svg)'; done)")" "ERROR/1" \
  "a long run of image lines is a gallery, not one badge row"

assert "$(check_file near-cap.md "# T

$(repeat_lines 150)")" "NOTE/0" "a file over its warn line but under its cap is advisory"

# 112 lines with the ToC counted, 92 without.
assert "$(check_file real-toc.md "<!-- START doctoc -->
$(repeat_lines 18)
<!-- END doctoc -->

# T

$(repeat_lines 90)")" "clean/0" "a real doctoc block is still discounted"

# 181 lines, 91 of them non-blank: clean only if blank lines are free.
assert "$(check_file spaced.md "# T
$(for _ in {1..90}; do printf '\n\nfiller'; done)")" "clean/0" "blank lines do not count toward the length"

# 411 lines, 205 of them one-line badge rows: over the cap only if each row counts, not one run of them.
assert "$(check_file badge-rows.md "# T
$(for _ in {1..205}; do printf '\n![b](https://example.com/y.svg)\n'; done)")" "ERROR/1" \
  "a blank line still ends a badge row, so spaced-out badges are not one row"

# 181 lines, 90 of them content: clean only if headings are free.
assert "$(check_file headings.md "# T
$(for _ in {1..90}; do printf '\n## H\nfiller'; done)")" "clean/0" "headings do not count toward the length"

# 252 lines, all but the title shell comments in a fence: a # line there is code, not a heading.
assert "$(check_file fenced-hash.md "# T

\`\`\`
$(for _ in {1..250}; do echo '# x'; done)
\`\`\`
")" "ERROR/1" "a # line inside a fence still counts"

# Fenced code is content: it is exempt from the line cap, never from the length.
assert "$(check_file fenced-count.md "# T

\`\`\`
$(repeat_lines 250)
\`\`\`
")" "ERROR/1" "fenced lines still count toward file length"

e_header "per-type limits"

# A 100-line body is over the cap for every strict type; a skill has room for more.
mkdir -p "$workdir/.claude/rules" "$workdir/claude" "$workdir/skills/x"
assert "$(check_file .claude/rules/r.md "# T

$(repeat_lines 100)")" "ERROR/1" "a rule is capped at 50 lines"
assert "$(check_file CLAUDE.md "# T

$(repeat_lines 100)")" "ERROR/1" "a project CLAUDE.md is capped at 50 lines"
assert "$(check_file claude/CLAUDE.md "# T

$(repeat_lines 100)")" "ERROR/1" "the global CLAUDE.md is capped at 75 lines"
assert "$(check_file skills/x/SKILL.md "# T

$(repeat_lines 120)")" "clean/0" "a skill has no aim, so 120 lines draw no note"
assert "$(check_file skills/x/SKILL.md "# T

$(repeat_lines 100)")" "clean/0" "a skill at 100 counted lines is clean"
assert "$(check_file skills/x/SKILL.md "# T

$(repeat_lines 101)")" "clean/0" "a skill past 100 counted lines draws no note"
assert "$(check_file skills/x/SKILL.md "# T

$(repeat_lines 250)")" "clean/0" "a skill at 250 counted lines is clean"
assert "$(check_file skills/x/SKILL.md "# T

$(repeat_lines 251)")" "ERROR/1" "a skill at 251 counted lines is over the cap"
assert "$(check_file skills/x/SKILL.md "---
name: x
description: d
other: o
---

# T

$(repeat_lines 250)")" "clean/0" "front matter does not count toward a skill's 250"
assert "$(check_file skills/x/SKILL.md "---
name: x
description: d
---

# T

$(repeat_lines 251)")" "ERROR/1" "front matter does not lift a skill's cap either"
assert "$(check_file skills/x/notes.md "# T

$(repeat_lines 100)")" "clean/0" "a non-skill file at 100 lines is clean"
assert "$(check_file skills/x/notes.md "# T

$(repeat_lines 101)")" "NOTE/0" "a non-skill file keeps its aim of 100"
assert "$(check_file skills/x/notes.md "# T

$(repeat_lines 200)")" "NOTE/0" "a non-skill file at 200 lines is still only advisory"
assert "$(check_file skills/x/notes.md "# T

$(repeat_lines 201)")" "ERROR/1" "a non-skill file keeps its cap of 200"
assert "$(check_file .claude/rules/r.md "# T

$(repeat_lines 51)")" "ERROR/1" "a rule keeps its cap of 50"

# A pin on a skill is moot: no aim to pass, so it is ignored and dropped.
printf '10\tskills/x/SKILL.md\n' > "$workdir/.md-baseline"
assert "$(check_file skills/x/SKILL.md "# T

$(repeat_lines 120)")" "clean/0" "a stale pin on a skill does not fail it"
(cd "$workdir" && bin/check-md-limits --update-baseline >/dev/null 2>&1)
assert "$(grep -c 'skills/x/SKILL.md' "$workdir/.md-baseline")" "0" \
  "--update-baseline drops a skill's pin"
rm -f "$workdir/.md-baseline"

# Over its cap, a skill's pin is dropped too, and the cap itself is still reported.
printf '10\tskills/x/SKILL.md\n' > "$workdir/.md-baseline"
printf '# T\n\n%s\n' "$(repeat_lines 251)" > "$workdir/skills/x/SKILL.md"
update_out="$(cd "$workdir" && bin/check-md-limits --update-baseline 2>&1)"
assert "$(grep -c 'skills/x/SKILL.md' "$workdir/.md-baseline")" "0" \
  "--update-baseline drops the pin of a skill over its cap"
assert "$(grep -c '^SKIP' <<<"$update_out")" "1" "a skill over its cap is still reported as SKIP"
assert "$(grep -c '^DROP' <<<"$update_out")" "1" "the dropped skill pin is reported as DROP"
rm -f "$workdir/.md-baseline"

# The rendered/raw split has to work in both directions: what a human-facing page
# gets for free, a Claude-loaded file still pays for.
mkdir -p "$workdir/claude"
# 109 raw lines, 92 once the comment is discounted: advisory as a Claude-loaded
# file, and clean as a human-facing one.
assert "$(check_file claude/notes.md "# T

<!--
$(repeat_lines 15)
-->
$(repeat_lines 90)")" "NOTE/0" "a comment block still counts in a Claude-loaded file"

assert "$(check_file human.md "# T

<!--
$(repeat_lines 15)
-->
$(repeat_lines 90)")" "clean/0" "the same file is clean when it is human-facing"

# 181 raw lines, 91 non-blank, every other one holding only spaces.
assert "$(check_file claude/spaced.md "# T
$(for _ in {1..90}; do printf '\n   \nfiller'; done | sed 1d)")" "clean/0" \
  "blank and whitespace-only lines do not count in a Claude-loaded file either"

assert "$(check_file claude/headings.md "# T
$(for _ in {1..90}; do printf '\n## H\nfiller'; done)")" "clean/0" "headings do not count in a Claude-loaded file either"

# 122 lines of front matter, each a key that would count as body: front matter is
# left out of the length, so a file over its aim only through it is clean.
assert "$(check_file claude/front-matter.md "---
$(for i in {1..120}; do echo "k$i: v"; done)
---
# T")" "clean/0" "a file over its aim only through front matter is not warned about"

assert "$(check_file claude/front-matter-as-body.md "# T
$(for i in {1..120}; do echo "k$i: v"; done)")" "NOTE/0" "the same key: value lines as body still count"

assert "$(check_file front-matter-human.md "---
$(for _ in {1..250}; do echo 'k: v'; done)
---
body")" "clean/0" "front matter does not count toward the hard cap either"

assert "$(check_file claude/unclosed-front-matter.md "---
$(for _ in {1..120}; do echo 'k: v'; done)
")" "NOTE/0" "a lone leading --- with no closer is still counted"

assert "$(check_file claude/thematic-break.md "---

Prose between separators.
$(for _ in {1..120}; do echo 'text'; done)

---
body")" "NOTE/0" "a blank line after the opening --- means it is not front matter, so it counts"

# A blank line inside real front matter (valid YAML) keeps the block front matter
# in both the line-length and the line-count passes.
mkdir -p "$workdir/claude/rules"
fm_blank="---
paths:

  - \"a\"
$(for _ in {1..60}; do echo '  - \"x\"'; done)
---
# T
$(repeat_lines 20)"
assert "$(check_file claude/rules/blank-in-fm.md "$fm_blank")" "clean/0" \
  "a rule whose front matter holds a blank line still counts only its body"
assert "$(check_file blank-in-fm-long.md "---
k: v

$LONG_LINE: x
---
body")" "clean/0" "a long line inside front matter with a blank line is exempt from the cap"
assert "$(check_file blank-in-fm-body.md "---
k: v

---
$LONG_LINE")" "ERROR/1" "a long line after front matter with a blank line is still caught"
assert "$(check_file claude/rules/fm-blank-first.md "---

k: v
$(for _ in {1..60}; do echo 'k: v'; done)
---
# T")" "ERROR/1" "a blank straight after the opening --- is still not front matter"

e_header "skill descriptions"

DESC_300="$(printf 'd%.0s' {1..300})"
assert "$(check_file skills/x/SKILL.md "---
name: x
description: $DESC_300
---

# T
")" "clean/0" "a 300-character description is within the cap"
assert "$(check_file skills/x/SKILL.md "---
name: x
description: ${DESC_300}d
---

# T
")" "ERROR/1" "a 301-character description is over it"
assert "$(check_file skills/x/SKILL.md "---
name: x
description: $(printf 'é%.0s' {1..300})
---

# T
")" "clean/0" "the cap counts characters, not bytes"
assert "$(check_file skills/x/notes.md "---
description: ${DESC_300}d
---

# T
")" "clean/0" "only a SKILL.md's description is capped"
# A URL, so the line cap lets the line through and only the description cap could object.
assert "$(check_file skills/x/SKILL.md "# T

description: https://example.com/$DESC_300
")" "clean/0" "a description line outside front matter is prose"

e_header "vendored directories"

printf '# vendored\n' > "$workdir/skills/x/VENDORED.md"
assert "$(check_file skills/x/SKILL.md "# T

$LONG_LINE
$(repeat_lines 400)")" "clean/0" "a directory holding a VENDORED.md is skipped entirely"
# Dropping a VENDORED.md into a directory must not erase pins it already had.
rm -f "$workdir/skills/x/VENDORED.md"
printf '# T\n\n%s' "$(repeat_lines 150)" > "$workdir/skills/x/long.md"
git -C "$workdir" add -A >/dev/null 2>&1
(cd "$workdir" && bin/check-md-limits --update-baseline skills/x/long.md >/dev/null 2>&1)
printf '# vendored\n' > "$workdir/skills/x/VENDORED.md"
(cd "$workdir" && bin/check-md-limits --update-baseline >/dev/null 2>&1)
assert "$(grep -c 'skills/x/long.md' "$workdir/.md-baseline")" "1" \
  "a pin survives its directory becoming vendored"
rm -f "$workdir/skills/x/VENDORED.md" "$workdir/skills/x/long.md"

assert "$(check_file fenced-body.md "# T

\`\`\`
$(repeat_lines 250)
\`\`\`
")" "ERROR/1" "a closed fence is exempt from the line cap but still counts as length"

e_header "follow-up trackers"

# The comment every tracker opens with, naming the skill that maintains it.
TRACKER_TOP="<!--
Maintain with the \`maintaining-follow-up-trackers\` skill.
-->
"

assert "$(check_file tracker.md "${TRACKER_TOP}# Follow-ups

$(repeat_lines 400)")" "clean/0" "a follow-up tracker has no length cap"

assert "$(check_file tracker-long-line.md "${TRACKER_TOP}# Follow-ups

$LONG_LINE
")" "ERROR/1" "a follow-up tracker's lines are still capped"

assert "$(check_file late-comment.md "# Notes
${TRACKER_TOP}
$(repeat_lines 400)")" "ERROR/1" "naming the skill in a comment below line 1 does not make a tracker"

assert "$(check_file open-comment.md "<!--
Maintain with the \`maintaining-follow-up-trackers\` skill.
$(repeat_lines 400)")" "ERROR/1" "an opening comment that never closes does not make a tracker"

# Becoming a tracker must not erase a pin the file already had.
printf '# T\n\n%s' "$(repeat_lines 150)" > "$workdir/tracker-pin.md"
git -C "$workdir" add -A >/dev/null 2>&1
(cd "$workdir" && bin/check-md-limits --update-baseline tracker-pin.md >/dev/null 2>&1)
printf '%s# T\n\n%s' "$TRACKER_TOP" "$(repeat_lines 150)" > "$workdir/tracker-pin.md"
(cd "$workdir" && bin/check-md-limits --update-baseline >/dev/null 2>&1)
assert "$(grep -c 'tracker-pin.md' "$workdir/.md-baseline")" "1" \
  "a pin survives its file becoming a tracker"
rm -f "$workdir/tracker-pin.md"

e_header "plan files"

# Plans are deleted once the work ships, so only their lines are checked.
mkdir -p "$workdir/plans"
assert "$(check_file PLAN-x.md "# Plan

$(repeat_lines 400)")" "clean/0" "a PLAN-*.md file has no length cap"
assert "$(check_file plan-x.md "# Plan

$(repeat_lines 400)")" "clean/0" "a plan-*.md file at the root has no length cap"
mkdir -p "$workdir/rules"
assert "$(check_file rules/plan-files.md "# Rule

$(repeat_lines 400)")" "ERROR/1" "a nested plan-*.md, like the plan-files rule, is still capped"
assert "$(check_file plans/step.md "# Plan

$(repeat_lines 400)")" "clean/0" "a file under plans/ has no length cap"
assert "$(check_file PLAN-long-line.md "# Plan

$LONG_LINE
")" "ERROR/1" "a plan file's lines are still capped"
assert "$(check_file not-a-plan.md "# Notes

$(repeat_lines 400)")" "ERROR/1" "a file merely mentioning plans is still capped"

e_header "the baseline ratchet"

# Carries the exit status, like check_file: the pin-growth branch sets errors=1,
# and a mutation dropping that would leave the hook and CI open while still
# printing the error.
pinned_state() {
  local output rc
  output="$(cd "$workdir" && bin/check-md-limits pinned.md 2>&1)" && rc=0 || rc=$?
  echo "$(echo "$output" | grep -oE '^(ERROR|NOTE)' | head -1)/$rc"
}

printf '# T\n\n%s' "$(repeat_lines 150)" > "$workdir/pinned.md"
git -C "$workdir" add -A >/dev/null 2>&1
(cd "$workdir" && bin/check-md-limits --update-baseline pinned.md >/dev/null 2>&1)

assert "$(grep -c 'pinned.md' "$workdir/.md-baseline")" "1" "pinning writes exactly one entry"
assert "$(pinned_state)" "/0" "a file at its pinned size is silent"

printf '# T\n\n%s' "$(repeat_lines 160)" > "$workdir/pinned.md"
assert "$(pinned_state)" "ERROR/1" "growing past a pin is an error, not an advisory"

# The ratchet must survive a file that has grown past its hard cap: dropping the
# pin there would silently raise the file's ceiling to the cap.
printf '# T\n\n%s' "$(repeat_lines 250)" > "$workdir/pinned.md"
(cd "$workdir" && bin/check-md-limits --update-baseline >/dev/null 2>&1)
assert "$(awk -F'\t' '$2 == "pinned.md" { print $1 }' "$workdir/.md-baseline")" "150" \
  "a pin survives the file outgrowing its hard cap"

printf '# T\n\n%s' "$(repeat_lines 20)" > "$workdir/pinned.md"
(cd "$workdir" && bin/check-md-limits --update-baseline >/dev/null 2>&1)
assert "$(grep -c 'pinned.md' "$workdir/.md-baseline" || true)" "0" \
  "a pin is dropped once the file is back under its warn line"

# Shrinking a pinned file is the improvement the ratchet banks, but it leaves the
# baseline stale — which CI would catch and the author would not.
printf '# T\n\n%s' "$(repeat_lines 150)" > "$workdir/shrunk.md"
git -C "$workdir" add -A >/dev/null 2>&1
(cd "$workdir" && bin/check-md-limits --update-baseline shrunk.md >/dev/null 2>&1)
printf '# T\n\n%s' "$(repeat_lines 140)" > "$workdir/shrunk.md"
assert "$(cd "$workdir" && bin/check-md-limits shrunk.md 2>&1 | grep -oE '^NOTE' | head -1)" "NOTE" \
  "shrinking a pinned file says so locally, rather than only failing CI"

printf '# T\n\n%s' "$(repeat_lines 150)" > "$workdir/pinned.md"
git -C "$workdir" add -A >/dev/null 2>&1
(cd "$workdir" && bin/check-md-limits --update-baseline pinned.md >/dev/null 2>&1)
printf '# T\n\n%s' "$(repeat_lines 170)" > "$workdir/pinned.md"
(cd "$workdir" && bin/check-md-limits --update-baseline >/dev/null 2>&1)
assert "$(awk -F'\t' '$2 == "pinned.md" { print $1 }' "$workdir/.md-baseline")" "150" \
  "a pin is not raised when the file grows but stays under its hard cap"

# A baseline nobody can parse must not be silently rewritten: the ratchet's own
# failure mode would otherwise be total release.
printf '# T\n\n%s' "$(repeat_lines 150)" > "$workdir/pinned.md"
git -C "$workdir" add -A >/dev/null 2>&1
(cd "$workdir" && bin/check-md-limits --update-baseline pinned.md >/dev/null 2>&1)
printf 'garbage line without a tab\n' >> "$workdir/.md-baseline"
(cd "$workdir" && bin/check-md-limits --update-baseline >/dev/null 2>&1)
assert "$(grep -c 'pinned.md' "$workdir/.md-baseline")" "1" \
  "a malformed baseline is not rewritten, so pins survive"
assert "$(cd "$workdir" && bin/check-md-limits >/dev/null 2>&1; echo $?)" "2" \
  "a malformed baseline is an error, not a silent unpin"
grep -v 'garbage' "$workdir/.md-baseline" > "$workdir/.md-baseline.tmp"
mv "$workdir/.md-baseline.tmp" "$workdir/.md-baseline"

# The ratchet must never widen on its own: a no-arg regen only tightens pins
# that already exist.
printf '# T\n\n%s' "$(repeat_lines 150)" > "$workdir/unpinned.md"
git -C "$workdir" add -A >/dev/null 2>&1
(cd "$workdir" && bin/check-md-limits --update-baseline >/dev/null 2>&1)
assert "$(grep -c 'unpinned.md' "$workdir/.md-baseline" || true)" "0" \
  "a no-arg re-pin never creates a pin for a file that had none"

# A tab-shaped but non-numeric size passed validation, then lost the pin.
printf '# T\n\n%s' "$(repeat_lines 150)" > "$workdir/pinned.md"
git -C "$workdir" add -A >/dev/null 2>&1
(cd "$workdir" && bin/check-md-limits --update-baseline pinned.md >/dev/null 2>&1)
printf 'abc\tpinned.md\n' > "$workdir/.md-baseline"
assert "$(cd "$workdir" && bin/check-md-limits >/dev/null 2>&1; echo $?)" "2" \
  "a non-numeric pin size is an error, not a silent unpin"
rm -f "$workdir/.md-baseline"
(cd "$workdir" && bin/check-md-limits --update-baseline pinned.md >/dev/null 2>&1)

e_header "invocation"

printf '# T\n\n%s\n' "$LONG_LINE" > "$workdir/args.md"
git -C "$workdir" add -A >/dev/null 2>&1

assert "$(cd "$workdir" && bin/check-md-limits ./args.md 2>&1 | grep -c 'exceeds 150 characters')" "1" \
  "a ./-prefixed path is checked"

assert "$(cd "$workdir" && bin/check-md-limits "$workdir/args.md" 2>&1 | grep -c 'exceeds 150 characters')" "1" \
  "an absolute path is checked"

mkdir -p "$workdir/sub"
assert "$(cd "$workdir/sub" && ../bin/check-md-limits ../args.md 2>&1 | grep -c 'exceeds 150 characters')" "1" \
  "a path relative to a subdirectory is checked"

assert "$(cd "$workdir" && bin/check-md-limits nope.md >/dev/null 2>&1; echo $?)" "1" \
  "a nonexistent path is an error, not a pass"

# --no-warn is the form CI runs: it must still report violations, just not advisories.
assert "$(cd "$workdir" && bin/check-md-limits --no-warn args.md >/dev/null 2>&1; echo $?)" "1" \
  "--no-warn still fails on a violation"
assert "$(cd "$workdir" && bin/check-md-limits --no-warn near-cap.md 2>&1)" "" \
  "--no-warn drops advisories"

# CI runs --no-warn, so a pin breach has to survive it.
printf '# T\n\n%s' "$(repeat_lines 180)" > "$workdir/pinned.md"
assert "$(cd "$workdir" && bin/check-md-limits --no-warn pinned.md >/dev/null 2>&1; echo $?)" "1" \
  "--no-warn still fails on a pin breach"

printf '# T\n\n%s\n' "$LONG_LINE" > "$workdir/-dash.md"
printf '# T\n\n%s\n' "$LONG_LINE" > "$workdir/a file.md"
git -C "$workdir" add -A >/dev/null 2>&1
assert "$(cd "$workdir" && bin/check-md-limits -- -dash.md 2>&1 | grep -c 'exceeds 150 characters')" "1" \
  "-- lets a filename start with a dash"
assert "$(cd "$workdir" && bin/check-md-limits "a file.md" 2>&1 | grep -c 'exceeds 150 characters')" "1" \
  "a filename containing a space is checked"

printf '# T\n\n%s\n' "$LONG_LINE" > "$workdir/café.md"
git -C "$workdir" add -A >/dev/null 2>&1
assert "$(cd "$workdir" && bin/check-md-limits 2>&1 | grep -c 'café.md exceeds')" "1" \
  "a non-ASCII filename survives git's C-quoting in the whole-repo scan"

assert "$(cd "$workdir" && bin/check-md-limits --bogus >/dev/null 2>&1; echo $?)" "2" \
  "an unknown option exits 2"

# A symlinked file kept an absolute key, so it missed its pin and was measured
# against the wrong type's cap — the shape ~/.claude/CLAUDE.md has every day.
printf '# T\n\n%s' "$(repeat_lines 150)" > "$workdir/linked.md"
git -C "$workdir" add -A >/dev/null 2>&1
(cd "$workdir" && bin/check-md-limits --update-baseline linked.md >/dev/null 2>&1)
linkdir="$(mktemp -d)"
ln -s "$workdir/linked.md" "$linkdir/linked.md"
assert "$(cd "$linkdir" && "$workdir/bin/check-md-limits" "$linkdir/linked.md" 2>&1; echo "rc=$?")" "rc=0" \
  "a file reached through a symlink keys to its real path, so its pin applies"
rm -rf "$linkdir"

# Green having checked nothing is the worst outcome a checker can produce.
nogit="$(mktemp -d)"
mkdir -p "$nogit/bin"
cp "$CHECKER" "$nogit/bin/"
assert "$(cd "$nogit" && bin/check-md-limits >/dev/null 2>&1; echo $?)" "2" \
  "outside a git repository it errors rather than passing empty"
rm -rf "$nogit"

e_header "--count-raw and front matter"

# The workflow-docs test counts through --count-raw, so it must match the cap's count.
printf -- '---\nname: x\n---\n# H\n\nbody\n```\n# in fence\n```\n' > "$workdir/count.md"
assert "$(cd "$workdir" && bin/check-md-limits --count-raw count.md)" "4" \
  "--count-raw skips front matter, headings and blanks but counts a # line inside a fence"
assert "$(cd "$workdir" && bin/check-md-limits --count-raw >/dev/null 2>&1; echo $?)" "2" "--count-raw without a file exits 2"
assert "$(cd "$workdir" && bin/check-md-limits --count-raw count.md count.md >/dev/null 2>&1; echo $?)" "2" "--count-raw with two files exits 2"
assert "$(cd "$workdir" && bin/check-md-limits --count-raw nope.md >/dev/null 2>&1; echo $?)" "2" "--count-raw on a missing file exits 2"

# One front-matter definition: the same file must be skipped by the line-length check and by the cap.
# A long line in YAML front matter is not reported, and the same block is not counted.
printf -- '---\nname: x\ndescription: %s\n---\nbody\n' "$LONG_LINE" > "$workdir/fm.md"
assert "$(cd "$workdir" && bin/check-md-limits fm.md >/dev/null 2>&1; echo $?)" "0" "a long line inside front matter is not reported"
assert "$(cd "$workdir" && bin/check-md-limits --count-raw fm.md)" "1" "the same front matter is not counted"
# Prose between two separators is a thematic break: both checks must see the body.
printf -- '---\n\nprose\n---\n%s\n' "$LONG_LINE" > "$workdir/hr.md"
assert "$(cd "$workdir" && bin/check-md-limits hr.md >/dev/null 2>&1; echo $?)" "1" "a thematic break is not front matter for the line check"
assert "$(cd "$workdir" && bin/check-md-limits --count-raw hr.md)" "4" "a thematic break is not front matter for the count"

test_done
