curl_fetch_headers <- function(urls, pool = curl::new_pool()) {
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
    handle_error <- local({
      i <- i
      function(x) {
        hs[[i]] <<- structure(list(message = x), class = c("curl_error", "error", "condition"))
      }
    })
    curl::multi_add(h, done = handle_result, fail = handle_error, pool = pool)
  }
  curl::multi_run(pool = pool)

  out <- vector("list", length(hs))
  for (i in seq_along(out)) {
    if (inherits(hs[[i]], "error")) {
      out[[i]] <- hs[[i]]
    } else {
      out[[i]] <- strsplit(rawToChar(hs[[i]]$headers), "(?<=\r\n)", perl = TRUE)[[1]]
      attr(out[[i]], "status") <- hs[[i]]$status_code
    }
  }
  out
}
