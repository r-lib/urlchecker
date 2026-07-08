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

test_that("url_check() extracts URLs from the package when db is NULL", {
  skip_on_cran()
  skip_if_not(nzchar(Sys.which("pandoc")), "pandoc is not available")
  skip_if_not_installed("knitr")

  web <- local_url_server()
  ok <- web$url("/ok")

  # Both the DESCRIPTION URL and the vignette URL resolve to the local server,
  # so extraction (sources + Rmd vignettes) followed by checking finds no
  # problems.
  root <- local_pkg(desc_url = ok, vignette_url = ok)

  res <- suppressMessages(url_check(root, progress = FALSE))

  expect_s3_class(res, "urlchecker_db")
  expect_equal(NROW(res), 0)
})

test_that("url_check() unpacks and checks a source package tarball", {
  skip_on_cran()
  skip_if_not(nzchar(Sys.which("pandoc")), "pandoc is not available")
  skip_if_not_installed("knitr")

  web <- local_url_server()
  ok <- web$url("/ok")
  bad <- web$url("/notfound")

  # The DESCRIPTION URL is fine; the vignette URL is broken, so the check on the
  # unpacked tarball should report exactly the vignette URL.
  root <- local_pkg(desc_url = ok, vignette_url = bad)
  tarball <- local_package_tarball(root)

  res <- suppressMessages(url_check(tarball, progress = FALSE))

  expect_s3_class(res, "urlchecker_db")
  expect_equal(res$URL, bad)
  # `root` points into the extracted sources, so the sources are still readable.
  expect_true(file.exists(file.path(res$root[[1]], "DESCRIPTION")))
})

test_that("url_check() errors on a tarball that is not a package", {
  # A tarball with a single top-level directory but no DESCRIPTION.
  dir <- withr::local_tempdir()
  notpkg <- file.path(dir, "notpkg")
  dir.create(notpkg)
  writeLines("nothing to see here", file.path(notpkg, "hello.txt"))
  tarball <- file.path(dir, "notpkg.tar.gz")
  withr::with_dir(dir, utils::tar(tarball, "notpkg", compression = "gzip"))

  # The message reports the tarball path (temp dir, not under the working
  # directory); scrub its directory so the snapshot is reproducible.
  expect_snapshot(
    url_check(tarball),
    error = TRUE,
    transform = function(x) {
      gsub("Tarball '.*[/\\\\](notpkg.tar.gz)'", "Tarball '\\1'", x)
    }
  )
})

test_that("url_check() scans a non-package directory", {
  skip_on_cran()

  web <- local_url_server()
  ok <- web$url("/ok")
  bad <- web$url("/notfound")

  # A plain directory (no DESCRIPTION) holding an HTML file. HTML extraction
  # needs only xml2, no pandoc/quarto.
  skip_if_not_installed("xml2")
  root <- withr::local_tempdir()
  writeLines(
    sprintf(
      "<html><body><a href='%s'>ok</a><a href='%s'>bad</a></body></html>",
      ok,
      bad
    ),
    file.path(root, "page.html")
  )

  res <- suppressMessages(url_check(root, progress = FALSE))

  expect_s3_class(res, "urlchecker_db")
  expect_equal(res$URL, bad)
  expect_equal(res$From[[1]], "page.html")
})

test_that("url_check() checks a single file", {
  skip_on_cran()
  skip_if_not_installed("xml2")

  web <- local_url_server()
  bad <- web$url("/notfound")

  root <- withr::local_tempdir()
  file <- file.path(root, "page.html")
  writeLines(
    sprintf("<html><body><a href='%s'>bad</a></body></html>", bad),
    file
  )

  res <- suppressMessages(url_check(file, progress = FALSE))

  expect_equal(res$URL, bad)
  # The single-file root is the file's directory, so `From` is the basename.
  expect_equal(res$From[[1]], "page.html")
  expect_equal(res$root[[1]], normalizePath(root, winslash = "/"))
})

test_that("url_check() accepts a mix of files and directories", {
  skip_on_cran()
  skip_if_not_installed("xml2")

  web <- local_url_server()
  bad1 <- web$url("/notfound")

  root <- withr::local_tempdir()
  sub <- file.path(root, "docs")
  dir.create(sub)
  loose <- file.path(root, "loose.html")
  writeLines(
    sprintf("<html><body><a href='%s'>b</a></body></html>", bad1),
    loose
  )
  writeLines(
    sprintf("<html><body><a href='%s'>b</a></body></html>", bad1),
    file.path(sub, "nested.html")
  )

  res <- suppressMessages(url_check(c(loose, sub), progress = FALSE))

  # Same broken URL from both inputs; `From` lists both, relative to the common
  # root directory.
  expect_equal(res$URL, bad1)
  expect_setequal(res$From[[1]], c("loose.html", "docs/nested.html"))
  expect_equal(res$root[[1]], normalizePath(root, winslash = "/"))
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
