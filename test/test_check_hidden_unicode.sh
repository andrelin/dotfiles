#!/usr/bin/env bash
# Resolve the script under test before sourcing the helper: bin/dotfiles exports
# DOTFILES=~/.dotfiles when sourced, so afterwards this would test whatever tree
# lives there rather than the one this file was launched from.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHECKER="$ROOT/bin/check-hidden-unicode"
readonly ROOT CHECKER

source "$DOTFILES/test/helper.sh"

e_header "$(basename "$0" .sh)"

# First, so a CI leg without perl's charnames fails here and not as a confusing wrong name below.
perl -Mcharnames=:full -e1 >/dev/null 2>&1
assert $? 0 "perl has the charnames module"

if [[ ! -x "$CHECKER" ]]; then
  echo "ERROR: $CHECKER is missing or not executable" >&2
  exit 1
fi

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

# Writes the UTF-8 bytes of a code point, "no warnings" so U+E0000 and U+DFFFF encode plainly.
function u() { perl -e 'no warnings; binmode STDOUT, ":utf8"; print chr(hex $ARGV[0])' "$1"; }

# Runs the checker; sets $out (stdout), $err (stderr) and $rc.
function run() {
  local o e
  o="$(mktemp "$workdir/out.XXXXXX")" e="$(mktemp "$workdir/err.XXXXXX")"
  "$CHECKER" "$@" >"$o" 2>"$e" && rc=0 || rc=$?
  out="$(cat "$o")"
  err="$(cat "$e")"
}

# Writes "a<char>b" to a fixture and reports the outcome as "rc|output".
function probe() {
  printf 'a%sb\n' "$(u "$1")" > "$workdir/p"
  run "$workdir/p"
  echo "$rc|${out//$workdir\//}"
}

