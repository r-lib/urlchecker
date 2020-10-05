curl_fetch_headers <- function(urls, pool = curl::new_pool(), progress = FALSE) {
  hs <- vector("list", length(urls))

  bar <- progress_bar(if (progress) length(urls), msg = "fetching ")
  for (i in seq_along(hs)) {
    u <- urls[[i]]
    h <- curl::new_handle(url = u)
    curl::handle_setopt(h,
      nobody = TRUE,
      cookiesession = 1L,
      followlocation = 1L,
      http_version = 2L,
      ssl_enable_alpn = 0L)
    if (grepl("^https?://github[.]com", u) && nzchar(a <- Sys.getenv("GITHUB_PAT", ""))) {
      curl::handle_setheaders(h, "Authorization" = paste("token", a))
    }
    handle_result <- local({
      i <- i
      function(x) {
        hs[[i]] <<- x
        bar$update()
      }
    })
    handle_error <- local({
      i <- i
      function(x) {
        hs[[i]] <<- structure(list(message = x), class = c("curl_error", "error", "condition"))
        bar$update()
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

utils::globalVariables(c("done", "fmt"))

progress_bar <- function(length, msg = "") {
  bar <- new.env(parent = baseenv())
  if (is.null(length)) {
    length <- 0L
  }
  bar$length <- length
  bar$done <- -1L
  digits <- trunc(log10(length)) + 1L
  bar$fmt <- paste0("\r", msg, "[ %", digits, "i / %", digits, "i ]")
  bar$update <- function() {
    assign("done", inherits = TRUE, done + 1L)
    if (length <= 0L) {
      return()
    }
    if (done >= length) {
      cat("\r", strrep(" ", nchar(fmt)), "\r", sep = "")
    } else {
      cat(sprintf(fmt, done, length), sep = "")
    }
  }
  environment(bar$update) <- bar
  bar$update()
  bar
}
