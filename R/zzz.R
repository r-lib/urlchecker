tools <- new.env(parent = asNamespace("tools"))

.onLoad <- function(...) {
  source(file = system.file(file.path("tools", "urltools.R"), package = "urlchecker"), local = tools)
  if (getRversion() < "4.0.0") {
    source(file = system.file(file.path("tools", "utils.R"), package = "urlchecker"), local = tools)
  }
}
