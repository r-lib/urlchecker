# urlchecker

The goal of urlchecker is to run the URL checks from R 4.1 in older
versions of R and automatically update URLs as needed.

It also uses concurrent requests, so is generally much faster than the
URL checks from the tools package.

## Installation

Install the released version from CRAN

``` r

install.packages("urlchecker")
```

Or the development version from GitHub:

``` r

# install.packages("pak")
pak::pak("r-lib/urlchecker")
```

## Usage

``` r

library(urlchecker)
```

    # `url_check()` will check all URLs in a package, as is done by CRAN when
    # submitting a package.
    url_check("path/to/pkg")

    # `url_update()` will check all URLs in a package, then update any 301
    # redirects automatically to their new location.
    url_update("path/to/pkg")

    # You can also point `url_check()` at a built source package tarball. It is
    # unpacked into a temporary directory and checked from there. Because the
    # tarball contains the rendered vignettes, this also checks URLs in the
    # built vignettes.
    tarball <- pkgbuild::build("path/to/pkg")
    url_check(tarball)

    # `url_check()` also works on non-package projects: point it at a directory
    # that is not a package (all supported files within are scanned), a single
    # file, or a mix of directories and files. Supported files are HTML, PDF, Rd,
    # Markdown (`.md`), R Markdown (`.Rmd`) and Quarto (`.qmd`).
    url_check("path/to/project")
    url_check(c("README.md", "docs"))

### Ignoring URLs

Some URLs cannot be checked automatically, e.g. a link to a private
repository, or a page behind a login or captcha. List them in a
`.urlignore` file (in the project root, or under `tools/`) to stop
[`url_check()`](https://urlchecker.r-lib.org/dev/reference/url_check.md)
from requesting and flagging them. Each line is a glob pattern:

    # Ignore everything under our private org, and one specific page.
    https://github.com/acme-private/*
    https://example.com/behind-a-login

Note that CRAN’s own URL checks do not read `.urlignore`, so an ignored
URL may still be flagged when the package is submitted to CRAN.

### Environment variables

[`url_check()`](https://urlchecker.r-lib.org/dev/reference/url_check.md)
mirrors CRAN’s incoming URL checks, which are controlled by a few
environment variables. urlchecker uses the same variables and defaults
to the same values CRAN uses, so results match what CRAN reports. Set a
variable yourself to override the default.

- `_R_CHECK_URLS_HTTP_STATUS_IGNORE_REGEXP_` — HTTP status codes to
  treat as OK rather than flag. Defaults to `"202|401|403|429"`
  (Accepted, Unauthorized, Forbidden, Too Many Requests), matching CRAN.

- `_R_CHECK_URLS_CURL_USER_AGENT_` — the `User-Agent` header sent with
  each request. Defaults to the browser-like string CRAN uses.

## Code of Conduct

Please note that the urlchecker project is released with a [Contributor
Code of Conduct](https://urlchecker.r-lib.org/CODE_OF_CONDUCT.html). By
contributing to this project, you agree to abide by its terms.
