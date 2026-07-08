read_urlignore <- function(root) {
  files <- file.path(root, c(".urlignore", file.path("tools", ".urlignore")))
  files <- files[file.exists(files)]
  patterns <- unlist(lapply(files, readLines, warn = FALSE), use.names = FALSE)
  patterns <- trimws(patterns)
  patterns[nzchar(patterns) & !startsWith(patterns, "#")]
}

filter_urlignore <- function(db, patterns) {
  if (length(patterns) == 0 || NROW(db) == 0) {
    return(db)
  }
  matched <- Reduce(
    `|`,
    lapply(patterns, function(p) grepl(utils::glob2rx(p), db$URL)),
    logical(NROW(db))
  )
  n <- sum(matched)
  if (n > 0) {
    cli::cli_alert_info("Ignoring {n} URL{?s} matching {.file .urlignore}.")
  }
  db[!matched, , drop = FALSE]
}
