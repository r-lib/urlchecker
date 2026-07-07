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
