#' Check urls in a package
#'
#' Runs the `url_db_from_package_source` function in the tools package along
#' with a function to check URLs in un-rendered Rmarkdown vignettes.
#'
#' @param path Path to the package
#' @param db A url database
#' @param parallel If `TRUE`, check the URLs in parallel
#' @param pool A multi handle created by [curl::new_pool()]. If `NULL` use a global pool.
#' @param progress Whether to show the progress bar for parallel checks
#' @return A `url_checker_db` object (invisibly). This is a `check_url_db` object
#'   with an added class with a custom print method.
#' @examples
#' \dontrun{
#' url_check("my_pkg")
#' }
#' @export
url_check <- function(path = ".", db = NULL, parallel = TRUE, pool = curl::new_pool(), progress = TRUE) {
  if (is.null(db)) {
    db <- with_pandoc_available(
      rbind(
        tools$url_db_from_package_sources(normalizePath(path)),
        url_db_from_package_rmd_vignettes(normalizePath(path))
      )
    )
  }

  res <- tools$check_url_db(db, parallel = parallel, pool = pool, verbose = progress)
  if (NROW(res) > 0) {
    res$root <- normalizePath(path)
  }
  class(res) <- c("urlchecker_db", class(res))
  res
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
      data <- readLines(file_path)
      match <- regexpr(url, data, fixed = TRUE)
      lines <- which(match != -1)
      starts <- match[match != -1]
      ends <- starts + attr(match, "match.length")[match != -1]
      for (i in seq_along(lines)) {
        pointer <- paste0(strrep(" ", starts[[i]] - 1), "^", strrep("~", ends[[i]] - starts[[i]] - 1))
        if (nzchar(new)) {
          fix_it <- paste0(strrep(" ", starts[[i]] - 1), new)
          cli::cli_alert_warning("
            {.strong Warning:} {file}:{lines[[i]]}:{starts[[i]]} {.emph Moved}
            {data[lines[[i]]]}
            {pointer}
            {fix_it}
            ")
        } else {
        cli::cli_alert_danger("
          {.strong Error:} {file}:{lines[[i]]}:{starts[[i]]} {.emph {status}: {message}}
          {data[lines[[i]]]}
          {pointer}
          ")
        }
      }
    }
  }

  invisible(x)
}

