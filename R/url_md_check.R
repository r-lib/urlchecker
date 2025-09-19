#' Check URLs in MD files
#'
#' Checks URLs in markdown files.
#' @param path Path to markdown directory
#' @param recursive logical. Should the listing recurse into directories?
#' @inheritParams url_check
#' @examples
#' \dontrun{
#' url_md_check("path_to_md_files")
#' }
#' @export
url_md_check = function(
  path = ".",
  recursive = FALSE,
  parallel = TRUE,
  pool = curl::new_pool(),
  progress = TRUE
) {
  rfiles = list.files(path, pattern = "\\.md$", recursive = recursive)
  db = url_db_from_md_files(dir = path, rfiles = rfiles)
  url_check(path, db, parallel = parallel, pool = pool, progress = progress)
}
