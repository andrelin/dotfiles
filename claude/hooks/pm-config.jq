# Merge, validate and clamp the .claude-pm.json files for bin/pm; the one place that logic lives.
# Call: jq -n --arg level L --arg origin O --arg origin_kind K --argjson guard_files '[...]' -f pm-config.jq FILE... </dev/null
# Files come farthest first as absolute paths. Kept to jq 1.6 builtins and syntax (RHEL 9 ships 1.6).

def fail($f; $m): error($f + ": " + $m);
def need($f; $c; $m): if $c then . else fail($f; $m) end;
def isobj: type == "object";
def isstr: type == "string";
def inlist($l): . as $x | any($l[]; . == $x);
def dedup: reduce .[] as $x ([]; if any(.[]; . == $x) then . else . + [$x] end);

def tiernames: ["issue_create", "label", "comment", "close", "release_notes"];
def tierrank: if . == "off" then 0 elif . == "suggest" then 1 elif . == "draft" then 2 elif . == "auto" then 3 else null end;
def tiername: ["off", "suggest", "draft", "auto"][.];
def kinds: ["github", "gitlab", "forgejo", "jira", "linear", "local", "none"];
def codehost: . == "github" or . == "gitlab" or . == "forgejo";
def topkeys: ["tracker", "follow_ups", "tiers", "vocabulary", "limits", "schedule", "decisions_dir", "roadmap", "redact", "notes"];
def sections: {
  tracker: ["kind", "repo"],
  follow_ups: ["backlog", "in_flight"],
  tiers: tiernames,
  vocabulary: ["labels", "priority"],
  limits: ["max_writes_per_run", "footer"],
  roadmap: ["status"]
};
def reporegex: "^[A-Za-z0-9-]+(\\.[A-Za-z0-9-]+)+(:[0-9]+)?/[^/\\s]+(/[^/\\s]+)+$";
def scheduleregex: "^(weekdays|daily|(mon|tue|wed|thu|fri|sat|sun)(,(mon|tue|wed|thu|fri|sat|sun))*) ([01][0-9]|2[0-3]):[0-5][0-9]$";

# An unknown key is ignored, not an error: list it, then drop it.
def warns($f):
  . as $o
  | [ keys[] | select(inlist(topkeys) | not) | $f + ": unknown key " + . ]
    + [ (sections | keys[]) as $s
        | (sections | .[$s]) as $known
        | select($o[$s] | isobj)
        | ($o[$s] | keys[]) | select(inlist($known) | not)
        | $f + ": unknown key " + $s + "." + . ];

def strip:
  with_entries(select(.key | inlist(topkeys)))
  | reduce (sections | keys[]) as $s (.;
      if (.[$s] | isobj) then .[$s] |= with_entries(select(.key | inlist(sections | .[$s]))) else . end)
  | if (.follow_ups | isobj) and (.follow_ups | length) == 0 then del(.follow_ups) else . end;

def checktracker($f):
  need($f; isobj; "tracker must be an object")
  | need($f; has("kind") and (.kind | isstr) and (.kind | inlist(kinds));
      "tracker.kind must be one of " + (kinds | join(", ")))
  | need($f; (has("repo") | not) or (.repo | isstr); "tracker.repo must be a string")
  | need($f; (has("repo") | not) or (.kind | codehost | not) or (.repo | test(reporegex));
      "tracker.repo must be <host>/<path> with a dot in the host and at least two path segments, as in github.com/owner/name");

