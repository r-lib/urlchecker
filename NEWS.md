# urlchecker 2.0.0

* `url_check()` now ignores the same HTTP status codes that CRAN ignores in
  its incoming URL checks: 202, 401, 403, and 429. This makes results match
  what CRAN reports and avoids false positives from servers that return.
  Set the `_R_CHECK_URLS_HTTP_STATUS_IGNORE_REGEXP_` environment variable
  to override it.

* `url_check()` now sends the same browser-like `User-Agent` header that
  CRAN uses for its URL checks. Set the `_R_CHECK_URLS_CURL_USER_AGENT_`
  environment variable to override it (#26).

* `url_check()` no longer reports URLs that appear inside code chunks of
  `.Rmd` vignettes (#50).

* `url_check()` now reads an optional `.urlignore` file (from the project
  root or from `tools/`). URLs matching its glob patterns are skipped and
  never requested, which is useful for links to private repositories or
  pages behind a login or captcha (#45).

* The `url_check()` report no longer errors when a flagged URL is empty
  (e.g. a Markdown `[]()` link); the empty URL is now reported without a
  source-line pointer (#47).

* `url_check()` now checks URLs in BibTeX (`.bib`) bibliography files (#13).

* `url_check()` now finds a GitHub token in the git credential store (via
  gitcreds, as configured by usethis or gh), in addition to the `GITHUB_PAT`
  environment variable. This lets checks of `github.com` URLs avoid the
  `429: Too Many Requests` errors that anonymous requests hit (#28).

* `url_check()` gains a `fail` argument. When `TRUE` (the default) it throws
  an error after printing the report if any URLs are flagged, yielding a
  non-zero exit status for CI/CD workflows. Set `fail = FALSE` to return the
  results instead (#42).

* The `url_check()` report now prints the `file:line:col` location of each
  flagged URL as a clickable hyperlink, so you can jump straight to the
  problem in supporting IDEs and terminals (#23).

* `url_check()` now also works on non-package projects. `path` may be a
  directory that is not an R package (all supported files within are
  scanned), a single file, or a character vector mixing packages,
  directories and files. Supported file types are HTML, PDF, Rd, Markdown
  (`.md`, `.markdown`), R Markdown (`.Rmd`) and Quarto (`.qmd`).

* `url_check()` now also checks URLs in Quarto (`.qmd`) vignettes,
  rendering them with `quarto` (the un-evaluated document, in the same way
  `.Rmd` vignettes are rendered with pandoc).

* `url_check()` now errors if a `VignetteBuilder` package listed in the
  `DESCRIPTION` is not installed, as it is needed to render the vignettes
  for URL checking.

* `url_check()` now errors, instead of silently skipping the file, when
  pandoc (for `.md`/`.Rmd` files) or quarto (for `.qmd` files) is needed to
  render a file but cannot be found on the `PATH`.

* Handle URL fragments in redirects (#9).

* `url_check()` now also handles package tarballs. This is useful to check
  the URL in the package vignettes.

# urlchecker 1.0.1

* Gábor Csárdi is now the maintainer.

# urlchecker 1.0.0

* Added a `NEWS.md` file to track changes to the package.
