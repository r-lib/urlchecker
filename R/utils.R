vlapply <- function(x, f, ...) vapply(x, f, logical(1))

# Path relative to the current working directory when it is below it,
# otherwise the path unchanged. Used to keep messages short.
rel_path <- function(path) {
  asNamespace("tools")$.file_path_relative_to_dir(path, getwd())
}

# TRUE if `path` looks like a source package tarball (a `.tar.gz` file).
is_package_tarball <- function(path) {
  !dir.exists(path) &&
    file.exists(path) &&
    grepl("\\.tar\\.gz$", path, ignore.case = TRUE)
}

# Unpack a source package tarball into a fresh temporary directory and return
# the path to the package root inside it. A source tarball holds the package in
# a single top-level directory (named after the package); we return that
# directory. The temp directory lives for the rest of the R session so callers
# (notably the `print.urlchecker_db` method) can still read the sources after
# `url_check()` has returned.
extract_package_tarball <- function(tarball) {
  exdir <- tempfile("urlchecker-")
  dir.create(exdir)
  utils::untar(tarball, exdir = exdir)

  contents <- list.files(exdir, full.names = TRUE)
  dirs <- contents[dir.exists(contents)]
  if (length(dirs) == 1 && file.exists(file.path(dirs, "DESCRIPTION"))) {
    normalizePath(dirs, winslash = "/")
  } else {
    cli::cli_abort(
      "Cannot determine package root in extracted tarball, no {.file DESCRIPTION} file found."
    )
  }
}

# makes sure that pandoc is available
# puts RStudio's pandoc on the PATH if it is the only one available
# When `required` is FALSE, a completely missing pandoc is tolerated (the
# callers that need it skip rendering gracefully); this is used for non-package
# paths, where pandoc may not be needed at all.
with_pandoc_available <- function(code, required = TRUE) {
  pandoc_location <- Sys.which("pandoc")
  if (!nzchar(pandoc_location)) {
    pandoc_path <- Sys.getenv("RSTUDIO_PANDOC")
    if (!nzchar(pandoc_path)) {
      if (required) {
        cli::cli_abort("{.pkg pandoc} is not installed and on the PATH.")
      }
    } else {
      sys_path <- Sys.getenv("PATH")
      on.exit(Sys.setenv("PATH" = sys_path))
      Sys.setenv(
        "PATH" = paste(pandoc_path, sys_path, sep = .Platform$path.sep)
      )
    }
  }
  force(code)
}


# Error if a VignetteBuilder package is not installed. We need it to
# render the un-built vignettes in `vignettes/` to extract their URLs. A
# built package already has them under `inst/doc`, so skip the check then.
check_vignette_builders <- function(path) {
  if (dir.exists(file.path(path, "inst", "doc"))) {
    cli::cli_alert_info(
      "Built vignettes found in {.path inst/doc}, using those; \\
       no VignetteBuilder needed."
    )
    return(invisible())
  }
  desc <- file.path(path, "DESCRIPTION")
  if (!file.exists(desc)) {
    return(invisible())
  }
  builders <- read.dcf(desc, fields = "VignetteBuilder")[1, 1]
  if (is.na(builders)) {
    return(invisible())
  }
  builders <- trimws(strsplit(builders, ",")[[1]])
  builders <- builders[nzchar(builders)]

  cli::cli_alert_info(
    "Checking that VignetteBuilder package{?s} {.pkg {builders}} \\
     {?is/are} installed."
  )
  # `system.file()` checks for the package without loading it.
  missing <- builders[
    !vlapply(builders, function(p) {
      nzchar(system.file(package = p))
    })
  ]
  if (length(missing)) {
    cli::cli_abort(c(
      "VignetteBuilder package{?s} {.pkg {missing}} {?is/are} not installed.",
      "i" = "{cli::qty(missing)}Install {?it/them} to check URLs in vignettes."
    ))
  }
  cli::cli_alert_success(
    "VignetteBuilder package{?s} {.pkg {builders}} {?is/are} installed."
  )
  invisible()
}


update_urltools <- function() {
  lines <- readLines(
    "https://raw.githubusercontent.com/wch/r-source/trunk/src/library/tools/R/urltools.R"
  )
  writeLines(lines, "inst/tools/urltools.R")
}
