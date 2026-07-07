# These tests talk only to a local webfakes server, so they need no internet
# access.

test_that("url_check() reports nothing for a working URL", {
  skip_on_cran()

  web <- local_url_server()
  db <- local_url_db(web$url("/ok"))

  res <- url_check(tempdir(), db = db, progress = FALSE)

  expect_s3_class(res, "urlchecker_db")
  expect_equal(NROW(res), 0)
})

test_that("url_check() reports a broken (404) URL", {
  skip_on_cran()

  web <- local_url_server()
  bad <- web$url("/notfound")
  db <- local_url_db(bad)

  res <- url_check(tempdir(), db = db, progress = FALSE)

  expect_equal(NROW(res), 1)
  expect_equal(res$URL, bad)
  expect_equal(res$Status, "404")
  # Nothing to suggest for a plain 404.
  expect_equal(res$New, "")
})

test_that("url_check() suggests the new location for a 301 redirect", {
  skip_on_cran()

  web <- local_url_server()
  moved <- web$url("/moved")
  db <- local_url_db(moved)

  res <- url_check(tempdir(), db = db, progress = FALSE)

  expect_equal(NROW(res), 1)
  expect_equal(res$URL, moved)
  expect_equal(res$New, web$url("/ok"))
})

test_that("url_check() works serially and in parallel", {
  skip_on_cran()

  web <- local_url_server()
  db <- local_url_db(c(web$url("/ok"), web$url("/notfound")))

  serial <- url_check(tempdir(), db = db, parallel = FALSE, progress = FALSE)
  parallel <- url_check(tempdir(), db = db, parallel = TRUE, progress = FALSE)

  expect_equal(serial$URL, web$url("/notfound"))
  expect_equal(parallel$URL, web$url("/notfound"))
})
