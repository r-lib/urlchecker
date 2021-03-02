tools <- new.env(parent = asNamespace("tools"))

.onLoad <- function(...) {
  source(file = system.file(file.path("tools", "urltools.R"), package = "urlchecker"), local = tools)
}
