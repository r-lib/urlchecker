#' Check urls in a package
#'
#' @param path Path to the package
#' @param db A url database
#' @param parallel If `TRUE`, check the URLs in parallel
#' @export
#' @examples
#' \dontrun{
#' url_check("my_pkg")
#' }
#'
url_check <- function(path = ".", db = NULL, parallel = TRUE) {
  if (is.null(db)) {
    db <- url_db_from_package_sources(path)
  }
  res <- check_url_db(db, parallel = parallel)
  if (NROW(res) > 0) {
    res$root <- normalizePath(path)
  }
  class(res) <- c("urlchecker_db", class(res))
  res
}

#' Update URLs in a package
#'
#' @param path Path to the package
#' @param results results from [url_check].
#' @return The results from `url_check(path)`, invisibly.
#' @export
#' @examples
#' \dontrun{
#' url_update("my_pkg")
#' }
#'
url_update <- function(path = ".", results = url_check(path)) {
  can_update <- vlapply(results[["New"]], nzchar)
  to_update <- results[can_update, ]
  for (row in seq_len(NROW(to_update))) {
    old <- to_update[row, "URL"]
    new <- to_update[row, "New"]
    root <- to_update[row, "root"]
    if (nzchar(new)) {
      for (file in to_update[row, "From"]) {
        file_path <- file.path(root, file)
        data <- readLines(file_path)
        data <- gsub(old, new, data, fixed = TRUE)
        writeLines(data, file_path)
        cli::cli_alert_success("{.strong Updated:} {.url {old}} to {.url {new}} in {.file {file}}")
      }
    }
  }

  print(results[!can_update, ])

  invisible(results)
}

#' @export
print.urlchecker_db <- function(x, ...) {
  for (row in seq_len(NROW(x))) {
    url <- x[row, "URL"]
    new <- x[row, "New"]
    status <- x[row, "Status"]
    message <- x[row, "Message"]
    root <- x[row, "root"]
    for (file in x[row, "From"]) {
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

vlapply <- function(x, f, ...) vapply(x, f, logical(1))
