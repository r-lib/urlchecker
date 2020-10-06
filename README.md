
# urlchecker

<!-- badges: start -->
[![R build status](https://github.com/jimhester/urlchecker/workflows/R-CMD-check/badge.svg)](https://github.com/jimhester/urlchecker/actions)
<!-- badges: end -->

The goal of urlchecker is to run the URL checks from R 4.1 in older versions of R and automatically update URLs as needed

``` r
library(urlchecker)

# Check all URLs in a package
url_check("path/to/pkg")

## Update any redirected URLs automatically
url_update("path/to/pkg")
```
