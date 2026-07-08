#' Check urls in a package or project
#'
#' For an R package, runs the `url_db_from_package_source` function in the
#' tools package along with functions to check URLs in un-rendered Rmarkdown
#' (`.Rmd`) and Quarto (`.qmd`) vignettes and in BibTeX (`.bib`) bibliographies.
#' For non-package projects, URLs are extracted from all supported files found
#' in the given directories.
#'
#' @param path Path(s) to check. Each element may be:
#'   * A package's (development) source directory tree, a directory holding an
#'     unpacked source package, or a source package tarball (`.tar.gz`). A
#'     tarball is unpacked into a temporary directory (kept for the rest of the
#'     session, so the printed report can point into the sources).
#'   * A directory that is not an R package. All supported files found within
#'     (recursively) are scanned for URLs. Supported files are HTML, PDF, Rd,
#'     Markdown (`.md`, `.markdown`), R Markdown (`.Rmd`), Quarto (`.qmd`) and
#'     BibTeX (`.bib`).
#'   * A single file of one of the supported types above.
#'
#'   `path` may be a character vector mixing any of these.
#' @param db A url database
#' @param parallel If `TRUE`, check the URLs in parallel
#' @param pool A multi handle created by [curl::new_pool()]. If `NULL` use a global pool.
#' @param progress Whether to show the progress bar for parallel checks
#' @param fail If `TRUE` (the default), throw an error when one or more URLs
#'   are flagged, after printing the report. This yields a non-zero exit status,
#'   which is useful in CI/CD workflows. Set to `FALSE` to return the results
#'   instead of failing.
#' @return A `url_checker_db` object (invisibly). This is a `check_url_db` object
#'   with an added class with a custom print method.
#' @examples
#' \dontrun{
#' url_check("my_pkg")
#' url_check(c("README.md", "docs"))
#' }
#' @export
url_check <- function(
  path = ".",
  db = NULL,
  parallel = TRUE,
  pool = curl::new_pool(),
  progress = TRUE,
  fail = TRUE
) {
  check_character(path)
  check_data_frame(db, allow_null = TRUE)
  check_bool(parallel)
  check_bool(progress)
  check_bool(fail)

  opts <- options(timeout = 5)
  on.exit(options(opts), add = TRUE)

  ua <- Sys.getenv("_R_CHECK_URLS_CURL_USER_AGENT_", cran_user_agent)
  old_hdrs <- tools$.curl_handle_default_hdrs
  tools$.curl_handle_default_hdrs <- utils::modifyList(
    old_hdrs,
    list("User-Agent" = ua)
  )
  on.exit(tools$.curl_handle_default_hdrs <- old_hdrs, add = TRUE)

  if (is.null(db)) {
    path <- normalizePath(path, winslash = "/", mustWork = TRUE)
    required <- any(vlapply(
      path,
      function(p) is_package_tarball(p) || is_package_dir(p)
    ))
    db <- with_pandoc_available(build_url_db(path), required = required)
    root <- attr(db, "root")
  } else {
    root <- normalizePath(path, winslash = "/", mustWork = TRUE)
  }

  # For github.com rate-limits
  pat <- github_pat()
  if (nzchar(pat) && !nzchar(Sys.getenv("GITHUB_PAT", ""))) {
    Sys.setenv(GITHUB_PAT = pat)
    on.exit(Sys.unsetenv("GITHUB_PAT"), add = TRUE)
  }

  res <- tools$check_url_db(
    db,
    parallel = parallel,
    pool = pool,
    verbose = progress
  )
  if (NROW(res) > 0) {
    res$root <- root
  }
  class(res) <- c("urlchecker_db", class(res))

  if (fail && NROW(res) > 0) {
    print(res)
    n <- NROW(res)
    # Avoid "Run `rlang::last_trace()`", details are already printed
    stop(errorCondition(
      cli::format_error("Found {n} invalid URL{?s}."),
      class = "urlchecker_error"
    ))
  }

  res
}

# The User-Agent CRAN sets for its incoming URL checks (via
# `_R_CHECK_URLS_CURL_USER_AGENT_`). Kept in sync with CRAN's check scripts:
# https://github.com/r-devel/r-dev-web/blob/main/CRAN/QA/Kurt/lib/R/Scripts/check_CRAN_incoming.R
cran_user_agent <-
  "Mozilla/5.0 (X11; Linux x86_64; rv:140.0) Gecko/20100101 Firefox/140.0"


