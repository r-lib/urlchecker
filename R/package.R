#' Check urls in a package
#'
#' @param path Path to the package
#' @export
url_check <- function(path = ".") {
  db <- url_db_from_package_sources(path)
  res <- check_url_db(db)
  res$root <- normalizePath(path)
  res
}

#' Update URLs in a package
#'
#' @param path Path to the package
#' @param results results from [url_check].
#' @export
url_update <- function(path = ".", results = url_check(path)) {
  for (row in seq_len(NROW(results))) {
    old <- results[row, "URL"]
    new <- results[row, "New"]
    root <- results[row, "root"] %||% path
    if (nzchar(new)) {
      for (file in results[row, "From"]) {
        file_path <- file.path(root, file)
        data <- readLines(file_path)
        data <- gsub(old, new, data, fixed = TRUE)
        writeLines(data, file_path)
      }
    }
  }
}

`%||%` <- function(x, y) if (is.null(x)) y else x
