# These tests talk only to a local webfakes server, so they need no internet
# access. `url_update()` reports via cli; expect_snapshot() captures that, with
# the random port scrubbed via `scrub_urls`.

test_that("url_update() rewrites permanently moved URLs in the source", {
  skip_on_cran()

  web <- local_url_server()
  moved <- web$url("/moved")
  target <- web$url("/ok")

  # A minimal "package" directory containing a file that references the URL.
  root <- withr::local_tempdir()
  file <- "URLS.txt"
  writeLines(c("See here:", moved, "done."), file.path(root, file))

  db <- local_url_db(moved, parents = file)
  res <- url_check(root, db = db, progress = FALSE)

  expect_snapshot(url_update(root, results = res), transform = scrub_urls)

  updated <- readLines(file.path(root, file))
  expect_true(any(grepl(target, updated, fixed = TRUE)))
  expect_false(any(grepl(moved, updated, fixed = TRUE)))
})

test_that("url_update() also rewrites README.Rmd when updating README.md", {
  skip_on_cran()

  web <- local_url_server()
  moved <- web$url("/moved")
  target <- web$url("/ok")

  root <- withr::local_tempdir()
  writeLines(c("readme md", moved), file.path(root, "README.md"))
  writeLines(c("readme rmd", moved), file.path(root, "README.Rmd"))

  # `url_update()` looks for README.Rmd relative to the working directory.
  withr::local_dir(root)

  db <- local_url_db(moved, parents = "README.md")
  res <- url_check(root, db = db, progress = FALSE)

  expect_snapshot(url_update(root, results = res), transform = scrub_urls)

  # Both files were rewritten.
  for (file in c("README.md", "README.Rmd")) {
    updated <- readLines(file.path(root, file))
    expect_true(any(grepl(target, updated, fixed = TRUE)))
    expect_false(any(grepl(moved, updated, fixed = TRUE)))
  }
})

test_that("url_update() leaves plain errors untouched", {
  skip_on_cran()

  web <- local_url_server()
  bad <- web$url("/notfound")

  root <- withr::local_tempdir()
  file <- "URLS.txt"
  writeLines(bad, file.path(root, file))

  db <- local_url_db(bad, parents = file)
  res <- url_check(root, db = db, progress = FALSE)

  expect_snapshot(url_update(root, results = res), transform = scrub_urls)

  expect_equal(readLines(file.path(root, file)), bad)
})
