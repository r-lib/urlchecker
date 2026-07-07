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
  res <- url_check(root, db = db, progress = FALSE)

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
  res <- url_check(root, db = db, progress = FALSE)

  expect_snapshot(print(res), transform = scrub_urls)
})
