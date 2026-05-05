<!-- DOCTOC SKIP -->

# Text Tools

Filter, search, and transform — `jq` for JSON, `fzf` for fuzzy filtering, `ag` for code search.

## Tip 11.1: jq — JSON Wrangling

Pipe JSON in, get fields/arrays/strings out.

```sh
echo '{"name":"foo","tags":["a","b"]}' | jq '.name'        # "foo"
echo '{"name":"foo","tags":["a","b"]}' | jq -r '.name'     # foo (raw, unquoted)
echo '[{"x":1},{"x":2}]'              | jq '.[].x'         # 1 \n 2
echo '[{"x":1},{"x":2}]'              | jq '.[] | select(.x > 1)'
```

Docs: <https://jqlang.org/manual/>

## Tip 11.2: fzf — Fuzzy Filtering

Pipe a list in, fuzzy-pick one, get it back on stdout. Shell integration adds keyboard shortcuts.

Shortcuts (after `eval "$(fzf --zsh)"` or equivalent):

```
Ctrl + R        Fuzzy-search shell history
Ctrl + T        Fuzzy-pick files into the command line
Alt  + C        Fuzzy-cd into a subdirectory
```

Pipe patterns:

```sh
git checkout "$(git branch | fzf)"                              # pick a branch
vim "$(fzf)"                                                    # open a file
git log --oneline | fzf --preview 'git show {1}'                # browse commits with preview
```

`Ctrl+R` alone replaces most uses of `history | grep`.

Docs: <https://github.com/junegunn/fzf>

## Tip 11.3: ag — The Silver Searcher

Fast recursive code search. Honours `.gitignore` by default.

```sh
ag pattern                          # search current dir
ag pattern path/to/dir              # scope to a path
ag -i pattern                       # force case-insensitive
ag --ignore '*.lock' pattern        # extra ignore
```

Cross-link: the repo's `dict` function (Tip 20.2) uses `ag` against the system dictionary.

Docs: <https://github.com/ggreer/the_silver_searcher>
