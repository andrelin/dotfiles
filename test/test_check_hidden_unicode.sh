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

hint="check-hidden-unicode: delete each character named above; a NUL means the file isn't UTF-8 text (Tip 24.9)"

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
for spec in 200B 200D 2060 2064 206A 206F 200E 200F 202A 202E 2066 2069 061C E0000 E007F 180B 180D 180E 180F 00AD \
  034F 115F 1160 17B4 17B5 3164 FFA0 FFF9 FFFB FE00 FE0E E0100 E01BF E01C0 E01EF 2800 13430 1343F 1D173 1D17A; do
  got="$(probe "$spec")"
  assert "${got%%|*}" 1 "U+$spec flagged: exit"
  assert "$([[ "${got#*|}" == "p:1: U+$spec "* && "${got#*|}" != *$'\n'* ]] && echo yes)" yes \
    "U+$spec flagged: one line, naming code point and line (got: ${got#*|})"
done

# Their outside neighbours pass.
for spec in 200A 2010 205F 2065 2070 2029 202F 061B 061D 180A 1810 DFFFF E0080 00AC 00AE FDFF FE0F E00FF E01F0 \
  034E 0350 115E 1161 17B3 17B6 3163 3165 FF9F FFA1 FFF8 FFFC 27FF 2801 1342F 13440 1D172 1D17B FEFE FF00; do
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
run "$workdir/mid" "$workdir/nope"
assert "$rc" 2 "a hit named before a missing file: still exit 2"
run "$workdir/nope" "$workdir/mid"
assert "$rc|${out//$workdir\//}|${err//$workdir\//}" "2|mid:1: U+FEFF ZERO WIDTH NO-BREAK SPACE|nope: no such file
$hint" \
  "a missing file named before a hit: the hit and the stderr line, exit 2"
run "$workdir"
assert "$rc" 2 "a directory counts as no such file"
run --bogus
assert "$rc" 2 "an unknown option exits 2"

# Everything below needs git repos.
repo="$workdir/repo"
mkdir -p "$repo"
git init -q "$repo"
git -C "$repo" config user.email t@example.com
git -C "$repo" config user.name t
mkdir -p "$repo/claude/skills/unslop" "$repo/.claude" "$repo/sub/.claude" "$repo/sub" "$repo/lower" "$repo/docs"
bad="a$(u 200B)b"
for f in claude/a.md .claude/b.json sub/.claude/c.md CLAUDE.md sub/CLAUDE.md sub/AGENTS.md lower/agents.md "claude/a b.md" "claude/å.md" docs/d.md \
  claude/skills/unslop/e.md; do
  printf '%s\n' "$bad" > "$repo/$f"
done
printf '%s\n' "$bad" > "$repo/claude/c.md"
printf 'clean\n' > "$repo/claude/clean.md"
git -C "$repo" add -f claude/a.md .claude/b.json sub/.claude/c.md CLAUDE.md sub/CLAUDE.md sub/AGENTS.md lower/agents.md "claude/a b.md" "claude/å.md" \
  docs/d.md claude/skills/unslop/e.md claude/clean.md

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
CLAUDE.md
claude/a b.md
claude/a.md
claude/skills/unslop/e.md
claude/å.md
lower/agents.md
sub/.claude/c.md
sub/AGENTS.md
sub/CLAUDE.md" "default set: ten tracked files, a nested .claude/ among them, root CLAUDE.md, agents.md, odd names, vendored skill; not untracked or docs/"
default_set="$out"
run_in "$repo/sub"
assert "$rc|$out" "1|$default_set" "default set from a subdirectory: the same toplevel set, same names"
run_in "$workdir"
assert "$rc" 2 "no files outside a git repository: exit 2"

run_in "$ROOT"
assert "$rc|$out" "0|" "the real repo passes"
run_in "$ROOT" --cached
assert "$rc|$out|$err" "0||" "the real repo's index passes, as pre-commit runs it"

# A repository with nothing in the default set passes, in both modes.
empty="$workdir/empty-set"
mkdir -p "$empty/docs"
git init -q "$empty"
printf 'a%sb\n' "$(u 200B)" > "$empty/docs/d.md"
git -C "$empty" add docs/d.md
run_in "$empty"
assert "$rc|$out|$err" "0||" "an empty default set passes"
run_in "$empty" --cached
assert "$rc|$out|$err" "0||" "an empty default set passes, --cached"

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
assert "$rc|$out|$err" "2|claude/a.sh:1: U+200B ZERO WIDTH SPACE|claude: no such file
$hint" "--cached on a directory before a file: both reported, and the hint"
run_in "$repo" --cached
assert "$rc|$(echo "$out" | cut -d: -f1 | LC_ALL=C sort)" "1|.claude/b.json
CLAUDE.md
claude/a b.md
claude/a.md
claude/a.sh
claude/skills/unslop/e.md
claude/å.md
lower/agents.md
sub/.claude/c.md
sub/AGENTS.md
sub/CLAUDE.md" "--cached with no files scans the index's default set"

# Relative paths from a subdirectory, one leaving the repository.
run_in "$repo/sub" --cached CLAUDE.md
assert "$rc|$out" "1|CLAUDE.md:1: U+200B ZERO WIDTH SPACE" "--cached from a subdirectory reads the path relative to it"
run_in "$repo/sub" --cached ../../outside.md ../claude/a.sh
assert "$rc|$out|$err" "2|../claude/a.sh:1: U+200B ZERO WIDTH SPACE|../../outside.md: no such file
$hint" \
  "--cached with a relative path outside the repo: no such file, the next file still checked"

# -- ends the options, so a file may start with a dash.
printf 'a%sb\n' "$(u 200B)" > "$workdir/-dash.md"
run_in "$workdir" -- -dash.md
assert "$rc|$out" "1|-dash.md:1: U+200B ZERO WIDTH SPACE" "-- lets a file name start with a dash"

# The default set skips what isn't a regular file, quietly; a named one is still reported.
skip="$workdir/skip"
mkdir -p "$skip/claude/dir"
git init -q "$skip"
printf 'clean\n' > "$skip/claude/dir/f.md"
ln -s nowhere "$skip/claude/dangling.md"
ln -s dir "$skip/claude/dirlink"
printf 'clean\n' > "$skip/claude/gone.md"
git -C "$skip" add claude
git -C "$skip" update-index --add --cacheinfo "160000,$(printf '%040d' 1),claude/module"
# A gitlink whose object exists, so cat-file answers with a tree, not "missing".
git -C "$skip" update-index --add --cacheinfo "160000,$(git -C "$skip" hash-object -t tree -w /dev/null),claude/module2"
rm "$skip/claude/gone.md"
run_in "$skip"
assert "$rc|$out|$err" "0||" "default set: a dangling symlink, an unstaged deletion and gitlinks pass quietly"
run_in "$skip" --cached
assert "$rc|$out|$err" "0||" "default set, --cached: the same entries are skipped"
run_in "$skip" claude/dangling.md
assert "$rc|$err" "2|claude/dangling.md: no such file" "a named dangling symlink is still reported"
run_in "$skip" --cached claude/module2
assert "$rc|$err" "2|claude/module2: no such file" "--cached: a named gitlink whose object exists is no such file"

# Every NUL byte is reported, so nothing can hide a file from the scan, whatever .gitattributes says;
# UTF-16 has NULs too. The rest of the file is still scanned.
nul="$workdir/nul"
mkdir -p "$nul/claude/skills/vend"
git init -q "$nul"
printf 'claude/** binary\n' > "$nul/.gitattributes"
printf '*.md binary\n' > "$nul/claude/skills/vend/.gitattributes"
printf 'intro\nx\0y\nrun %s this\n' "$(u 202E)" > "$nul/claude/nul.md"
printf 'hi %s\n' "$(u 200B)" | iconv -f UTF-8 -t UTF-16 > "$nul/claude/wide.md"
printf 'do %s this\n' "$(u 202E)" > "$nul/claude/skills/vend/SKILL.md"
git -C "$nul" add .gitattributes claude
nul_expected="claude/nul.md:2: NUL byte, so not UTF-8 text
claude/nul.md:3: U+202E RIGHT-TO-LEFT OVERRIDE
claude/skills/vend/SKILL.md:1: U+202E RIGHT-TO-LEFT OVERRIDE
claude/wide.md:1: NUL byte, so not UTF-8 text"
run_in "$nul"
assert "$rc|$out" "1|$nul_expected" "default set: NULs reported and text scanned, binary attributes or not"
run_in "$nul" --cached
assert "$rc|$out" "1|$nul_expected" "default set, --cached: the same"
assert "$err" "check-hidden-unicode: delete each character named above; a NUL means the file isn't UTF-8 text (Tip 24.9)" \
  "a hit also says on stderr what to do"
run_in "$nul" claude/wide.md
assert "$rc|$out" "1|claude/wide.md:1: NUL byte, so not UTF-8 text" "a named UTF-16 file is reported"
run_in "$nul" --cached claude/nul.md
assert "$rc|$(echo "$out" | grep -c 'NUL byte')" "1|1" "--cached: a named file's NUL is reported"

# A git or perl failure mid-scan exits 2, "can't run", never 1, a hit.
mkdir -p "$workdir/badgit"
# It puts the caller's PATH back before running git, so a git found through a shim never finds this one again.
# FAIL names the subcommand to fail, "cat-file" by default; "cat-file blob" fails only that form.
printf '#!/bin/sh\ncase "$1 $2" in "${FAIL:-cat-file} "*|"${FAIL:-cat-file}") exit 128 ;; esac\nPATH=%q exec git "$@"\n' "$PATH" > "$workdir/badgit/git"
chmod +x "$workdir/badgit/git"
(cd "$nul" && PATH="$workdir/badgit:$PATH" "$CHECKER" --cached claude/nul.md) >"$workdir/bg.out" 2>&1 && rc=0 || rc=$?
assert "$rc|$(tail -1 "$workdir/bg.out")" "2|check-hidden-unicode: the scan failed (exit 3)" "a failed git cat-file: exit 2"
(cd "$nul" && FAIL=ls-files PATH="$workdir/badgit:$PATH" "$CHECKER") >"$workdir/bg.out" 2>&1 && rc=0 || rc=$?
assert "$rc|$(tail -1 "$workdir/bg.out")" "2|check-hidden-unicode: the scan failed (git ls-files)" \
  "a failed git ls-files listing the default set: exit 2, not an empty pass"
(cd "$nul" && FAIL=ls-files PATH="$workdir/badgit:$PATH" "$CHECKER" --cached claude/nul.md) >"$workdir/bg.out" 2>&1 && rc=0 || rc=$?
assert "$rc" 2 "a failed git ls-files reading the index: exit 2"

# Names git could misread: a leading <digit>: is a merge stage in a :<path> spec, and a newline ends a spec.
odd="$workdir/odd"
mkdir -p "$odd/1:evil" "$odd/claude" "$odd/docs"
git init -q "$odd"
printf 'a%sb\n' "$(u 200B)" > "$odd/1:evil/CLAUDE.md"
printf 'a%sb\n' "$(u 200B)" > "$odd/claude/new
line.md"
printf 'a%sb\n' "$(u 200B)" > "$odd/docs/claude.md"
printf 'a%sb\n' "$(u 200B)" > "$odd/claude/z.md"
git -C "$odd" add .
odd_names="1:evil/CLAUDE.md
claude/new
claude/z.md
docs/claude.md
line.md"
run_in "$odd" --cached
assert "$rc|$(echo "$out" | cut -d: -f1-2 | sed 's/:[0-9]*$//; s/^1$/1:evil\/CLAUDE.md/' | LC_ALL=C sort -u)" "1|$odd_names" \
  "--cached: a 1: directory, a newline in a name and a lower-case claude.md are all scanned"
run_in "$odd"
assert "$rc|$(echo "$out" | grep -c U+200B)" "1|4" "worktree: the same four files"
run_in "$odd" --cached 1:evil/CLAUDE.md
assert "$rc|$out" "1|1:evil/CLAUDE.md:1: U+200B ZERO WIDTH SPACE" "--cached: a named 1: path reads stage 0"

# --cached reads a staged symlink's blob, its target's path, then the staged blob behind it, under that file's path.
links="$workdir/links"
mkdir -p "$links/claude" "$links/docs"
git init -q "$links"
printf 'a%sb\n' "$(u 200B)" > "$links/docs/t.md"
ln -s ../docs/t.md "$links/claude/l.md"
ln -s l.md "$links/claude/chain.md"
git -C "$links" add docs/t.md claude/l.md
printf 'clean\n' > "$links/docs/t.md"
run_in "$links" --cached claude/l.md
assert "$rc|$out" "1|docs/t.md:1: U+200B ZERO WIDTH SPACE" "--cached: a symlink's staged target is scanned, not its clean working tree"
run_in "$links"
assert "$rc|$out" "0|" "worktree: a symlink is followed to the working tree file"
printf 'a%sb\n' "$(u 200B)" > "$links/docs/t.md"
run_in "$links"
assert "$rc|$out" "1|claude/l.md:1: U+200B ZERO WIDTH SPACE" "worktree: a hit through a symlink, under the symlink's name"
printf 'clean\n' > "$links/docs/t.md"
git -C "$links" add docs/t.md
printf 'a%sb\n' "$(u 200B)" > "$links/docs/t.md"
run_in "$links" --cached claude/l.md
assert "$rc|$out" "0|" "--cached: an unstaged hit in a symlink's target doesn't block"
git -C "$links" add docs/t.md claude/chain.md
run_in "$links" --cached claude/chain.md
assert "$rc|$out" "1|docs/t.md:1: U+200B ZERO WIDTH SPACE" "--cached: a chain of symlinks is followed"
ln -s ../docs/t.md "$links/claude/l2.md"
git -C "$links" add claude/l2.md
run_in "$links" --cached claude/l.md claude/l2.md docs/t.md
assert "$rc|$out" "1|docs/t.md:1: U+200B ZERO WIDTH SPACE" "--cached: a target named itself, or by two links, is reported once"

# A linked directory, a target outside the repository and a cycle.
edge="$workdir/edge"
mkdir -p "$edge/claude/skills" "$edge/vendor/foo"
git init -q "$edge"
printf 'a%sb\n' "$(u 200B)" > "$edge/vendor/foo/SKILL.md"
printf 'a%sb\n' "$(u 200B)" > "$workdir/outside.txt"
ln -s ../../vendor/foo "$edge/claude/skills/foo"
ln -s "$workdir/outside.txt" "$edge/claude/abs.md"
ln -s ../../../outside.txt "$edge/claude/up.md"
ln -s b.md "$edge/claude/a.md"
ln -s a.md "$edge/claude/b.md"
git -C "$edge" add .
run_in "$edge"
assert "$rc|$(echo "$out" | cut -d: -f1 | LC_ALL=C sort)" "1|claude/abs.md
claude/skills/foo/SKILL.md" "worktree: through a linked directory and an absolute link; a cycle passes"
run_in "$edge" --cached
assert "$rc|$(echo "$out" | cut -d: -f1 | LC_ALL=C sort)" "1|claude/abs.md
vendor/foo/SKILL.md" "--cached: a linked directory's staged files, and an absolute link's file on disk; a cycle ends"
run_in "$edge" --cached claude/up.md
assert "$rc|$out" "0|" "--cached: a relative link leaving the repo has no staged target and points at nothing here"
ln -s ../../outside.txt "$edge/claude/up2.md"
ln -s ../notes.md "$edge/claude/notes.md"
git -C "$edge" add claude/up2.md claude/notes.md
printf 'a%sb\n' "$(u 200B)" > "$edge/notes.md"
run_in "$edge" --cached claude/up2.md claude/notes.md
assert "$rc|$out" "1|claude/up2.md:1: U+200B ZERO WIDTH SPACE
notes.md:1: U+200B ZERO WIDTH SPACE" "--cached: a relative link out of the repo, and one to an untracked file, read from disk"

# Linked directories the index doesn't hold, a nested link inside one, and a long chain.
mkdir -p "$edge/untr" "$edge/ext" "$edge/other" "$edge/sub/inner"
printf 'a%sb\n' "$(u 200B)" > "$edge/untr/x.md"
printf 'a%sb\n' "$(u 200B)" > "$edge/other/y.md"
printf 'a%sb\n' "$(u 200B)" > "$edge/sub/inner/z.md"
ln -s ../other "$edge/ext/nested"
ln -s ../untr "$edge/claude/ud"
ln -s ../ext "$edge/claude/ext"
ln -s ../sub "$edge/claude/sm"
git -C "$edge" add claude/ud claude/ext claude/sm
git -C "$edge" update-index --add --cacheinfo "160000,$(git -C "$edge" hash-object -t tree -w /dev/null),sub"
run_in "$edge" --cached claude/ud claude/sm
assert "$rc|$out" "1|untr/x.md:1: U+200B ZERO WIDTH SPACE
sub/inner/z.md:1: U+200B ZERO WIDTH SPACE" "--cached: a link to an untracked directory or a gitlink is read from disk"
run_in "$edge"
assert "$(echo "$out" | grep -c '^claude/ext/nested/y.md:1: U+200B')" 1 "worktree: a link nested in a linked directory is followed"
mkdir -p "$edge/chain"
printf 'a%sb\n' "$(u 200B)" > "$edge/chain/end.md"
prev=end.md
for n in $(seq 1 41); do ln -s "$prev" "$edge/chain/l$n"; prev="l$n"; done
ln -s ../chain/l39 "$edge/claude/c40.md"
ln -s ../chain/l40 "$edge/claude/c41.md"
git -C "$edge" add chain claude/c40.md claude/c41.md
run_in "$edge" --cached claude/c40.md
assert "$rc|$out" "1|chain/end.md:1: U+200B ZERO WIDTH SPACE" "--cached: a chain of 40 links is followed"
run_in "$edge" --cached claude/c41.md
assert "$rc|$err" "2|claude/c41.md: no such file (more than 40 symlinks to follow)" "--cached: one more link gives up, and says so"

# A target reached through a staged directory symlink is read from the index too, not from disk.
dl="$workdir/dirlink"
mkdir -p "$dl/claude" "$dl/docs/real"
git init -q "$dl"
ln -s real "$dl/docs/d"
ln -s ../docs/d/x.md "$dl/claude/l.md"
printf 'a%sb\n' "$(u 200B)" > "$dl/docs/real/x.md"
git -C "$dl" add .
printf 'clean\n' > "$dl/docs/real/x.md"
run_in "$dl" --cached
assert "$rc|$out" "1|docs/real/x.md:1: U+200B ZERO WIDTH SPACE" "--cached: through a staged directory link, the staged blob"
git -C "$dl" add docs/real/x.md
printf 'a%sb\n' "$(u 200B)" > "$dl/docs/real/x.md"
run_in "$dl" --cached
assert "$rc|$out" "0|" "--cached: through a staged directory link, an unstaged hit doesn't block"
(cd "$dl" && FAIL="cat-file blob" PATH="$workdir/badgit:$PATH" "$CHECKER" --cached) >"$workdir/bg.out" 2>&1 && rc=0 || rc=$?
assert "$rc" 2 "a failed git cat-file blob following a link: exit 2"

# Many links through one directory link each resolve on their own, and ".." after a directory link applies to
# where the link led, as the kernel has it.
many="$workdir/many"
mkdir -p "$many/claude" "$many/docs/real" "$many/other/deep"
git init -q "$many"
ln -s real "$many/docs/d"
for n in $(seq 1 45); do
  printf 'clean\n' > "$many/docs/real/a$n.md"
  ln -s "../docs/d/a$n.md" "$many/claude/l$n.md"
done
printf 'a%sb\n' "$(u 200B)" > "$many/docs/real/a9.md"
ln -s ../other/deep "$many/docs/a"
ln -s ../docs/a/../b.md "$many/claude/up.md"
printf 'clean\n' > "$many/docs/b.md"
printf 'a%sb\n' "$(u 200B)" > "$many/other/b.md"
git -C "$many" add .
run_in "$many" --cached
assert "$rc|$out" "1|docs/real/a9.md:1: U+200B ZERO WIDTH SPACE
other/b.md:1: U+200B ZERO WIDTH SPACE" "--cached: 45 links through one directory link, and .. after a directory link"
run_in "$many"
assert "$rc|$(echo "$out" | cut -d: -f1 | LC_ALL=C sort)" "1|claude/l9.md
claude/up.md" "worktree: the same two"

# A link to the toplevel itself, an absolute target into the repository, and one that climbs out and back in.
back="$workdir/back"
mkdir -p "$back/claude" "$back/docs"
git init -q "$back"
back_top="$(cd "$back" && pwd -P)"
printf 'a%sb\n' "$(u 200B)" > "$back/docs/t.md"
ln -s .. "$back/claude/up"
ln -s "$back_top/docs/t.md" "$back/claude/abs.md"
ln -s "../../$(basename "$back_top")/docs/t.md" "$back/claude/round.md"
git -C "$back" add .
printf 'clean\n' > "$back/docs/t.md"
for link in claude/up claude/abs.md claude/round.md; do
  run_in "$back" --cached "$link"
  assert "$rc|$out" "1|docs/t.md:1: U+200B ZERO WIDTH SPACE" "--cached: through $link, the staged blob"
done

# Components the index doesn't hold are resolved on disk: an untracked link inside the repository, and an absolute
# target through a symlinked prefix above the toplevel (macOS's /var for /private/var, where the test's dir is under it).
ln -s . "$back/alias"
ln -s ../alias/docs/t.md "$back/claude/via.md"
git -C "$back" add claude/via.md
run_in "$back" --cached claude/via.md
assert "$rc|$out" "1|docs/t.md:1: U+200B ZERO WIDTH SPACE" "--cached: through an untracked link in the repo, the staged blob"
if [[ "$back" != "$back_top" ]]; then
  ln -s "$back/docs/t.md" "$back/claude/logical.md"
  git -C "$back" add claude/logical.md
  run_in "$back" --cached claude/logical.md
  assert "$rc|$out" "1|docs/t.md:1: U+200B ZERO WIDTH SPACE" "--cached: an absolute target through a symlinked prefix, the staged blob"
fi

# A Git LFS pointer is reported, in both modes: the text it stands for is scanned by neither.
lfs="$workdir/lfs"
mkdir -p "$lfs/claude"
git init -q "$lfs"
printf 'version https://git-lfs.github.com/spec/v1\noid sha256:%064d\nsize 12\n' 0 > "$lfs/claude/big.md"
git -C "$lfs" add claude
lfs_expected="claude/big.md:1: a Git LFS pointer, so its text can't be scanned: keep agent-loaded files out of LFS"
run_in "$lfs"
assert "$rc|$out" "1|$lfs_expected" "worktree: a Git LFS pointer is a hit"
run_in "$lfs" --cached
assert "$rc|$out" "1|$lfs_expected" "--cached: a Git LFS pointer is a hit"

# A named staged link to nothing is no such file, as in worktree mode; a tracked directory replaced on disk by an
# unstaged link still resolves to its staged files; PERL_UNICODE in the environment changes nothing.
mixed="$workdir/mixed"
mkdir -p "$mixed/claude" "$mixed/dir" "$mixed/clean"
git init -q "$mixed"
ln -s ../missing.md "$mixed/claude/dang.md"
printf 'a%sb\n' "$(u 200B)" > "$mixed/dir/x"
ln -s ../dir/x "$mixed/claude/l"
printf 'a%sb\n' "$(u 200B)" > "$mixed/docs-ø.md"
ln -s ../docs-ø.md "$mixed/claude/lnk-å.md"
git -C "$mixed" add .
run_in "$mixed" --cached claude/dang.md
assert "$rc|$err" "2|claude/dang.md: no such file" "--cached: a named staged link to nothing is no such file"
mv "$mixed/dir" "$mixed/dir.real"
printf 'clean\n' > "$mixed/clean/x"
ln -s clean "$mixed/dir"
run_in "$mixed" --cached claude/l
assert "$rc|$out" "1|dir/x:1: U+200B ZERO WIDTH SPACE" "--cached: a tracked directory replaced by an unstaged link reads as staged"
for pu in D SDL ""; do
  (cd "$mixed" && PERL_UNICODE="$pu" "$CHECKER" --cached "claude/lnk-å.md") >"$workdir/pu.out" 2>/dev/null && rc=0 || rc=$?
  assert "$rc|$(cat "$workdir/pu.out")" "1|docs-ø.md:1: U+200B ZERO WIDTH SPACE" "--cached with PERL_UNICODE='$pu': a non-ASCII link followed"
done

# The hint comes after the hits even when both streams go to one file, as in a CI log.
(cd "$lfs" && "$CHECKER") >"$workdir/both.out" 2>&1 || true
assert "$(tail -1 "$workdir/both.out")" "$hint" "the hint follows the hits in a combined log"

# The process budget: the git calls for --cached don't grow with the number of files (a link adds its own).
mkdir -p "$workdir/countgit"
printf '#!/bin/sh\necho "$1" >> %q\nPATH=%q exec git "$@"\n' "$workdir/git.calls" "$PATH" > "$workdir/countgit/git"
chmod +x "$workdir/countgit/git"
function git_calls() {
  : > "$workdir/git.calls"
  (cd "$1" && PATH="$workdir/countgit:$PATH" "$CHECKER" --cached) >/dev/null 2>&1 || true
  wc -l < "$workdir/git.calls" | tr -d ' '
}
for n in 1 30; do
  mkdir -p "$workdir/budget$n/claude"
  git init -q "$workdir/budget$n"
  for i in $(seq 1 "$n"); do printf 'clean\n' > "$workdir/budget$n/claude/f$i.md"; done
  git -C "$workdir/budget$n" add claude
done
assert "$(git_calls "$workdir/budget30")" "$(git_calls "$workdir/budget1")" "--cached: as many git calls for 30 files as for one"

# A submodule in the default set is scanned from disk, in both modes, its .git left out.
subm="$workdir/subm"
mkdir -p "$subm/claude/skills/x"
git init -q "$subm"
git init -q "$subm/claude/skills/x"
printf 'a%sb\n' "$(u 200B)" > "$subm/claude/skills/x/SKILL.md"
git -C "$subm/claude/skills/x" add SKILL.md
git -C "$subm/claude/skills/x" -c user.email=t@example.com -c user.name=t -c commit.gpgsign=false commit -qm x
git -C "$subm" add claude/skills/x 2>/dev/null
assert "$(git -C "$subm" ls-files -s claude/skills/x | cut -c1-6)" 160000 "the fixture is a gitlink"
run_in "$subm"
assert "$rc|$out" "1|claude/skills/x/SKILL.md:1: U+200B ZERO WIDTH SPACE" "worktree: a submodule's files are scanned"
run_in "$subm" --cached
assert "$rc|$out" "1|claude/skills/x/SKILL.md:1: U+200B ZERO WIDTH SPACE" "--cached: a submodule's files are scanned from disk"

# A directory link back to its own parent is walked once, not until the path is too long; a checkout's .git is skipped.
loop="$workdir/loop"
mkdir -p "$loop/claude" "$loop/co"
git init -q "$loop"
printf 'a%sb\n' "$(u 200B)" > "$loop/claude/x.md"
ln -s . "$loop/claude/self"
git init -q "$loop/co"
printf 'clean\n' > "$loop/co/f.md"
git -C "$loop/co" add f.md
ln -s ../co "$loop/claude/co"
git -C "$loop" add claude/x.md claude/self claude/co
run_in "$loop"
assert "$rc|$(echo "$out" | LC_ALL=C sort)" "1|claude/self/x.md:1: U+200B ZERO WIDTH SPACE
claude/x.md:1: U+200B ZERO WIDTH SPACE" "worktree: a link to its own directory is walked once; a linked checkout's .git is skipped"

# As root, which reads anything, a named unreadable file is checked as another user where one can be switched to.
if [[ "$(id -u)" == 0 ]] && command -v runuser >/dev/null && id nobody >/dev/null 2>&1; then
  ro="$(mktemp -d /tmp/chu-ro.XXXXXX)"
  chmod 755 "$ro"
  cp "$CHECKER" "$ro/checker"
  chmod 755 "$ro/checker"
  printf 'x\n' > "$ro/locked.md"
  chmod 000 "$ro/locked.md"
  (cd "$ro" && runuser -u nobody -- bash ./checker locked.md) >"$workdir/ro.out" 2>&1 && rc=0 || rc=$?
  assert "$rc|$(grep -c 'locked.md: cannot read' "$workdir/ro.out")" "2|1" "as another user: an unreadable named file exits 2"
  rm -rf "$ro"
fi

# An unreadable file fails the run, in the default set too; root reads it anyway, so not as root.
if [[ "$(id -u)" != 0 ]]; then
  printf 'a%sb\n' "$(u 200B)" > "$loop/claude/locked.md"
  git -C "$loop" add claude/locked.md
  chmod 000 "$loop/claude/locked.md"
  run_in "$loop"
  assert "$rc|$(echo "$err" | grep -c 'claude/locked.md: cannot read')" "2|1" "an unreadable file in the default set: exit 2"
  chmod 644 "$loop/claude/locked.md"
  git -C "$loop" rm -q --cached claude/locked.md
  mkdir -p "$loop/shut"
  ln -s ../shut "$loop/claude/shut"
  git -C "$loop" add claude/shut
  chmod 000 "$loop/shut"
  run_in "$loop"
    # Reached first through claude/self, the walk names it there.
  assert "$rc|$(echo "$err" | grep -c 'shut: cannot read')" "2|1" "an unreadable linked directory: exit 2"
  run_in "$loop" --cached
  assert "$rc|$(echo "$err" | grep -c 'shut: cannot read')" "2|1" "--cached: an unreadable linked directory on disk: exit 2"
  chmod 755 "$loop/shut"
fi

# A name ending in a CR, which cat-file would strip from its spec.
crrepo="$workdir/cr"
mkdir -p "$crrepo/claude"
git init -q "$crrepo"
printf 'a%sb\n' "$(u 200B)" > "$crrepo/claude/evil.md"$'\r'
printf 'clean\n' > "$crrepo/claude/evil.md"
git -C "$crrepo" add claude
run_in "$crrepo" --cached
assert "$rc|$(echo "$out" | grep -c 'U+200B')" "1|1" "--cached: a name ending in a CR is read by object id, not as its CR-less neighbour"

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

# Started by bash 3.2 it re-execs: a copy with a bash 4 construct after the guard still runs.
if [[ -x /bin/bash && "$(/bin/bash -c 'echo "${BASH_VERSINFO[0]}"')" == 3 ]]; then
  sed 's/^set -euo pipefail$/set -euo pipefail; declare -A needs_bash4=([x]=1)/' "$CHECKER" > "$workdir/bash4"
  assert "$(grep -c 'declare -A needs_bash4' "$workdir/bash4")" 1 "the bash 4 probe is in the copy"
  printf 'a%sb\n' "$(u 200B)" > "$workdir/b4.md"
  /bin/bash "$workdir/bash4" "$workdir/b4.md" >/dev/null 2>"$workdir/b4.err" && rc=0 || rc=$?
  assert "$rc|$(cat "$workdir/b4.err")" "1|check-hidden-unicode: delete each character named above; a NUL means the file isn't UTF-8 text (Tip 24.9)" \
    "started by bash 3.2: re-execs under bash 4"
fi

# Without bash 4 the guard exits 2, not 1, which would read as a hit.
if [[ -x /bin/bash && "$(/bin/bash -c 'echo "${BASH_VERSINFO[0]}"')" == 3 ]]; then
  sed 's#/opt/homebrew/bin/bash /usr/local/bin/bash#/nonexistent/bash#' "$CHECKER" > "$workdir/nobash"
  /bin/bash "$workdir/nobash" "$workdir/p" >"$workdir/nb.out" 2>&1 && rc=0 || rc=$?
  assert "$rc|$(head -1 "$workdir/nb.out")" "2|check-hidden-unicode: needs bash 4+; current: $(/bin/bash -c 'echo $BASH_VERSION')" \
    "no bash 4: exit 2 and says so"
fi

# hooks/pre-commit runs it through env bash, which is Apple's 3.2 on a Mac without Homebrew first on the PATH:
# it re-execs under Homebrew's bash.
if [[ -x /bin/bash && "$(/bin/bash -c 'echo "${BASH_VERSINFO[0]}"')" == 3 ]]; then
  (cd "$multi" && /bin/bash "$CHECKER" --cached c1 h1 c2 h2) >"$workdir/b3.out" 2>/dev/null && rc=0 || rc=$?
  assert "$rc|$(cat "$workdir/b3.out")" "1|$expected" "started by bash 3.2: --cached"
fi

# The workflow's pull-request step, its run block lifted out of the file: the base branch's copy of the script scans
# the tree where the base has one, and the pull request's own where it has none.
step="$workdir/step.sh"
awk '/- name: check-hidden-unicode/{f=1} f && /run: \|/{r=1; next} r && /^          /{sub(/^          /, ""); print; next} r{exit}' \
  "$ROOT/.github/workflows/hidden-unicode.yml" > "$step"
assert "$(grep -c 'FETCH_HEAD:bin/check-hidden-unicode' "$step")" 2 "the workflow's run block was lifted out"
origin="$workdir/origin.git"
git init -q --bare "$origin"
pr="$workdir/pr"
mkdir -p "$pr/bin"
git init -q "$pr"
printf '#!/bin/sh\necho base-copy\n' > "$pr/bin/check-hidden-unicode"
git -C "$pr" add bin/check-hidden-unicode
git -C "$pr" -c user.email=t@example.com -c user.name=t -c commit.gpgsign=false commit -qm base
git -C "$pr" push -q "$origin" HEAD:refs/heads/main
git -C "$pr" remote add origin "$origin"
printf '#!/bin/sh\necho pr-copy\n' > "$pr/bin/check-hidden-unicode"
# Under bash -e, as Actions runs a step.
function step() { (cd "$pr" && GITHUB_EVENT_NAME="$1" BASE_REF="$2" RUNNER_TEMP="$workdir" bash -e "$step") 2>/dev/null | tail -1; }
function step_rc() { (cd "$pr" && GITHUB_EVENT_NAME="$1" BASE_REF="$2" RUNNER_TEMP="$workdir" bash -e "$step") >/dev/null 2>&1; }
assert "$(step pull_request main)" base-copy "pull request: the base branch's copy runs"
assert "$(step push main)" pr-copy "push: the checked-out copy runs"
git -C "$pr" push -q "$origin" "$(git -C "$pr" -c user.email=t@example.com -c user.name=t -c commit.gpgsign=false commit-tree \
  "$(git -C "$pr" mktree < /dev/null)" -m empty):refs/heads/bare"
assert "$(step pull_request bare)" pr-copy "pull request into a base without the script: its own copy runs"
printf '#!/bin/sh\necho pr-copy\nexit 1\n' > "$pr/bin/check-hidden-unicode"
step_rc push main && rc=0 || rc=$?
assert "$rc" 1 "push: the scanner's exit 1 fails the step"
step_rc pull_request nosuchbranch && rc=0 || rc=$?
assert "$([[ $rc -ne 0 ]] && echo failed)" failed "pull request: a base that can't be fetched fails the step"

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
(cd "$hookrepo" && PATH="$workdir/badgit:$PATH" "$BASH" hooks/pre-commit) >"$workdir/h.out" 2>&1 && rc=0 || rc=$?
assert "$([[ $rc -ne 0 ]] && echo blocked)|$(grep -c 'the scan failed' "$workdir/h.out")" "blocked|1" \
  "hook: a scan that can't run blocks the commit too"

test_done
