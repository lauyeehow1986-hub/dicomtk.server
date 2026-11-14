`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

srv_check_scalar_chr <- function(x, arg = deparse(substitute(x))) {
  if (!is.character(x) || length(x) != 1L || is.na(x) || !nzchar(trimws(x))) {
    cli::cli_abort("{.arg {arg}} must be a single non-empty character string.")
  }
  x
}

srv_hash_hex <- function(txt) {
  s <- as.character(txt)[1L]
  if (requireNamespace("openssl", quietly = TRUE)) {
    return(as.character(openssl::sha256(s)))
  }
  rlang::hash(s)
}

srv_hmac_hex <- function(key, msg) {
  if (requireNamespace("openssl", quietly = TRUE)) {
    return(as.character(openssl::sha256(as.character(msg)[1L], key = as.character(key)[1L])))
  }
  rlang::hash(paste0(key, "::", msg))
}
