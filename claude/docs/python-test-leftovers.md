# Python test leftovers

What a Python test leaves open is freed by the garbage collector at some later moment, inside whichever test runs then.
Freeing it emits a `ResourceWarning` on stderr. A test that captures stderr and asserts it exactly
(`contextlib.redirect_stderr`, `assertEqual(err, …)`) then fails, in a file nobody touched, and only in the full suite:
a change elsewhere that shifts when the collector runs makes it appear or vanish.

## What leaks

- **`urllib.error.HTTPError` built with a body:** `HTTPError(url, 404, "gone", {}, io.BytesIO())` holds a file-like
  body; freeing it warns "Implicitly cleaning up <HTTPError 404: 'gone'>". Pass `fp=None` when the test doesn't read
  the body, or close it (`err.close()`) in a `finally`.
- **Files opened without a `with`:** `json.load(open(path))` warns "unclosed file". Use `with open(...)` or
  `Path.read_text()`.
- **`subprocess.Popen` left running or unwaited:** warns "subprocess N is still running". Kill and `wait()` it in a
  cleanup (`addCleanup(p.wait)` after `addCleanup(p.kill)`, so the kill runs first).

## Finding the source

- `python3 -W always::ResourceWarning -m unittest discover -s tests 2>&1 | grep -B3 ResourceWarning` lists every
  leak in the run, with the line that opened it where Python can tell.
- Add `-X tracemalloc` for the allocation traceback of each, at the cost of slower tests (a timing test may then fail).
- The test that fails is the victim, not the cause: match the leaked object's text (`<HTTPError 404: 'gone'>`) to the
  test that built it.

## Making a victim robust

A test that asserts captured stderr exactly can call `gc.collect()` just before it starts capturing, so others'
leftovers are freed outside its capture. Do that as well as fixing the leak, never instead: other leaks remain.