# Flagged ends of each range: exit 1, the code point and the line named.
for spec in 200B 200D 2060 2064 200E 200F 202A 202E 2066 2069 E0000 E007F 180E 00AD FE00 FE0E E0100 E01EF; do
  got="$(probe "$spec")"
  assert "${got%%|*}" 1 "U+$spec flagged: exit"
  assert "$([[ "${got#*|}" == "p:1: U+$spec "* ]] && echo yes)" yes "U+$spec flagged: names code point and line (got: ${got#*|})"
done

# Their outside neighbours pass.
for spec in 200A 2010 205F 2065 2029 202F 206A DFFFF E0080 00AC 00AE FDFF FE0F E00FF E01F0 FEFE FF00; do
  assert "$(probe "$spec")" "0|" "U+$spec passes"
done

# U+FEFF: fine at byte 0 only.
printf '\xef\xbb\xbfhello\n' > "$workdir/bom"
run "$workdir/bom"
assert "$rc|$out" "0|" "BOM at byte 0 passes"
printf 'ab\xef\xbb\xbfc\n' > "$workdir/mid"
run "$workdir/mid"
assert "$rc|${out#"$workdir"/}" "1|mid:1: U+FEFF ZERO WIDTH NO-BREAK SPACE" "U+FEFF mid-line flagged"
printf 'one\n\xef\xbb\xbftwo\n' > "$workdir/l2"
run "$workdir/l2"
assert "$rc|${out#"$workdir"/}" "1|l2:2: U+FEFF ZERO WIDTH NO-BREAK SPACE" "U+FEFF at the start of line 2 flagged"
printf '\xef\xbb\xbf\xef\xbb\xbfx\n' > "$workdir/two"
run "$workdir/two"
assert "$rc|$(echo "$out" | wc -l | tr -d ' ')" "1|1" "a second U+FEFF at byte 3 is flagged once; only byte 0 is exempt"

# Ordinary non-ASCII text passes; a ZWJ sequence is flagged at its U+200D.
printf '\xef\xbb\xbf\xe2\x80\x94 \xe2\x86\x92 \xc3\xa6\xc3\xb8\xc3\xa5 \xe2\x9c\x85 \xe2\x9d\xa4\xef\xb8\x8f\n' > "$workdir/text"
run "$workdir/text"
assert "$rc|$out" "0|" "dash, arrow, Norwegian letters, emoji and a BOM pass"
printf 'x %s\n' "$(u 1F468)$(u 200D)$(u 1F469)$(u 200D)$(u 1F467)" > "$workdir/zwj"
run "$workdir/zwj"
assert "$rc|$(echo "$out" | wc -l | tr -d ' ')" "1|2" "a family emoji is flagged at each of its two ZWJs"
printf 'x %s\n' "$(u 1F468)$(u 200D)$(u 1F469)" > "$workdir/zwj1"
run "$workdir/zwj1"
assert "$rc|${out#"$workdir"/}" "1|zwj1:1: U+200D ZERO WIDTH JOINER" "a ZWJ sequence gives one hit, U+200D"

# Malformed bytes elsewhere do not stop the scan; unnamed code points are labelled.
printf 'x\xff\n%s\n' "$(u 200B)" > "$workdir/bad"
run "$workdir/bad"
assert "$rc|${out#"$workdir"/}" "1|bad:2: U+200B ZERO WIDTH SPACE" "a stray 0xFF byte does not hide a U+200B"
printf '%s\n' "$(u E0000)" > "$workdir/tag"
run "$workdir/tag"
assert "$rc|${out#"$workdir"/}" "1|tag:1: U+E0000 (no name)" "an unnamed code point says so"
: > "$workdir/empty"
run "$workdir/empty"
assert "$rc|$out" "0|" "an empty file passes"
printf 'a%s' "$(u 200B)" > "$workdir/nonl"
run "$workdir/nonl"
assert "$rc|${out#"$workdir"/}" "1|nonl:1: U+200B ZERO WIDTH SPACE" "a hit on a last line without a newline is found"

# Output shape and exit codes.
printf 'a%sb%sc\n' "$(u 202E)" "$(u 200B)" > "$workdir/two1"
run "$workdir/two1"
assert "${out//$workdir\//}" "two1:1: U+202E RIGHT-TO-LEFT OVERRIDE
two1:1: U+200B ZERO WIDTH SPACE" "two hits on one line get a line each, in order"
run "$workdir/nope"
assert "$rc|$out|${err//$workdir\//}" "2||nope: no such file" "a missing file: exit 2 and a stderr line"
run "$workdir/nope" "$workdir/mid"
assert "$rc|${out//$workdir\//}|${err//$workdir\//}" "2|mid:1: U+FEFF ZERO WIDTH NO-BREAK SPACE|nope: no such file" \
  "a missing file named before a hit: the hit and the stderr line, exit 2"
run "$workdir"
assert "$rc" 2 "a directory counts as no such file"
run --bogus
assert "$rc" 2 "an unknown option exits 2"

# Everything below needs git repos. Each is created in a call of its own.
repo="$workdir/repo"
mkdir -p "$repo"
git init -q "$repo"
git -C "$repo" config user.email t@example.com
git -C "$repo" config user.name t
mkdir -p "$repo/claude/skills/unslop" "$repo/.claude" "$repo/sub" "$repo/docs"
bad="a$(u 200B)b"
for f in claude/a.md .claude/b.json sub/CLAUDE.md sub/AGENTS.md "claude/a b.md" "claude/å.md" docs/d.md claude/skills/unslop/e.md; do
  printf '%s\n' "$bad" > "$repo/$f"
done
printf '%s\n' "$bad" > "$repo/claude/c.md"
printf 'clean\n' > "$repo/claude/clean.md"
git -C "$repo" add -f claude/a.md .claude/b.json sub/CLAUDE.md sub/AGENTS.md "claude/a b.md" "claude/å.md" docs/d.md claude/skills/unslop/e.md claude/clean.md

function run_in() {
  local dir="$1"
  shift
  local o e
  o="$(mktemp "$workdir/out.XXXXXX")" e="$(mktemp "$workdir/err.XXXXXX")"
  (cd "$dir" && "$CHECKER" "$@") >"$o" 2>"$e" && rc=0 || rc=$?
  out="$(cat "$o")"
  err="$(cat "$e")"
}

run_in "$repo"
assert "$rc" 1 "default set: exit 1"
assert "$(echo "$out" | cut -d: -f1 | LC_ALL=C sort)" ".claude/b.json
claude/a b.md
claude/a.md
claude/å.md
sub/AGENTS.md
sub/CLAUDE.md" "default set: the six tracked files, space and non-ASCII names intact; untracked, docs/ and unslop skipped"
run_in "$repo/sub"
assert "$(echo "$out" | wc -l | tr -d ' ')" 6 "default set from a subdirectory still covers the toplevel set"
run_in "$workdir"
assert "$rc" 2 "no files outside a git repository: exit 2"

run_in "$ROOT"
assert "$rc|$out" "0|" "the real repo passes"

# --cached reads the index, not the working tree.
printf 'clean\n' > "$repo/claude/a.sh"
git -C "$repo" add claude/a.sh
printf 'clean%s\n' "$(u 200B)" > "$repo/claude/a.sh"
run_in "$repo" --cached claude/a.sh
assert "$rc|$out" "0|" "--cached ignores an unstaged U+200B"
git -C "$repo" add claude/a.sh
run_in "$repo" --cached claude/a.sh
assert "$rc|$out" "1|claude/a.sh:1: U+200B ZERO WIDTH SPACE" "--cached finds a staged U+200B"
run_in "$repo" --cached claude/c.md
assert "$rc|$out|$err" "2||claude/c.md: no such file" "--cached on an untracked file: exit 2"
run_in "$repo" --cached "$repo/claude/a.sh"
assert "$rc|$out" "1|$repo/claude/a.sh:1: U+200B ZERO WIDTH SPACE" "--cached with an absolute path"
run_in "$repo" --cached "$workdir/p"
assert "$rc|$err" "2|$workdir/p: no such file" "--cached with an absolute path outside the repo: no such file"
run_in "$repo" --cached claude
assert "$rc|$err" "2|claude: no such file" "--cached on a directory: no such file"
run_in "$repo" --cached claude claude/a.sh
assert "$rc|$out|$err" "2|claude/a.sh:1: U+200B ZERO WIDTH SPACE|claude: no such file" "--cached on a directory before a file: both reported"
run_in "$repo" --cached
assert "$(echo "$out" | cut -d: -f1 | grep -c .)" 7 "--cached with no files scans the index's default set"

# Attribution and per-file line numbers, in worktree mode and staged.
multi="$workdir/multi"
mkdir -p "$multi"
git init -q "$multi"
z="$(u 200B)"
printf 'clean\n' > "$multi/c1"
printf 'a\nb%s\n' "$z" > "$multi/h1"
printf 'clean\n' > "$multi/c2"
printf 'a\nb\nc\nd%s\n' "$z" > "$multi/h2"
printf 'l1\nl2\nl3\nl4' > "$multi/ml"
printf '%s\n' "$z" > "$multi/second"
git -C "$multi" add c1 h1 c2 h2 ml second
expected="h1:2: U+200B ZERO WIDTH SPACE
h2:4: U+200B ZERO WIDTH SPACE"
run_in "$multi" --cached c1 h1 c2 h2
assert "$rc|$out" "1|$expected" "--cached: hits attributed to the right files among clean ones"
run_in "$multi" c1 h1 c2 h2
assert "$rc|$out" "1|$expected" "worktree: hits attributed to the right files among clean ones"
run_in "$multi" --cached ml second
assert "$rc|$out" "1|second:1: U+200B ZERO WIDTH SPACE" "--cached: line numbers restart per file"
run_in "$multi" ml second
assert "$rc|$out" "1|second:1: U+200B ZERO WIDTH SPACE" "worktree: line numbers restart per file"

# The pre-commit hook runs the check with no paths.
hookrepo="$workdir/hook"
mkdir -p "$hookrepo/bin" "$hookrepo/hooks" "$hookrepo/claude" "$hookrepo/docs"
git init -q "$hookrepo"
cp "$ROOT/hooks/pre-commit" "$hookrepo/hooks/"
cp "$ROOT/bin/check-md-limits" "$ROOT/bin/check-hidden-unicode" "$hookrepo/bin/"
printf 'clean\n' > "$hookrepo/claude/a.sh"
git -C "$hookrepo" add claude/a.sh
printf 'clean%s\n' "$(u 200B)" > "$hookrepo/claude/a.sh"
function hook() { (cd "$hookrepo" && "$BASH" hooks/pre-commit) >"$workdir/h.out" 2>&1 && rc=0 || rc=$?; }
hook
assert "$rc" 0 "hook: clean staged blob, unstaged U+200B -> pass"
git -C "$hookrepo" add claude/a.sh
hook
assert "$rc" 1 "hook: staged U+200B -> blocked"
assert "$(grep -c 'claude/a.sh:1: U+200B' "$workdir/h.out")" 1 "hook: names the file and code point"
printf 'clean\n' > "$hookrepo/claude/a.sh"
git -C "$hookrepo" add claude/a.sh
printf '<!-- DOCTOC SKIP -->\n\n# Title\n\nx%s\n' "$(u 200B)" > "$hookrepo/docs/d.md"
git -C "$hookrepo" add docs/d.md
hook
assert "$rc" 0 "hook: U+200B only in docs/d.md, outside the default set -> pass"

test_done
