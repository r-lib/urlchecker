# urlchecker

<!-- badges: start -->
[![R-CMD-check](https://github.com/r-lib/urlchecker/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/r-lib/urlchecker/actions/workflows/R-CMD-check.yaml)
[![Codecov test coverage](https://codecov.io/gh/r-lib/urlchecker/graph/badge.svg)](https://app.codecov.io/gh/r-lib/urlchecker)
<!-- badges: end -->

The goal of urlchecker is to run the URL checks from R 4.1 in older versions of R and automatically update URLs as needed.

It also uses concurrent requests, so is generally much faster than the URL checks from the tools package.

## Installation

Install the released version from CRAN

```r
install.packages("urlchecker")
```

Or the development version from GitHub:

```r
# install.packages("pak")
pak::pak("r-lib/urlchecker")
```

## Usage

``` r
library(urlchecker)
```

```
# `url_check()` will check all URLs in a package, as is done by CRAN when
# submitting a package.
url_check("path/to/pkg")
```

```
# `url_update()` will check all URLs in a package, then update any 301
# redirects automatically to their new location.
url_update("path/to/pkg")
```

```
# You can also point `url_check()` at a built source package tarball. It is
# unpacked into a temporary directory and checked from there. Because the
# tarball contains the rendered vignettes, this also checks URLs in the
# built vignettes.
tarball <- pkgbuild::build("path/to/pkg")
url_check(tarball)
```

```
# `url_check()` also works on non-package projects: point it at a directory
# that is not a package (all supported files within are scanned), a single
# file, or a mix of directories and files. Supported files are HTML, PDF, Rd,
# Markdown (`.md`), R Markdown (`.Rmd`) and Quarto (`.qmd`).
url_check("path/to/project")
url_check(c("README.md", "docs"))
```

## Code of Conduct

Please note that the urlchecker project is released with a
[Contributor Code of Conduct](https://urlchecker.r-lib.org/CODE_OF_CONDUCT.html).
By contributing to this project, you agree to abide by its terms.
