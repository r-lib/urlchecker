# CLAUDE.md

Guidance for working in this repository.

## What this package does

`urlchecker` backports CRAN’s URL-checking tools (from R 4.1+) so they
run on older R, and adds concurrent (parallel) requests for speed.
Public API:
[`url_check()`](https://urlchecker.r-lib.org/dev/reference/url_check.md)
and
[`url_update()`](https://urlchecker.r-lib.org/dev/reference/url_update.md).

## Architecture

The core URL-checking logic is **not written here** — it is a verbatim
copy of R’s `tools` package code, embedded at
[inst/tools/urltools.R](https://urlchecker.r-lib.org/dev/inst/tools/urltools.R).

- [R/zzz.R](https://urlchecker.r-lib.org/dev/R/zzz.R) `.onLoad()`
  sources `urltools.R` into an environment `tools` whose parent is
  `asNamespace("tools")`. Unqualified calls in the embedded code resolve
  first against the embedded functions, then fall through to the
  installed `tools` namespace. This lets the embedded copy shadow the
  installed one while still reusing stable internal `tools` helpers
  (e.g. `config_val_to_logical`, `.file_path_relative_to_dir`,
  `table_of_HTTP_status_codes`).
- The package’s own code wraps that embedded logic:
  - [R/url_check.R](https://urlchecker.r-lib.org/dev/R/url_check.R) —
    [`url_check()`](https://urlchecker.r-lib.org/dev/reference/url_check.md),
    plus the custom `print.urlchecker_db` that renders `file:line:col`
    pointers under each flagged URL.
  - [R/rmd.R](https://urlchecker.r-lib.org/dev/R/rmd.R) — checks URLs in
    un-rendered Rmd vignettes (needs pandoc).
  - [R/url_update.R](https://urlchecker.r-lib.org/dev/R/url_update.R) —
    rewrites permanently-redirected (301) URLs in place.
  - [R/utils.R](https://urlchecker.r-lib.org/dev/R/utils.R) —
    `with_pandoc_available()` and `update_urltools()` (see below).
- [inst/tools/utils.R](https://urlchecker.r-lib.org/dev/inst/tools/utils.R)
  is a **compatibility backport** (currently just `lines2str`), sourced
  into the `tools` env only when `getRversion() < "4.0.0"`. Since
  DESCRIPTION requires R \>= 4.1, this branch is effectively dead code
  today; keep it only for legacy. Air’s reformat suggestion for this
  file can be ignored — nothing loads it.

## Maintenance: refreshing the embedded base-R code

This is the main recurring task (see
[MAINTENANCE.md](https://urlchecker.r-lib.org/dev/MAINTENANCE.md)).

1.  Overwrite
    [inst/tools/urltools.R](https://urlchecker.r-lib.org/dev/inst/tools/urltools.R)
    **verbatim** from upstream R’s `src/library/tools/R/urltools.R`
    (local checkout, or `update_urltools()` which pulls the
    `wch/r-source` trunk mirror). Do not hand-edit — the file is a
    faithful mirror. The one historical local patch (“Fix fragments”,
    issue \#9) is now upstream.
2.  If the new code calls an internal `tools` function not present in
    supported R versions, backport its definition into
    [inst/tools/utils.R](https://urlchecker.r-lib.org/dev/inst/tools/utils.R)
    (the `lines2str` precedent).
3.  Keep this file OUT of Air formatting — it must stay in upstream
    R-Core style so future refreshes are clean diffs. This is enforced
    by the `[format] exclude` entry in
    [air.toml](https://urlchecker.r-lib.org/dev/air.toml). (Air’s
    `exclude` key lives under `[format]`, not top level; the IDE’s TOML
    schema may wrongly flag it, but Air itself honors it.)

## Dev workflow

- Load: `uncovr::reload()` (not
  [`pkgload::load_all()`](https://pkgload.r-lib.org/reference/load_all.html)).
- Tests: `uncovr::test()` — note there is currently **no** `tests/`
  suite.
- Real verification: run the actual pipeline, e.g.
  `uncovr::reload(); print(urlchecker::url_check("."))`. This needs
  pandoc on PATH and network access; it exercises URL extraction +
  parallel curl checks + the custom printer. A missing internal `tools`
  function shows up here as a `could not find function` error (→
  backport).
- Formatting: `air format .` (uses
  [air.toml](https://urlchecker.r-lib.org/dev/air.toml); leaves
  `urltools.R` untouched).
