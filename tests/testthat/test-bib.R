test_that("urls_from_bib_file() extracts explicit http(s) URLs", {
  urls_from_bib_file <- asNamespace("urlchecker")$urls_from_bib_file

  file <- withr::local_tempfile()
  writeLines(
    c(
      "@article{wickham2019,",
      "  title = {Welcome to the {tidyverse}},",
      "  url = {https://example.com/joss},",
      "  note = {see \\url{https://example.org/path/}},",
      "  howpublished = {\\href{https://r-project.org}{R}},",
      "  abstract = {mentions http://bare.example.com, in prose.},",
      "}"
    ),
    file
  )

  expect_equal(
    urls_from_bib_file(file),
    c(
      "https://example.com/joss",
      "https://example.org/path/",
      "https://r-project.org",
      "http://bare.example.com"
    )
  )
})

test_that("urls_from_bib_file() skips bare DOIs and dedupes within a file", {
  urls_from_bib_file <- asNamespace("urlchecker")$urls_from_bib_file

  file <- withr::local_tempfile()
  writeLines(
    c(
      "@article{a,",
      "  doi = {10.21105/joss.01686},",
      "  url = {https://example.com/x},",
      "}",
      "@article{b,",
      "  url = {https://example.com/x},",
      "}"
    ),
    file
  )

  # The bare DOI is not turned into a URL, and the URL shared by both entries
  # appears only once.
  expect_equal(urls_from_bib_file(file), "https://example.com/x")
})

test_that("url_db_from_package_bib_files() scans vignettes/ and inst/", {
  url_db_from_package_bib_files <-
    asNamespace("urlchecker")$url_db_from_package_bib_files

  root <- withr::local_tempdir()
  dir.create(file.path(root, "vignettes"))
  dir.create(file.path(root, "inst"))
  writeLines(
    "@misc{a, url = {https://example.com/vignette}}",
    file.path(root, "vignettes", "paper.bib")
  )
  writeLines(
    "@misc{b, url = {https://example.com/refs}}",
    file.path(root, "inst", "REFERENCES.bib")
  )
  # A `.bib` outside the scanned directories is ignored.
  writeLines(
    "@misc{c, url = {https://example.com/ignored}}",
    file.path(root, "stray.bib")
  )

  db <- url_db_from_package_bib_files(normalizePath(root))

  expect_setequal(
    db$URL,
    c("https://example.com/vignette", "https://example.com/refs")
  )
  expect_setequal(
    db$Parent,
    c("vignettes/paper.bib", "inst/REFERENCES.bib")
  )
})

test_that("url_db_from_package_bib_files() is empty when there are no bib files", {
  url_db_from_package_bib_files <-
    asNamespace("urlchecker")$url_db_from_package_bib_files

  root <- withr::local_tempdir()

  db <- url_db_from_package_bib_files(normalizePath(root))
  expect_equal(NROW(db), 0)
})
