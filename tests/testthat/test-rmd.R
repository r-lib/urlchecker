# `url_db_from_package_rmd_vignettes()` renders un-evaluated Rmd vignettes with
# pandoc and extracts their URLs. These tests need pandoc (and knitr, to make
# `tools::pkgVignettes()` recognise the vignette engine) but no network access.

test_that("url_db_from_package_rmd_vignettes() extracts URLs from vignettes", {
  skip_on_cran()
  skip_if_not(nzchar(Sys.which("pandoc")), "pandoc is not available")
  skip_if_not_installed("knitr")

  url <- "https://httpbin.org/status/200"
  root <- local_pkg(desc_url = "https://example.com", vignette_url = url)

  db <- asNamespace("urlchecker")$url_db_from_package_rmd_vignettes(
    normalizePath(root)
  )

  expect_equal(db$URL, url)
  expect_equal(db$Parent, "vignettes/v.Rmd")
})

test_that("url_db_from_package_rmd_vignettes() is empty when there are no vignettes", {
  skip_on_cran()

  root <- local_pkg(desc_url = "https://example.com")

  db <- asNamespace("urlchecker")$url_db_from_package_rmd_vignettes(
    normalizePath(root)
  )

  expect_equal(NROW(db), 0)
})

test_that("urls_from_pandoc_md_file() errors when pandoc is not found", {
  urls_from_pandoc_md_file <- asNamespace("urlchecker")$urls_from_pandoc_md_file

  # Pretend pandoc is not on the PATH.
  testthat::local_mocked_bindings(
    Sys.which = function(...) "",
    .package = "base"
  )

  expect_error(
    urls_from_pandoc_md_file("vignette.Rmd"),
    "pandoc is required"
  )
})

test_that("urls_from_pandoc_md_file() returns nothing when the render fails", {
  urls_from_pandoc_md_file <- asNamespace("urlchecker")$urls_from_pandoc_md_file

  # Pretend pandoc is available so we get past the guard, then make the render
  # itself fail (non-zero status).
  testthat::local_mocked_bindings(
    Sys.which = function(...) "/usr/bin/pandoc",
    .package = "base"
  )
  testthat::local_mocked_bindings(
    .pandoc_md_for_CRAN2 = function(ifile, ofile) list(status = 1L)
  )

  expect_equal(urls_from_pandoc_md_file("vignette.Rmd"), character())
})
