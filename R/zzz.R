.srv_env <- new.env(parent = emptyenv())

.onLoad <- function(libname, pkgname) {
  .srv_env$started_at <- Sys.time()
  invisible(NULL)
}
