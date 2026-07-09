# Check urls in a package or project

For an R package, runs the `url_db_from_package_source` function in the
tools package along with functions to check URLs in un-rendered
Rmarkdown (`.Rmd`) and Quarto (`.qmd`) vignettes and in BibTeX (`.bib`)
bibliographies. For non-package projects, URLs are extracted from all
supported files found in the given directories.

## Usage

``` r
url_check(
  path = ".",
  db = NULL,
  parallel = TRUE,
  pool = curl::new_pool(),
  progress = TRUE,
  fail = TRUE
)
```

## Arguments

- path:

  Path(s) to check. Each element may be:

  - A package's (development) source directory tree, a directory holding
    an unpacked source package, or a source package tarball (`.tar.gz`).
    A tarball is unpacked into a temporary directory (kept for the rest
    of the session, so the printed report can point into the sources).

  - A directory that is not an R package. All supported files found
    within (recursively) are scanned for URLs. Supported files are HTML,
    PDF, Rd, Markdown (`.md`, `.markdown`), R Markdown (`.Rmd`), Quarto
    (`.qmd`) and BibTeX (`.bib`).

  - A single file of one of the supported types above.

  `path` may be a character vector mixing any of these.

- db:

  A url database

- parallel:

  If `TRUE`, check the URLs in parallel

- pool:

  A multi handle created by
  [`curl::new_pool()`](https://jeroen.r-universe.dev/curl/reference/multi.html).
  If `NULL` use a global pool.

- progress:

  Whether to show the progress bar for parallel checks

- fail:

  If `TRUE` (the default), throw an error when one or more URLs are
  flagged, after printing the report. This yields a non-zero exit
  status, which is useful in CI/CD workflows. Set to `FALSE` to return
  the results instead of failing.

## Value

A `url_checker_db` object (invisibly). This is a `check_url_db` object
with an added class with a custom print method.

## Ignoring URLs with `.urlignore`

Some URLs cannot be checked automatically, e.g. a link to a private
repository, or a page behind a login or captcha. To stop `url_check()`
from flagging (and even requesting) such URLs, list them in a
`.urlignore` file. It is read from two locations relative to the checked
root, and the patterns found are combined:

- `.urlignore` in the root directory (like `.gitignore`), and

- `tools/.urlignore` (handy for packages that keep it under `tools/`).

Each non-empty line is a glob pattern (blank lines and lines starting
with `#` are ignored), matched against the whole URL. For example
`https://github.com/acme/secret` matches that URL exactly, while
`https://github.com/acme/*` matches every URL under that path. Matching
URLs are dropped before checking, so they are never requested.

Note that CRAN's own URL checks do not read `.urlignore`, so an ignored
URL may still be flagged when the package is submitted to CRAN.

## Examples

``` r
if (FALSE) { # \dontrun{
url_check("my_pkg")
url_check(c("README.md", "docs"))
} # }
```
