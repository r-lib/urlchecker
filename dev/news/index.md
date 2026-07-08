# Changelog

## urlchecker (development version)

- The
  [`url_check()`](https://urlchecker.r-lib.org/dev/reference/url_check.md)
  report now prints the `file:line:col` location of each flagged URL as
  a clickable hyperlink, so you can jump straight to the problem in
  supporting IDEs and terminals
  ([\#23](https://github.com/r-lib/urlchecker/issues/23)).

- [`url_check()`](https://urlchecker.r-lib.org/dev/reference/url_check.md)
  now also works on non-package projects. `path` may be a directory that
  is not an R package (all supported files within are scanned), a single
  file, or a character vector mixing packages, directories and files.
  Supported file types are HTML, PDF, Rd, Markdown (`.md`, `.markdown`),
  R Markdown (`.Rmd`) and Quarto (`.qmd`).

- [`url_check()`](https://urlchecker.r-lib.org/dev/reference/url_check.md)
  now also checks URLs in Quarto (`.qmd`) vignettes, rendering them with
  `quarto` (the un-evaluated document, in the same way `.Rmd` vignettes
  are rendered with pandoc).

- [`url_check()`](https://urlchecker.r-lib.org/dev/reference/url_check.md)
  now errors if a `VignetteBuilder` package listed in the `DESCRIPTION`
  is not installed, as it is needed to render the vignettes for URL
  checking.

- Handle URL fragments in redirects
  ([\#9](https://github.com/r-lib/urlchecker/issues/9)).

- [`url_check()`](https://urlchecker.r-lib.org/dev/reference/url_check.md)
  now also handles package tarballs. This is useful to check the URL in
  the package vignettes.

## urlchecker 1.0.1

CRAN release: 2021-11-30

- Gábor Csárdi is now the maintainer.

## urlchecker 1.0.0

CRAN release: 2021-03-04

- Added a `NEWS.md` file to track changes to the package.
