# File-extension based URL extraction for non-package projects: loose files and
# directories that are not R packages. `url_check()` uses the package-aware
# `tools$url_db_from_package_sources()` for packages, and these helpers for
# everything else.

# The document types we know how to extract URLs from, keyed by (lowercase)
# file extension. `DESCRIPTION`-style package metadata is intentionally not
# handled here: that is the package code path's job.
supported_extensions <- c(
  "html",
  "htm",
  "pdf",
  "rd",
  "md",
  "markdown",
  "rmd",
  "qmd",
  "bib"
)

# TRUE if `path` is a directory holding an R package (i.e. has a DESCRIPTION).
is_package_dir <- function(path) {
  dir.exists(path) && file.exists(file.path(path, "DESCRIPTION"))
}

# Extract URLs from a single file, dispatching on its extension. Rendering
# formats (md/Rmd/qmd) error when the required external tool (pandoc/quarto) is
# missing; HTML/PDF silently yield nothing when xml2/pdftohtml is missing.
urls_from_file <- function(file) {
  ext <- tolower(tools::file_ext(file))
  switch(
    ext,
    "html" = ,
    "htm" = tools$.get_urls_from_HTML_file(file),
    "pdf" = tools$.get_urls_from_PDF_file(file),
    "rd" = tools$.get_urls_from_Rd(tools::parse_Rd(file)),
    "md" = ,
    "markdown" = ,
    "rmd" = urls_from_pandoc_md_file(file),
    "qmd" = urls_from_quarto_qmd_file(file),
    "bib" = urls_from_bib_file(file),
    character()
  )
}

# Build a `url_db` from a single file. The `Parent` is the absolute file path;
# `url_check()` rebases parents to a common root for display.
url_db_from_file <- function(file) {
  file <- normalizePath(file, winslash = "/", mustWork = TRUE)
  urls <- urls_from_file(file)
  tools$url_db(urls, rep.int(file, length(urls)))
}

# Build a `url_db` from every supported file found (recursively) in a directory
# that is not an R package. Hidden directories (e.g. `.git`) are skipped by
# `list.files()`'s default `all.files = FALSE`. Parents are absolute paths.
url_db_from_dir <- function(dir) {
  dir <- normalizePath(dir, winslash = "/", mustWork = TRUE)
  pattern <- paste0(
    "[.](",
    paste(supported_extensions, collapse = "|"),
    ")$"
  )
  files <- list.files(
    dir,
    pattern = pattern,
    recursive = TRUE,
    full.names = TRUE,
    ignore.case = TRUE
  )
  if (!length(files)) {
    cli::cli_alert_info("No supported files in {.file {rel_path(dir)}}")
    return(tools$url_db(character(), character()))
  }
  cli::cli_alert_info("{length(files)} file{?s} in {.file {rel_path(dir)}}")
  dbs <- lapply(files, url_db_from_file)
  do.call(rbind, dbs)
}

# Longest common directory prefix of a set of absolute paths, used as the
# `root` that printed `From:` paths are shown relative to. Returns the
# filesystem root ("/") if there is no deeper common component.
common_dir <- function(paths) {
  parts <- strsplit(paths, .Platform$file.sep, fixed = TRUE)
  n <- min(lengths(parts))
  common <- character()
  for (i in seq_len(n)) {
    col <- vapply(parts, `[[`, "", i)
    if (length(unique(col)) == 1L) {
      common <- c(common, col[[1L]])
    } else {
      break
    }
  }
  root <- do.call(file.path, as.list(common))
  if (!nzchar(root)) .Platform$file.sep else root
}
