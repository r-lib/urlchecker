url_db_from_package_rmd_vignettes <-
function(dir)
{
    urls <- path <- character()
    rfiles <- Filter(file.exists, tools::pkgVignettes(dir = dir)$docs)
    for (rfile in rfiles) {
      if(!is.na(rfile) && nzchar(Sys.which("pandoc"))) {
        rpath <- asNamespace("tools")$.file_path_relative_to_dir(rfile, dir)
        tfile <- tempfile(fileext = ".html")
        on.exit(unlink(tfile), add = TRUE)
        out <- try(convert_markdown(rfile, tfile), silent = TRUE)

        if(!inherits(out, "try-error")) {
          rurls <- .get_urls_from_HTML_file(tfile)
          urls <- c(urls, rurls)
          path <- c(path, rep.int(rpath, length(rurls)))
        }
      }
    }
    url_db(urls, path)
}

convert_markdown <- function(infile, outfile) {
  input <- readLines(infile)
  output <- commonmark::markdown_html(input, extensions = TRUE)
  writeLines(output, outfile)
}
