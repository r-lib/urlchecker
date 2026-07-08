# `print.urlchecker_db()` emits its report via cli (to stderr); expect_snapshot()
# captures that. URLs are scrubbed of their random port via `scrub_urls`.

test_that("print() reports success when there are no problems", {
  skip_on_cran()

  web <- local_url_server()
  db <- local_url_db(web$url("/ok"))
  res <- url_check(tempdir(), db = db, progress = FALSE)

  expect_invisible(suppressMessages(print(res)))
  expect_snapshot(print(res), transform = scrub_urls)
})

test_that("print() points at the offending line for a broken URL", {
  skip_on_cran()

  web <- local_url_server()
  bad <- web$url("/notfound")

  root <- withr::local_tempdir()
  file <- "URLS.txt"
  writeLines(c("first line", paste("url:", bad)), file.path(root, file))

  db <- local_url_db(bad, parents = file)
  res <- url_check(root, db = db, progress = FALSE, fail = FALSE)

  expect_snapshot(print(res), transform = scrub_urls)
})

test_that("print() suggests a fix for a moved URL", {
  skip_on_cran()

  web <- local_url_server()
  moved <- web$url("/moved")

  root <- withr::local_tempdir()
  file <- "URLS.txt"
  writeLines(c("see", paste("  ", moved)), file.path(root, file))

  db <- local_url_db(moved, parents = file)
  res <- url_check(root, db = db, progress = FALSE, fail = FALSE)

  expect_snapshot(print(res), transform = scrub_urls)
})

test_that("print() handles an empty URL without erroring (#47)", {
  # An empty URL (e.g. Markdown `[]()`) is flagged as "Empty URL" but cannot be
  # located within the source, so it must print without a line pointer rather
  # than erroring in `strrep()`. Build the result object directly (no server).
  root <- withr::local_tempdir()
  file <- "NEWS.md"
  writeLines("[]()", file.path(root, file))

  res <- data.frame(
    URL = "",
    From = I(list(file)),
    Status = "",
    Message = "Empty URL",
    New = "",
    CRAN = "",
    root = root,
    stringsAsFactors = FALSE
  )
  class(res) <- c("urlchecker_db", "check_url_db", "data.frame")

  expect_snapshot(print(res))
})

test_that("print() flags a non-canonical CRAN URL", {
  # A CRAN URL that is not in canonical form is reported from the `CRAN` column
  # rather than from a live check, so this needs no server. Build the result
  # object directly.
  url <- "https://cran.r-project.org/package=foo"
  root <- withr::local_tempdir()
  file <- "DESCRIPTION"
  writeLines(c("line one", url), file.path(root, file))

  res <- data.frame(
    URL = url,
    From = I(list(file)),
    Status = "200",
    Message = "OK",
    New = "",
    CRAN = url,
    root = root,
    stringsAsFactors = FALSE
  )
  class(res) <- c("urlchecker_db", "check_url_db", "data.frame")

  expect_snapshot(print(res))
})
