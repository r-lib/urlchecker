vlapply <- function(x, f, ...) vapply(x, f, logical(1))

# makes sure that pandoc is available
# puts RStudio's pandoc on the PATH if it is the only one available
with_pandoc_available <- function(code) {
  pandoc_location <- Sys.which("pandoc")
  if (!nzchar(pandoc_location)) {
    pandoc_path <- Sys.getenv("RSTUDIO_PANDOC")
    if (!nzchar(pandoc_path)) {
      stop("pandoc is not installed and on the PATH")
    } else {
      sys_path <- Sys.getenv("PATH")
      on.exit(Sys.setenv("PATH" = sys_path))
      Sys.setenv("PATH" = paste(pandoc_path, sys_path, sep = .Platform$path.sep))
    }
  }
  force(code)
}
