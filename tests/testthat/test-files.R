# File-extension based URL extraction for non-package projects.

test_that("url_db_from_dir() reports when there are no supported files", {
  url_db_from_dir <- asNamespace("urlchecker")$url_db_from_dir

  dir <- withr::local_tempdir()
  # A file with an unsupported extension: nothing to extract URLs from.
  writeLines("nothing to see here", file.path(dir, "notes.txt"))

  expect_message(
    db <- url_db_from_dir(dir),
    "No supported files"
  )
  expect_equal(NROW(db), 0)
})
