# Small helpers (no jamovi dependency, so they can be unit-tested standalone).

`%||%` <- function(a, b) if (is.null(a)) b else a
