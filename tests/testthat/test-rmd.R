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

test_that("url_db_from_package_rmd_vignettes() ignores code-chunk URLs (#50)", {
  skip_on_cran()
  skip_if_not(nzchar(Sys.which("pandoc")), "pandoc is not available")
  skip_if_not_installed("knitr")

  prose_url <- "https://httpbin.org/status/200"
  code_url <- "https://httpbin.org/status/404"
  root <- local_pkg(
    desc_url = "https://example.com",
    vignette_url = prose_url,
    vignette_code_url = code_url
  )

  db <- asNamespace("urlchecker")$url_db_from_package_rmd_vignettes(
    normalizePath(root)
  )

  # The prose URL is checked; the code-chunk URL is not.
  expect_equal(db$URL, prose_url)
})

test_that("rewrite_knitr_fences() normalises knitr chunk headers", {
  rewrite_knitr_fences <- asNamespace("urlchecker")$rewrite_knitr_fences

  in_file <- withr::local_tempfile(
    lines = c(
      "Prose <https://example.com/prose>.",
      "",
      "```{r eval = FALSE, purl = FALSE}",
      "x <- \"https://example.com/in-code\"",
      "```",
      "",
      "```{python}",
      "y = 1",
      "```",
      "",
      "```{.r .numberLines}",
      "kept as-is",
      "```"
    )
  )
  out <- readLines(rewrite_knitr_fences(in_file))

  # knitr chunk headers become plain fences; the closing fences and pandoc
  # attribute fences (leading `.`) are untouched.
  expect_equal(out[[3]], "```r")
  expect_equal(out[[7]], "```r")
  expect_equal(out[[11]], "```{.r .numberLines}")
  # Non-fence lines are preserved verbatim.
  expect_equal(out[[1]], "Prose <https://example.com/prose>.")
  expect_equal(out[[4]], "x <- \"https://example.com/in-code\"")
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
