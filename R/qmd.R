url_db_from_package_qmd_vignettes <- function(dir) {
  urls <- path <- character()
  docs <- Filter(file.exists, tools::pkgVignettes(dir = dir)$docs)
  # Only qmd vignettes are rendered with quarto; Rmd vignettes go through pandoc
  # in `url_db_from_package_rmd_vignettes()`.
  qfiles <- grep("[.]qmd$", docs, value = TRUE)
  for (qfile in qfiles) {
    if (nzchar(Sys.which("quarto"))) {
      qpath <- asNamespace("tools")$.file_path_relative_to_dir(qfile, dir)
      # quarto writes supporting files (`*_files/`) next to the input, so render
      # a copy in a temp dir to keep the package sources clean; the HTML itself
      # is captured from stdout (see `.quarto_html_for_CRAN()`).
      tdir <- tempfile()
      dir.create(tdir)
      on.exit(unlink(tdir, recursive = TRUE), add = TRUE)
      tin <- file.path(tdir, basename(qfile))
      file.copy(qfile, tin)
      out <- .quarto_html_for_CRAN(tin)
      if (!out$status && length(out$stdout)) {
        tfile <- tempfile(fileext = ".html")
        on.exit(unlink(tfile), add = TRUE)
        writeLines(out$stdout, tfile)
        qurls <- tools$.get_urls_from_HTML_file(tfile)
        urls <- c(urls, qurls)
        path <- c(path, rep.int(qpath, length(qurls)))
      }
    }
  }
  tools$url_db(urls, path)
}

# Render a `.qmd` to HTML (on stdout) for URL extraction only: `--no-execute`
# skips running code chunks (we only need the prose and links), and the `from`
# metadata adds pandoc's autolink_bare_uris extension so bare URLs are turned
# into links too, matching `.pandoc_md_for_CRAN2()` in rmd.R. `--output -`
# writes the HTML to stdout so we never place a file in the package sources.
.quarto_html_for_CRAN <- function(ifile) {
  asNamespace("tools")$.system_with_capture(
    "quarto",
    paste(
      "render",
      shQuote(normalizePath(ifile)),
      "--no-execute",
      "--to",
      "html",
      "--metadata",
      shQuote("from:markdown+autolink_bare_uris"),
      "--output",
      "-"
    )
  )
}