def checkfile($f):
  (if has("tracker") then .tracker |= checktracker($f) else . end)
  | (if has("tiers") then
       .tiers |= (need($f; isobj; "tiers must be an object")
         | reduce to_entries[] as $e (.;
             need($f; $e.value | tierrank != null; "tiers." + $e.key + " must be one of off, suggest, draft, auto")))
     else . end)
  | (if has("vocabulary") then
       .vocabulary |= (need($f; isobj; "vocabulary must be an object")
         | reduce to_entries[] as $e (.;
             need($f; ($e.value | type) == "array" and all($e.value[]; isstr);
               "vocabulary." + $e.key + " must be an array of strings")))
     else . end)
  | (if has("limits") then
       .limits |= (need($f; isobj; "limits must be an object")
         | (if has("max_writes_per_run") then
              need($f; (.max_writes_per_run | type) == "number" and .max_writes_per_run >= 0 and .max_writes_per_run == (.max_writes_per_run | floor);
                "limits.max_writes_per_run must be a non-negative integer")
            else . end)
         | (if has("footer") then need($f; .footer | isstr; "limits.footer must be a string") else . end))
     else . end)
  | (if has("schedule") then
       .schedule |= (need($f; isobj; "schedule must be an object")
         | reduce to_entries[] as $e (.;
             need($f; ($e.value | isstr) and ($e.value | test(scheduleregex));
               "schedule." + $e.key + " must be weekdays, daily or mon..sun[,mon..sun] followed by HH:MM")))
     else . end)
  | (if has("redact") then
       .redact |= need($f; type == "array" and all(.[]; isstr and length > 0); "redact must be an array of non-empty strings")
     else . end)
  | (if has("decisions_dir") then need($f; (.decisions_dir | isstr) and (.decisions_dir | length > 0); "decisions_dir must be a non-empty string") else . end)
  | (if has("notes") then need($f; .notes | isstr; "notes must be a string") else . end)
  | (if has("roadmap") then
       .roadmap |= (need($f; isobj; "roadmap must be an object")
         | (if has("status") then need($f; .status | inlist(["derived", "labels", "project"]); "roadmap.status must be derived, labels or project") else . end))
     else . end)
  | (if has("follow_ups") then
       .follow_ups |= (need($f; (isstr and length > 0) or (isobj and all(.[]; isstr and length > 0));
         "follow_ups must be a non-empty string or an object of non-empty strings"))
     else . end);

def normpath:
  split("/")
  | reduce .[] as $s ([];
      if $s == "" or $s == "." then .
      elif $s == ".." then (if length > 0 then .[:-1] else . end)
      else . + [$s] end)
  | "/" + join("/");
def abspath($dir): if startswith("/") then normpath else ($dir + "/" + .) | normpath end;
def resolvefollow($f):
  ($f | sub("/[^/]*$"; "")) as $dir
  | if has("follow_ups") then
      .follow_ups |= (if isstr then abspath($dir) else map_values(abspath($dir)) end)
    else . end;

def ceilings($level):
  if $level == "customer" then {issue_create: 2, label: 2, comment: 2, close: 0, release_notes: 2}
  else {issue_create: 3, label: 3, comment: 3, close: 3, release_notes: 3} end;
def tierdefaults($level):
  if $level == "customer" then {issue_create: 0, label: 0, comment: 2, close: 0, release_notes: 2}
  else {issue_create: 3, label: 3, comment: 3, close: 3, release_notes: 3} end;

# --- arguments ---
if ($level | inlist(["", "personal", "company", "customer"])) | not then error("pm-config: level must be personal, company, customer or empty, got \"" + $level + "\"") else . end
| if ($origin_kind | inlist(["github", "gitlab", "forgejo", "none"])) | not then error("pm-config: origin_kind must be github, gitlab, forgejo or none, got \"" + $origin_kind + "\"") else . end
| if ($guard_files | type) == "array" and all($guard_files[]; isstr) then . else error("pm-config: guard_files must be a JSON array of strings") end
| if ($origin | isstr | not) then error("pm-config: origin must be a string") else . end
| if ($origin_kind | codehost) and $origin != "" and ($origin | test(reporegex) | not) then
    error("pm-config: origin " + $origin + ": must be <host>/<path> with a dot in the host and at least two path segments")
  else . end

