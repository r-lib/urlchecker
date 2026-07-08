# These tests talk only to a local webfakes server, so they need no internet
# access. Because the server runs on a random port, `.urlignore` patterns use a
# leading `*` (e.g. `*/notfound`) rather than a literal host:port.

test_that("url_check() skips URLs matching .urlignore", {
  skip_on_cran()

  web <- local_url_server()
  bad <- web$url("/notfound")
  db <- local_url_db(bad)

  root <- withr::local_tempdir()
  writeLines("*/notfound", file.path(root, ".urlignore"))

  # The ignored URL is dropped before checking, so nothing is flagged and the
  # default `fail = TRUE` does not error.
  res <- suppressMessages(url_check(root, db = db, progress = FALSE))

  expect_s3_class(res, "urlchecker_db")
  expect_equal(NROW(res), 0)
})

test_that("url_check() still flags URLs not matching .urlignore", {
  skip_on_cran()

  web <- local_url_server()
  bad <- web$url("/notfound")
  db <- local_url_db(bad)

  root <- withr::local_tempdir()
  writeLines("*/somethingelse", file.path(root, ".urlignore"))

  res <- suppressMessages(
    url_check(root, db = db, progress = FALSE, fail = FALSE)
  )

  expect_equal(res$URL, bad)
})

test_that("url_check() reads tools/.urlignore too", {
  skip_on_cran()

  web <- local_url_server()
  bad <- web$url("/notfound")
  db <- local_url_db(bad)

  root <- withr::local_tempdir()
  dir.create(file.path(root, "tools"))
  writeLines("*/notfound", file.path(root, "tools", ".urlignore"))

  res <- suppressMessages(url_check(root, db = db, progress = FALSE))

  expect_equal(NROW(res), 0)
})

test_that("url_check() ignores comments and blank lines in .urlignore", {
  skip_on_cran()

  web <- local_url_server()
  bad <- web$url("/notfound")
  db <- local_url_db(bad)

  root <- withr::local_tempdir()
  writeLines(
    c("# a comment", "", "  # indented comment", "*/notfound"),
    file.path(root, ".urlignore")
  )

  res <- suppressMessages(url_check(root, db = db, progress = FALSE))

  expect_equal(NROW(res), 0)
})

test_that("read_urlignore() combines both files and drops comments/blanks", {
  root <- withr::local_tempdir()
  dir.create(file.path(root, "tools"))
  writeLines(
    c("# comment", "", "  https://a.example/x  "),
    file.path(root, ".urlignore")
  )
  writeLines("https://b.example/*", file.path(root, "tools", ".urlignore"))

  expect_setequal(
    read_urlignore(root),
    c("https://a.example/x", "https://b.example/*")
  )
})

test_that("read_urlignore() returns character() when no file exists", {
  root <- withr::local_tempdir()
  expect_identical(read_urlignore(root), character())
})
