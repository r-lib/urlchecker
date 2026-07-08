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

test_that("check_vignette_builders() errors on missing builder packages", {
  check_vignette_builders <- asNamespace("urlchecker")$check_vignette_builders

  root <- withr::local_tempdir()
  writeLines(
    c(
      "Package: fake",
      "Version: 0.0.1",
      "VignetteBuilder: knitr, thisPackageDoesNotExist"
    ),
    file.path(root, "DESCRIPTION")
  )

  expect_error(
    suppressMessages(check_vignette_builders(root)),
    "thisPackageDoesNotExist.*not installed"
  )
})

test_that("check_vignette_builders() passes when there is no VignetteBuilder", {
  check_vignette_builders <- asNamespace("urlchecker")$check_vignette_builders

  root <- withr::local_tempdir()
  writeLines(
    c("Package: fake", "Version: 0.0.1"),
    file.path(root, "DESCRIPTION")
  )

  expect_silent(check_vignette_builders(root))
})

test_that("check_vignette_builders() passes when there is no DESCRIPTION", {
  check_vignette_builders <- asNamespace("urlchecker")$check_vignette_builders

  root <- withr::local_tempdir()

  expect_silent(check_vignette_builders(root))
})

test_that("check_vignette_builders() passes for installed builders", {
  check_vignette_builders <- asNamespace("urlchecker")$check_vignette_builders

  root <- withr::local_tempdir()
  writeLines(
    c("Package: fake", "Version: 0.0.1", "VignetteBuilder: tools"),
    file.path(root, "DESCRIPTION")
  )

  expect_message(
    expect_message(
      check_vignette_builders(root),
      "Checking that VignetteBuilder"
    ),
    "installed"
  )
})

test_that("check_vignette_builders() skips built packages (inst/doc exists)", {
  check_vignette_builders <- asNamespace("urlchecker")$check_vignette_builders

  root <- withr::local_tempdir()
  writeLines(
    c(
      "Package: fake",
      "Version: 0.0.1",
      "VignetteBuilder: thisPackageDoesNotExist"
    ),
    file.path(root, "DESCRIPTION")
  )
  # Built vignettes live under inst/doc, so no builder is needed.
  dir.create(file.path(root, "inst", "doc"), recursive = TRUE)

  expect_message(
    check_vignette_builders(root),
    "Built vignettes found"
  )
})

test_that("github_pat() prefers the GITHUB_PAT environment variable", {
  github_pat <- asNamespace("urlchecker")$github_pat

  withr::local_envvar(GITHUB_PAT = "from-env")
  # gitcreds must not be consulted when the env var is set.
  testthat::local_mocked_bindings(
    gitcreds_get = function(...) stop("should not be called"),
    .package = "gitcreds"
  )

  expect_equal(github_pat(), "from-env")
})

test_that("github_pat() falls back to the git credential store", {
  github_pat <- asNamespace("urlchecker")$github_pat

  withr::local_envvar(GITHUB_PAT = NA)
  testthat::local_mocked_bindings(
    gitcreds_get = function(...) list(password = "from-gitcreds"),
    .package = "gitcreds"
  )

  expect_equal(github_pat(), "from-gitcreds")
})

test_that("github_pat() returns '' when no token is available", {
  github_pat <- asNamespace("urlchecker")$github_pat

  withr::local_envvar(GITHUB_PAT = NA)
  testthat::local_mocked_bindings(
    gitcreds_get = function(...) stop("no credentials"),
    .package = "gitcreds"
  )

  expect_equal(github_pat(), "")
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
