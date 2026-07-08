url_db_from_package_rmd_vignettes <- function(dir) {
  dir <- normalizePath(dir, winslash = "/")
  urls <- path <- character()
  docs <- Filter(file.exists, tools::pkgVignettes(dir = dir)$docs)
  # Only Rmd vignettes are rendered with pandoc; qmd vignettes go through quarto
  # in `url_db_from_package_qmd_vignettes()`.
  rfiles <- grep("[.][Rr]md$", docs, value = TRUE)
  for (rfile in rfiles) {
    rpath <- asNamespace("tools")$.file_path_relative_to_dir(
      normalizePath(rfile, winslash = "/"),
      dir
    )
    rurls <- urls_from_pandoc_md_file(rfile)
    urls <- c(urls, rurls)
    path <- c(path, rep.int(rpath, length(rurls)))
  }
  tools$url_db(urls, path)
}

# Extract URLs from a Markdown-family file (`.md`, `.Rmd`) by rendering it to
# HTML with pandoc and scraping the links. Errors if pandoc is not available
# (it is required to render the file); returns `character()` if the render
# fails.
urls_from_pandoc_md_file <- function(file) {
  if (!nzchar(Sys.which("pandoc"))) {
    cli::cli_abort(c(
      "pandoc is required to check URLs in {.file {basename(file)}}, \\
       but it was not found.",
      "i" = "Install pandoc and make sure it is on the PATH."
    ))
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
  ifile <- rewrite_knitr_fences(ifile)
  on.exit(unlink(ifile), add = TRUE)
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

# Rewrite opening ```{r ...}`, etc. to ```r, so URLs are ignored in it.
rewrite_knitr_fences <- function(file) {
  lines <- readLines(file, warn = FALSE, encoding = "UTF-8")
  lines <- sub("^(\\s*`{3,})\\{[a-zA-Z][^}]*\\}[ \t]*$", "\\1r", lines)
  tfile <- tempfile(fileext = ".md")
  writeLines(lines, tfile, useBytes = TRUE)
  tfile
}