# Build a `url_db` from one or more paths (packages, directories or files),
# emitting a message for each. Parents are made relative to a common root
# directory, which is attached as the `"root"` attribute for the printer.
build_url_db <- function(paths) {
  dbs <- list()
  locations <- character()
  for (path in paths) {
    if (is_package_tarball(path)) {
      cli::cli_alert_info("Tarball {.file {rel_path(path)}}")
      pkgdir <- extract_package_tarball(path)
      dbs <- c(dbs, list(package_url_db(pkgdir)))
      locations <- c(locations, pkgdir)
    } else if (is_package_dir(path)) {
      name <- read.dcf(file.path(path, "DESCRIPTION"), fields = "Package")[1, 1]
      cli::cli_alert_info("Package {.pkg {name}}")
      dbs <- c(dbs, list(package_url_db(path)))
      locations <- c(locations, path)
    } else if (dir.exists(path)) {
      cli::cli_alert_info("Directory {.file {rel_path(path)}}")
      dbs <- c(dbs, list(url_db_from_dir(path)))
      locations <- c(locations, path)
    } else {
      cli::cli_alert_info("File {.file {rel_path(path)}}")
      dbs <- c(dbs, list(url_db_from_file(path)))
      locations <- c(locations, path)
    }
  }

  root <- if (length(locations) == 1L) {
    if (dir.exists(locations)) locations else dirname(locations)
  } else {
    common_dir(locations)
  }

  db <- do.call(rbind, dbs)
  if (NROW(db)) {
    db$Parent <- asNamespace("tools")$.file_path_relative_to_dir(
      db$Parent,
      root
    )
  }
  attr(db, "root") <- root
  db
}

# Build a `url_db` for an R package directory, combining the base-R package
# sources with the Rmd/qmd vignette checks. Parents are returned as absolute
# paths (they come back relative to `dir`) so `build_url_db()` can rebase them.
package_url_db <- function(dir) {
  check_vignette_builders(dir)
  db <- rbind(
    tools$url_db_from_package_sources(dir),
    url_db_from_package_rmd_vignettes(dir),
    url_db_from_package_qmd_vignettes(dir),
    url_db_from_package_bib_files(dir)
  )
  if (NROW(db)) {
    db$Parent <- file.path(dir, db$Parent)
  }
  db
}

#' @export
print.urlchecker_db <- function(x, ...) {
  if (NROW(x) == 0) {
    cli::cli_alert_success("All URLs are correct!")
    return(invisible(x))
  }

  for (row in seq_len(NROW(x))) {
    cran <- x[["CRAN"]][[row]]
    if (nzchar(cran)) {
      status <- "Error"
      message <- "CRAN URL not in canonical form"
      url <- cran
      new <- ""
    } else {
      status <- x[["Status"]][[row]]
      message <- x[["Message"]][[row]]
      url <- x[["URL"]][[row]]
      new <- x[["New"]][[row]]
    }
    root <- x[["root"]][[row]]
    from <- x[["From"]][[row]]

    for (file in from) {
      file_path <- file.path(root, file)

      # An empty URL (e.g. Markdown `[]()`) has no text to locate within the
      # file, so report it without a source-line pointer (#47).
      if (!nzchar(url)) {
        loc <- cli::style_hyperlink(
          text = file,
          url = paste0("file://", file_path)
        )
        detail <- if (nzchar(status)) paste0(status, ": ", message) else message
        cli::cli_alert_danger("{.strong Error:} {loc} {.emph {detail}}")
        next
      }

      data <- readLines(file_path)
      match <- regexpr(url, data, fixed = TRUE)
      lines <- which(match != -1)
      starts <- match[match != -1]
      ends <- starts + attr(match, "match.length")[match != -1]
      for (i in seq_along(lines)) {
        pointer <- paste0(
          strrep(" ", starts[[i]] - 1),
          "^",
          strrep("~", ends[[i]] - starts[[i]] - 1)
        )
        loc <- cli::style_hyperlink(
          text = paste0(file, ":", lines[[i]], ":", starts[[i]]),
          url = paste0("file://", file_path),
          params = c(line = lines[[i]], col = starts[[i]])
        )
        if (nzchar(new)) {
          fix_it <- paste0(strrep(" ", starts[[i]] - 1), new)
          cli::cli_alert_warning(
            "
            {.strong Warning:} {loc} {.emph Moved}
            {data[lines[[i]]]}
            {pointer}
            {fix_it}
            "
          )
        } else {
          cli::cli_alert_danger(
            "
          {.strong Error:} {loc} {.emph {status}: {message}}
          {data[lines[[i]]]}
          {pointer}
          "
          )
        }
      }
    }
  }

  invisible(x)
}
