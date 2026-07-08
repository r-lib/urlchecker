# Check urls in a package

Runs the `url_db_from_package_source` function in the tools package
along with a function to check URLs in un-rendered Rmarkdown vignettes.

## Usage

``` r
url_check(
  path = ".",
  db = NULL,
  parallel = TRUE,
  pool = curl::new_pool(),
  progress = TRUE
)
```

## Arguments

- path:

  Path to the package. Most commonly this is a package's (development)
  source directory tree, but it may also be a directory holding an
  unpacked source package, or the path to a source package tarball
  (`.tar.gz`). A tarball is unpacked into a temporary directory (kept
  for the rest of the session, so the printed report can point into the
  sources).

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

## Value

A `url_checker_db` object (invisibly). This is a `check_url_db` object
with an added class with a custom print method.

## Examples

``` r
if (FALSE) { # \dontrun{
url_check("my_pkg")
} # }
```
