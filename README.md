# urlchecker

<!-- badges: start -->
[![R build status](https://github.com/r-lib/urlchecker/workflows/R-CMD-check/badge.svg)](https://github.com/r-lib/urlchecker/actions)
[![Codecov test coverage](https://codecov.io/gh/jimhester/urlchecker/branch/main/graph/badge.svg)](https://app.codecov.io/gh/jimhester/urlchecker?branch=main)
[![R-CMD-check](https://github.com/r-lib/urlchecker/workflows/R-CMD-check/badge.svg)](https://github.com/r-lib/urlchecker/actions)
<!-- badges: end -->

The goal of urlchecker is to run the URL checks from R 4.1 in older versions of R and automatically update URLs as needed.

It also uses concurrent requests, so is generally much faster than the URL checks from the tools package.

``` r
library(urlchecker)

# `url_check()` will check all URLs in a package, as is done by CRAN when
# submitting a package.
url_check("path/to/pkg")

# `url_update()` will check all URLs in a package, then update any 301
# redirects automatically to their new location.
url_update("path/to/pkg")
```

## Code of Conduct

Please note that the urlchecker project is released with a 
[Contributor Code of Conduct](https://r-lib.github.io/urlchecker/CODE_OF_CONDUCT.html).
By contributing to this project, you agree to abide by its terms.
