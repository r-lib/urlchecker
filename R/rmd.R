url_db_from_package_rmd_vignettes <- function(dir) {
    urls <- path <- character()
    rfiles <- Filter(file.exists, tools::pkgVignettes(dir = dir)$docs)
    for (rfile in rfiles) {
      if(!is.na(rfile) && nzchar(Sys.which("pandoc"))) {
        rpath <- asNamespace("tools")$.file_path_relative_to_dir(rfile, dir)
        tfile <- tempfile(fileext = ".html")
        on.exit(unlink(tfile), add = TRUE)
        out <- .pandoc_md_for_CRAN2(rfile, tfile)
        if(!out$status) {
          rurls <- tools$.get_urls_from_HTML_file(tfile)
          urls <- c(urls, rurls)
          path <- c(path, rep.int(rpath, length(rurls)))
        }
      }
    }
    tools$url_db(urls, path)
}

# adapted from https://github.com/wch/r-source/blob/58d223cf3eaa50ff8cfc2caf591d67350e549e4a/src/library/tools/R/utils.R#L1847-L1857
# Adding the autolink_bare_uris extension
.pandoc_md_for_CRAN2 <- function(ifile, ofile) {
    asNamespace("tools")$.system_with_capture("pandoc", paste(shQuote(normalizePath(ifile)),
        "-s", "--mathjax", "--email-obfuscation=references", "-f", "markdown+autolink_bare_uris",
        "-o", shQuote(ofile)))
}
