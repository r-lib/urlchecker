#' Update URLs in a package
#'
#' First uses [url_check] to check and then updates any URLs which are permanent (301)
#' redirects.
#'
#' @param path Path to the package
#' @param results results from [url_check].
#' @return The results from `url_check(path)`, invisibly.
#' @examples
#' \dontrun{
#' url_update("my_pkg")
#' }
#' @export
url_update <- function(path = ".", results = url_check(path)) {
  can_update <- vlapply(results[["New"]], nzchar)
  to_update <- results[can_update, ]
  for (row in seq_len(NROW(to_update))) {
    old <- to_update[["URL"]][[row]]
    new <- to_update[["New"]][[row]]
    root <- to_update[["root"]][[row]]
    if (nzchar(new)) {
      from <- to_update[["From"]][[row]]
      if (("README.md" %in% from) && file.exists("README.Rmd")) {
        from <- c(from, "README.Rmd")
      }
      for (file in from) {
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