# --- read: one value per file ---
| [inputs | {f: input_filename, v: .}] as $vals
| (reduce $vals[] as $e ({prev: null, files: []};
    if $e.f == .prev then fail($e.f; "holds more than one JSON value or is passed twice")
    else .prev = $e.f | .files += [$e.f] end) | .files) as $sources

# --- validate each file alone, then merge farthest first ---
| (reduce $vals[] as $e ({acc: {}, redact: [], tf: null, warnings: []};
    $e.f as $f
    | need($f; $f | startswith("/"); "config file paths must be absolute")
    | ($e.v | need($f; isobj; "must hold a JSON object")) as $v
    | ($v | warns($f)) as $w
    | ($v | strip | checkfile($f) | resolvefollow($f)) as $c
    | (if $level == "customer" and ($f | inlist($guard_files) | not) then $c | del(.tiers, .vocabulary, .tracker, .limits) else $c end) as $k
    | .warnings += $w
    | .redact = ((.redact + ($k.redact // [])) | dedup)
    | .tf = (if $k | has("tracker") then $f else .tf end)
    | .acc = (((.acc * ($k | del(.redact))) | if $k | has("tracker") then .tracker = $k.tracker else . end)))) as $m
| $m.acc as $a

# --- tracker ---
| (if $a | has("tracker") then
     ($a.tracker
      | if (.kind | codehost) and (has("repo") | not) then
          (if $origin_kind == .kind and $origin != "" then .repo = $origin
           else fail($m.tf; "tracker.repo is required for kind " + .kind + " and origin does not supply one") end)
        else . end
      | checktracker($m.tf)
      | if .kind == "none" or .kind == "local" then .repo = "" else . end
      | if has("repo") then . else .repo = "" end)
   elif ($origin_kind | codehost) and $origin != "" then {kind: $origin_kind, repo: $origin}
   else {kind: "none", repo: ""} end) as $tracker

# --- tiers: default, then clamp to the lower of the level and tracker-kind ceilings ---
| (if $level == "" or ($tracker.kind | codehost) then 3 else 2 end) as $tc
| ceilings($level) as $lc
| tierdefaults($level) as $td
| ($a.tiers // {}) as $asked
| [ tiernames[] as $t
    | (if $asked | has($t) then $asked[$t] | tierrank else null end) as $ar
    | ([$lc[$t], $tc] | min) as $ceil
    | {t: $t, ar: $ar, result: ([($ar // $td[$t]), $ceil] | min),
       reason: (if $level == "customer" and $lc[$t] <= $tc then "customer ceiling" else "tracker kind " + $tracker.kind end),
       over: ($ar != null and $ar > $ceil)} ] as $tl
| ($a.roadmap.status // "derived") as $rs
| (if $rs == "project" and $tracker.kind != "github" then "labels" else $rs end) as $rres

| {
    level: $level,
    sources: $sources,
    tracker: $tracker,
    tiers: ($tl | map({key: .t, value: (.result | tiername)}) | from_entries),
    vocabulary: ({labels: [], priority: []} * ($a.vocabulary // {})),
    limits: ({max_writes_per_run: 3, footer: "Drafted with Claude"} * ($a.limits // {})),
    schedule: ($a.schedule // {}),
    decisions_dir: ($a.decisions_dir // "docs/adr"),
    roadmap: {status: $rres},
    redact: $m.redact,
    adjustments:
      ([ $tl[] | select(.over) | "tiers." + .t + ": " + (.ar | tiername) + " -> " + (.result | tiername) + " (" + .reason + ")" ]
       + (if $rres != $rs then ["roadmap.status: " + $rs + " -> " + $rres + " (no projects on " + $tracker.kind + ")"] else [] end)),
    warnings: $m.warnings
  }
  + (if $a | has("follow_ups") then {follow_ups: $a.follow_ups} else {} end)
  + (if $a | has("notes") then {notes: $a.notes} else {} end)
