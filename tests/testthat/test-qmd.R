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
