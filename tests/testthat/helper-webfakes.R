# A tiny web app used to test URL checking without hitting the internet.
#
# Routes:
#   GET /ok        -> 200 OK
#   GET /notfound  -> 404 Not Found
#   GET /moved     -> 301 permanent redirect to /ok (absolute Location)
#   GET /found     -> 302 temporary redirect to /ok (absolute Location)
url_app <- function() {
  app <- webfakes::new_app()

  app$get("/ok", function(req, res) {
    res$send("OK")
  })

  app$get("/notfound", function(req, res) {
    res$set_status(404L)$send("Not Found")
  })

  # `url_check()` only reports a "New" URL for permanent (301) redirects, and
  # only when the `Location` is absolute (i.e. has a scheme), so build one from
  # the request's Host header.
  app$get("/moved", function(req, res) {
    loc <- paste0("http://", req$get_header("host"), "/ok")
    res$set_header("Location", loc)$set_status(301L)$send("Moved Permanently")
  })

  app$get("/found", function(req, res) {
    loc <- paste0("http://", req$get_header("host"), "/ok")
    res$set_header("Location", loc)$set_status(302L)$send("Found")
  })

  app
}

# Start the app in a background process, cleaned up when the calling frame
# (test or file) finishes.
local_url_server <- function(.local_envir = parent.frame()) {
  webfakes::local_app_process(
    url_app(),
    .local_envir = .local_envir
  )
}

# Snapshot transform: the server runs on a random port, and the `^~~~~` pointer
# under a URL is as long as the URL (so its length depends on the port's digit
# count). Replace the host:port with a stable placeholder and collapse the
# pointer tildes so snapshots are reproducible.
scrub_urls <- function(x) {
  x <- gsub("http://(127\\.0\\.0\\.1|localhost):[0-9]+", "http://{host}", x)
  gsub("~~+", "~~", x)
}

# Build a `url_db` (the input `url_check()` accepts via its `db` argument) from
# a named character vector, where names are the "parent" files the URLs come
# from.
local_url_db <- function(urls, parents = "URLS.txt") {
  urlchecker_tools <- asNamespace("urlchecker")$tools
  urlchecker_tools$url_db(unname(urls), rep_len(parents, length(urls)))
}
