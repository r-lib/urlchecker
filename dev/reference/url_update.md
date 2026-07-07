# Update URLs in a package

First uses
[url_check](https://urlchecker.r-lib.org/dev/reference/url_check.md) to
check and then updates any URLs which are permanent (301) redirects.

## Usage

``` r
url_update(path = ".", results = url_check(path))
```

## Arguments

- path:

  Path to the package

- results:

  results from
  [url_check](https://urlchecker.r-lib.org/dev/reference/url_check.md).

## Value

The results from `url_check(path)`, invisibly.

## Examples

``` r
if (FALSE) { # \dontrun{
url_update("my_pkg")
} # }
```
