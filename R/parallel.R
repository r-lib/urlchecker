curl_fetch_headers <- function(urls) {
  hs <- vector("list", length(urls))

  for (i in seq_along(hs)) {
    h <- curl::new_handle(url = urls[[i]])
    curl::handle_setopt(h, nobody = TRUE, followlocation = 0L)
    handle_result <- local({
      i <- i
      function(x) {
      if (x$status_code >= 300L && x$status_code < 400L) {
        headers <- curl::parse_headers_list(x$headers)
        if (nzchar(headers$location)) {
          h <- curl::new_handle(url = headers$location)
          curl::handle_setopt(h, nobody = TRUE, followlocation = 0L)
          curl::multi_add(h, done = handle_result)
        }
      }
      hs[[i]] <<- append(hs[[i]], list(x))
      }
    })
    curl::multi_add(h, done = handle_result)
  }
  curl::multi_run()
  #return (hs[[1]])

  out <- vector("list", length(hs))
  for (i in seq_along(out)) {
    n <- length(hs[[i]])
    out[[i]] <- unlist(lapply(hs[[i]], function(x) strsplit(rawToChar(x$headers), "(?<=\r\n)", perl = TRUE)[[1]]))
    attr(out[[i]], "status") <- hs[[i]][[n]][["status_code"]]
  }
  out
}
