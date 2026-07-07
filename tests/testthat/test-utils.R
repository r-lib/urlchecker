# `with_pandoc_available()` makes sure pandoc is reachable before running its
# argument, temporarily putting RStudio's bundled pandoc on the PATH if that is
# the only copy available.

with_pandoc_available <- asNamespace("urlchecker")$with_pandoc_available

test_that("with_pandoc_available() runs the code when pandoc is on the PATH", {
  skip_if_not(nzchar(Sys.which("pandoc")), "pandoc is not available")

  expect_equal(with_pandoc_available(42), 42)
})

test_that("with_pandoc_available() errors when pandoc cannot be found", {
  withr::local_envvar(c(PATH = "", RSTUDIO_PANDOC = ""))

  expect_error(
    with_pandoc_available(1),
    "pandoc is not installed"
  )
})

test_that("with_pandoc_available() falls back to RSTUDIO_PANDOC", {
  skip_if_not(nzchar(Sys.which("pandoc")), "pandoc is not available")

  pandoc_dir <- dirname(Sys.which("pandoc"))
  withr::local_envvar(c(PATH = "", RSTUDIO_PANDOC = pandoc_dir))

  # Inside the call, pandoc is reachable again because RSTUDIO_PANDOC was put
  # on the PATH.
  expect_true(with_pandoc_available(nzchar(Sys.which("pandoc"))))
})

test_that("update_urltools() writes the fetched source into inst/tools", {
  update_urltools <- asNamespace("urlchecker")$update_urltools

  root <- withr::local_tempdir()
  dir.create(file.path(root, "inst", "tools"), recursive = TRUE)
  withr::local_dir(root)

  # Stub the network read so the test is offline and does not touch the real
  # inst/tools/urltools.R in the source tree.
  fake <- c("# fetched upstream copy", "x <- 1")
  testthat::local_mocked_bindings(
    readLines = function(...) fake,
    .package = "base"
  )

  update_urltools()

  expect_equal(readLines(file.path(root, "inst", "tools", "urltools.R")), fake)
})
