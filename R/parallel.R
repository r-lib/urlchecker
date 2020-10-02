curl_fetch_headers <- function(urls) {
  hs <- vector("list", length(urls))

  for (i in seq_along(hs)) {
    h <- curl::new_handle(url = urls[[i]])
    curl::handle_setopt(h, nobody = TRUE)
    handle_result <- local({
      i <- i
      function(x) {
        hs[[i]] <<- x
      }
    })
    curl::multi_add(h, done = handle_result)
  }
  curl::multi_run()
  #return (hs[[1]])

  out <- vector("list", length(hs))
  for (i in seq_along(out)) {
    n <- length(hs[[i]])
    out[[i]] <- strsplit(rawToChar(hs[[i]]$headers), "(?<=\r\n)", perl = TRUE)[[1]]
    attr(out[[i]], "status") <- hs[[i]]$status_code
  }
  out
}
