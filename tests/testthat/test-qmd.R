# `url_db_from_package_qmd_vignettes()` renders un-evaluated Quarto (`.qmd`)
# vignettes with quarto and extracts their URLs. These tests need the quarto CLI
# on the PATH and the quarto package installed (so `tools::pkgVignettes()`
# recognises the vignette engine), but no network access.

test_that("url_db_from_package_qmd_vignettes() extracts URLs from vignettes", {
  skip_on_cran()
  skip_if_not(nzchar(Sys.which("quarto")), "quarto is not available")
  skip_if_not_installed("quarto")

  url <- "https://httpbin.org/status/200"
  root <- local_pkg(desc_url = "https://example.com", qmd_vignette_url = url)

  db <- asNamespace("urlchecker")$url_db_from_package_qmd_vignettes(
    normalizePath(root)
  )

  expect_equal(db$URL, url)
  expect_equal(db$Parent, "vignettes/v.qmd")
})

test_that("url_db_from_package_qmd_vignettes() is empty when there are no vignettes", {
  skip_on_cran()

  root <- local_pkg(desc_url = "https://example.com")

  db <- asNamespace("urlchecker")$url_db_from_package_qmd_vignettes(
    normalizePath(root)
  )

  expect_equal(NROW(db), 0)
})

test_that("urls_from_quarto_qmd_file() errors when quarto is not found", {
  urls_from_quarto_qmd_file <- asNamespace(
    "urlchecker"
  )$urls_from_quarto_qmd_file

  # Pretend quarto is not on the PATH.
  testthat::local_mocked_bindings(
    Sys.which = function(...) "",
    .package = "base"
  )

  expect_error(
    urls_from_quarto_qmd_file("vignette.qmd"),
    "quarto is required"
  )
})

test_that("urls_from_quarto_qmd_file() returns nothing when the render fails", {
  urls_from_quarto_qmd_file <- asNamespace(
    "urlchecker"
  )$urls_from_quarto_qmd_file

  qmd <- withr::local_tempfile(fileext = ".qmd")
  writeLines("See <https://example.com>.", qmd)

  # Pretend quarto is available so we get past the guard, then make the render
  # itself fail (non-zero status, no stdout).
  testthat::local_mocked_bindings(
    Sys.which = function(...) "/usr/bin/quarto",
    .package = "base"
  )
  testthat::local_mocked_bindings(
    .quarto_html_for_CRAN = function(ifile) {
      list(status = 1L, stdout = character())
    }
  )

  expect_equal(urls_from_quarto_qmd_file(qmd), character())
})
