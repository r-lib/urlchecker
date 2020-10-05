curl_fetch_headers <- function(urls, pool = curl::new_pool(), progress = FALSE) {
  hs <- vector("list", length(urls))

  done <- 0L
  n <- length(urls)
  digits <- trunc(log10(n)) + 1L
  fmt <- paste0("\r[ %", digits, "i / %", digits, "i ]")
  if (progress) cat(sprintf(fmt, done, n), sep = "")
  for (i in seq_along(hs)) {
    h <- curl::new_handle(url = urls[[i]])
    curl::handle_setopt(h, nobody = TRUE)
    handle_result <- local({
      i <- i
      function(x) {
        hs[[i]] <<- x
        done <<- done + 1L
        if (progress) cat(sprintf(fmt, done, n), sep = "")
      }
    })
    handle_error <- local({
      i <- i
      function(x) {
        hs[[i]] <<- structure(list(message = x), class = c("curl_error", "error", "condition"))
        done <<- done + 1L
        if (progress) cat(sprintf(fmt, done, n), sep = "")
      }
    })
    curl::multi_add(h, done = handle_result, fail = handle_error, pool = pool)
  }
  curl::multi_run(pool = pool)
  if (progress) cat("\r", strrep(" ", nchar(fmt)), "\r", sep = "")

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
