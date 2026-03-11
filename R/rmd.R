url_db_from_package_rmd_vignettes <- function(dir) {
  urls <- path <- character()
  docs <- Filter(file.exists, tools::pkgVignettes(dir = dir)$docs)
  # Only Rmd vignettes are rendered with pandoc; qmd vignettes go through quarto
  # in `url_db_from_package_qmd_vignettes()`.
  rfiles <- grep("[.][Rr]md$", docs, value = TRUE)
  for (rfile in rfiles) {
    # normalizePath() so `rfile` and `dir` use the same separator
    rpath <- asNamespace("tools")$.file_path_relative_to_dir(
      normalizePath(rfile),
      dir
    )
    rurls <- urls_from_pandoc_md_file(rfile)
    urls <- c(urls, rurls)
    path <- c(path, rep.int(rpath, length(rurls)))
  }
  tools$url_db(urls, path)
}

# Extract URLs from a Markdown-family file (`.md`, `.Rmd`) by rendering it to
# HTML with pandoc and scraping the links. Returns `character()` if pandoc is
# not available or the render fails.
urls_from_pandoc_md_file <- function(file) {
  if (!nzchar(Sys.which("pandoc"))) {
    return(character())
  }
  tfile <- tempfile(fileext = ".html")
  on.exit(unlink(tfile), add = TRUE)
  out <- .pandoc_md_for_CRAN2(file, tfile)
  if (!out$status) {
    tools$.get_urls_from_HTML_file(tfile)
  } else {
    character()
  }
}

# adapted from https://github.com/wch/r-source/blob/58d223cf3eaa50ff8cfc2caf591d67350e549e4a/src/library/tools/R/utils.R#L1847-L1857
# Adding the autolink_bare_uris extension
.pandoc_md_for_CRAN2 <- function(ifile, ofile) {
  asNamespace("tools")$.system_with_capture(
    "pandoc",
    paste(
      shQuote(normalizePath(ifile)),
      "-s",
      "--mathjax",
      "--email-obfuscation=references",
      "-f",
      "markdown+autolink_bare_uris",
      "-o",
      shQuote(ofile)
    )
  )
}
