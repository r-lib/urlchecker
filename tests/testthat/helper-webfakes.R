# A tiny web app used to test URL checking without hitting the internet.
#
# Routes:
#   GET  /ok       -> 200 OK
#   GET  /notfound -> 404 Not Found
#   GET  /moved    -> 301 permanent redirect to /ok (absolute Location)
#   GET  /found    -> 302 temporary redirect to /ok (absolute Location)
#   GET  /getonly  -> 200 OK, but HEAD /getonly -> 404 (see #15)
url_app <- function() {
  app <- webfakes::new_app()

  app$get("/ok", function(req, res) {
    res$send("OK")
  })

  app$get("/notfound", function(req, res) {
    res$set_status(404L)$send("Not Found")
  })

  # Some servers 404 (or otherwise fail) a HEAD request but serve the URL fine
  # on GET. The URL checker should fall back to GET when HEAD fails, so this
  # URL must not be flagged (#15).
  app$get("/getonly", function(req, res) {
    res$send("OK")
  })
  app$head("/getonly", function(req, res) {
    res$set_status(404L)$send("")
  })

  # `url_check()` only reports a "New" URL for permanent (301) redirects, and
  # only when the `Location` is absolute (i.e. has a scheme), so build one from
  # the request's Host header.
  app$get("/moved", function(req, res) {
    loc <- paste0("http://", req$get_header("host"), "/ok")
    res$set_header("Location", loc)$set_status(301L)$send("Moved Permanently")
  })

  app$get("/found", function(req, res) {
    loc <- paste0("http://", req$get_header("host"), "/ok")
    res$set_header("Location", loc)$set_status(302L)$send("Found")
  })

  app
}

# Start the app in a background process, cleaned up when the calling frame
# (test or file) finishes.
local_url_server <- function(.local_envir = parent.frame()) {
  webfakes::local_app_process(
    url_app(),
    .local_envir = .local_envir
  )
}

# Snapshot transform: the server runs on a random port, and the `^~~~~` pointer
# under a URL is as long as the URL (so its length depends on the port's digit
# count). Replace the host:port with a stable placeholder and collapse the
# pointer tildes so snapshots are reproducible.
scrub_urls <- function(x) {
  x <- gsub("http://(127\\.0\\.0\\.1|localhost):[0-9]+", "http://{host}", x)
  gsub("~~+", "~~", x)
}

# Build a `url_db` (the input `url_check()` accepts via its `db` argument) from
# a named character vector, where names are the "parent" files the URLs come
# from.
local_url_db <- function(urls, parents = "URLS.txt") {
  urlchecker_tools <- asNamespace("urlchecker")$tools
  urlchecker_tools$url_db(unname(urls), rep_len(parents, length(urls)))
}

# Write a minimal source package into a temporary directory so the extraction
# path of `url_check()` (`db = NULL`) can be exercised without a fixture on
# disk. `desc_url` goes in DESCRIPTION's `URL:` field; when `vignette_url` is
# supplied an Rmd vignette referencing it is added (this needs pandoc + knitr).
# Returns the package root, cleaned up when `.local_envir` finishes.
local_pkg <- function(
  desc_url,
  vignette_url = NULL,
  qmd_vignette_url = NULL,
  .local_envir = parent.frame()
) {
  root <- withr::local_tempdir(.local_envir = .local_envir)

  desc <- c(
    "Package: fake",
    "Title: A Fake Package",
    "Version: 0.0.1",
    "Description: A fake package for testing.",
    paste("URL:", desc_url)
  )
  builders <- c(
    if (!is.null(vignette_url)) "knitr",
    if (!is.null(qmd_vignette_url)) "quarto"
  )
  if (length(builders)) {
    suggests <- c(
      if (!is.null(vignette_url)) c("knitr", "rmarkdown"),
      if (!is.null(qmd_vignette_url)) "quarto"
    )
    desc <- c(
      desc,
      paste("VignetteBuilder:", paste(builders, collapse = ", ")),
      paste("Suggests:", paste(suggests, collapse = ", "))
    )
  }
  writeLines(desc, file.path(root, "DESCRIPTION"))

  if (!is.null(vignette_url) || !is.null(qmd_vignette_url)) {
    dir.create(file.path(root, "vignettes"))
  }

  if (!is.null(vignette_url)) {
    writeLines(
      c(
        "---",
        "title: v",
        "vignette: >",
        "  %\\VignetteEngine{knitr::rmarkdown}",
        "  %\\VignetteIndexEntry{v}",
        "---",
        "",
        paste0("See <", vignette_url, ">.")
      ),
      file.path(root, "vignettes", "v.Rmd")
    )
  }

  if (!is.null(qmd_vignette_url)) {
    writeLines(
      c(
        "---",
        "title: v",
        "vignette: >",
        "  %\\VignetteEngine{quarto::html}",
        "  %\\VignetteIndexEntry{v}",
        "---",
        "",
        paste0("See <", qmd_vignette_url, ">.")
      ),
      file.path(root, "vignettes", "v.qmd")
    )
  }

  root
}

# Build a source package tarball (`<pkg>_<version>.tar.gz`) from an unpacked
# package directory (e.g. one from `local_pkg()`), mirroring the single
# top-level directory layout of a real source tarball. Returns the tarball path,
# cleaned up when `.local_envir` finishes.
local_package_tarball <- function(root, .local_envir = parent.frame()) {
  dir <- withr::local_tempdir(.local_envir = .local_envir)
  pkg <- basename(root)
  tarball <- file.path(dir, paste0(pkg, ".tar.gz"))
  # Tar with the package directory as the single top-level entry.
  withr::with_dir(
    dirname(root),
    utils::tar(tarball, files = pkg, compression = "gzip")
  )
  normalizePath(tarball)
}
