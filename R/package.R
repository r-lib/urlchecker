#' Check urls in a package
#'
#' @param path Path to the package
#' @export
url_check <- function(path = ".") {
  db <- url_db_from_package_sources(path)
  res <- check_url_db(db)
  if (NROW(res) > 0) {
    res$root <- normalizePath(path)
  }
  res
}

#' Update URLs in a package
#'
#' @param path Path to the package
#' @param results results from [url_check].
#' @return The results from `url_check(path)`, invisibly.
#' @export
url_update <- function(path = ".", results = url_check(path)) {
  can_update <- vlapply(results[["New"]], nzchar)
  to_update <- results[can_update, ]
  for (row in seq_len(NROW(to_update))) {
    old <- to_update[row, "URL"]
    new <- to_update[row, "New"]
    root <- to_update[row, "root"] %||% path
    if (nzchar(new)) {
      for (file in to_update[row, "From"]) {
        file_path <- file.path(root, file)
        data <- readLines(file_path)
        data <- gsub(old, new, data, fixed = TRUE)
        writeLines(data, file_path)
        cli::cli_alert_success("Updated {.url {old}} to {.url {new}} in {.file {file}}")
      }
    }
  }

  broken <- results[!can_update, ]

  for (row in seq_len(NROW(broken))) {
    url <- broken[row, "URL"]
    status <- broken[row, "Status"]
    message <- broken[row, "Message"]
    root <- broken[row, "root"] %||% path
    for (file in broken[row, "From"]) {
      file_path <- file.path(root, file)
      data <- readLines(file_path)
      match <- regexpr(url, data, fixed = TRUE)
      lines <- which(match != -1)
      starts <- match[match != -1]
      ends <- starts + attr(match, "match.length")[match != -1]
      for (i in seq_along(lines)) {
        pointer <- paste0(strrep(" ", starts[[i]] - 1), "^", strrep("~", ends[[i]] - starts[[i]] - 1))
        cli::cli_alert_danger("
          {.strong Error:} {file}:{lines[[i]]}:{starts[[i]]} {.emph {status}: {message}}
          {data[lines[[i]]]}
          {pointer}
          ")
      }
    }
  }
  invisible(results)
}

`%||%` <- function(x, y) if (is.null(x)) y else x
vlapply <- function(x, f, ...) vapply(x, f, logical(1))
