url_db_from_package_bib_files <- function(dir) {
  dir <- normalizePath(dir, winslash = "/")
  files <- list.files(
    file.path(dir, c("vignettes", "inst")),
    pattern = "[.]bib$",
    recursive = TRUE,
    full.names = TRUE,
    ignore.case = TRUE
  )
  urls <- path <- character()
  for (file in files) {
    rpath <- asNamespace("tools")$.file_path_relative_to_dir(
      normalizePath(file, winslash = "/"),
      dir
    )
    burls <- urls_from_bib_file(file)
    urls <- c(urls, burls)
    path <- c(path, rep.int(rpath, length(burls)))
  }
  tools$url_db(urls, path)
}

urls_from_bib_file <- function(file) {
  txt <- readLines(file, warn = FALSE)
  # Stop the match at whitespace, the field delimiters `{}` `"` `'`, and `<>`.
  # A trailing `}` (e.g. `\url{https://x.org}`) is thus excluded automatically.
  matches <- regmatches(
    txt,
    gregexpr("https?://[^[:space:]{}\"'<>]+", txt, perl = TRUE)
  )
  urls <- unlist(matches, use.names = FALSE)
  # Trim sentence punctuation that commonly abuts a URL; keep `/` and other
  # characters that can legitimately end a URL.
  urls <- sub("[.,;]+$", "", urls)
  unique(urls)
}
