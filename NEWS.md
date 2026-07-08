# urlchecker (development version)

* `url_check()` now errors if a `VignetteBuilder` package listed in the
  `DESCRIPTION` is not installed, as it is needed to render the vignettes
  for URL checking.

* Handle URL fragments in redirects (#9).

* `url_check()` now also handles package tarballs. This is useful to check
  the URL in the package vignettes.

# urlchecker 1.0.1

* Gábor Csárdi is now the maintainer.

# urlchecker 1.0.0

* Added a `NEWS.md` file to track changes to the package.
