# spec -> readable R code. Same spec, registry and layer_plan() as build_plot().
# Only validated values reach this function; strings go through deparse(),
# so quotes/backslashes in labels or names cannot break out of a string.

code_name <- function(v) {
  if (identical(make.names(v), v) && !(v %in% c(".data", ".env")))
    v
  else
    paste0(".data[[", paste(deparse(v), collapse = ""), "]]")
}

code_value <- function(v) paste(deparse(v), collapse = "")

code_aes <- function(m) {
  m <- as.list(m)
  paste0("aes(", paste0(names(m), " = ", vapply(m, code_name, ""), collapse = ", "), ")")
}

code_vars <- function(v) paste0("vars(", paste(vapply(v, code_name, ""), collapse = ", "), ")")

code_facets <- function(f) {
  args <- character()
  if (identical(f$type, "wrap")) {
    args <- code_vars(f$rows)
    if (!is.null(f$ncol)) args <- c(args, paste0("ncol = ", code_value(f$ncol)))
  } else {
    if (length(f$rows)) args <- c(args, paste0("rows = ", code_vars(f$rows)))
    if (length(f$cols)) args <- c(args, paste0("cols = ", code_vars(f$cols)))
  }
  if (!identical(f$scales, "fixed")) args <- c(args, paste0("scales = ", code_value(f$scales)))
  paste0("facet_", f$type, "(", paste(args, collapse = ", "), ")")
}

# fn(name = value, ...) from a named list of already-validated values
code_call <- function(fn, args) {
  if (length(args) == 0) return(paste0(fn, "()"))
  paste0(fn, "(", paste0(names(args), " = ", vapply(args, code_value, ""), collapse = ", "), ")")
}

# `data` is only needed when a colour/fill palette is set: whether the code uses a
# continuous or a discrete scale depends on the variable's type.
spec_to_code <- function(spec, data = NULL) {
  head <- if (length(spec$mappings)) paste0("ggplot(data, ", code_aes(spec$mappings), ")") else "ggplot(data)"
  parts <- character()

  for (l in spec$layers) {
    if (!isTRUE(l$enabled)) next
    def  <- GEOM_REGISTRY[[l$type]]
    plan <- layer_plan(spec, l)
    args <- character()
    if (length(plan$mapping)) args <- c(args, code_aes(plan$mapping))
    for (p in names(l$params))
      args <- c(args, paste0(p, " = ",
                             if (identical(p, "position")) position_arg(def, l$params[[p]])$code
                             else code_value(l$params[[p]])))
    if (!isTRUE(plan$inherit)) args <- c(args, "inherit.aes = FALSE")
    args <- c(args, def$extra_code(l))
    parts <- c(parts, paste0(def$fn, "(", paste(args, collapse = ", "), ")"))
  }

  if (!is.null(spec$facets)) parts <- c(parts, code_facets(spec$facets))

  for (ax in c("x", "y"))
    if (!is.null(spec$scales[[ax]]))
      parts <- c(parts, code_call(paste0("scale_", ax, "_continuous"), spec$scales[[ax]]))
  for (aes in c("colour", "fill")) {
    if (is.null(spec$scales[[aes]])) next
    if (is.null(data)) stop("`data` is required to generate the code for a colour/fill palette.", call. = FALSE)
    plan <- palette_plan(spec, aes, data)
    if (!is.null(plan)) parts <- c(parts, code_call(plan$fn, plan$args))
  }
  if (!is.null(spec$coord))
    parts <- c(parts, code_call(COORD_TYPES[[spec$coord$type]],
                                spec$coord[intersect(c("xlim", "ylim"), names(spec$coord))]))

  if (length(spec$labels)) {
    la <- paste0(names(spec$labels), " = ", vapply(spec$labels, code_value, ""))
    parts <- c(parts, paste0("labs(", paste(la, collapse = ", "), ")"))
  }
  parts <- c(parts, code_call(THEMES[[spec$theme]], theme_base_args(spec$theme_details)))
  tw <- theme_tweaks(spec$theme_details)
  if (length(tw$code))
    parts <- c(parts, paste0("theme(", paste0(names(tw$code), " = ", tw$code, collapse = ", "), ")"))
  if (!is.null(spec$legend))
    parts <- c(parts, code_call("theme", list(legend.position = spec$legend$position)))

  used <- Filter(function(l) isTRUE(l$enabled), spec$layers)
  pkgs <- unique(vapply(used, function(l) GEOM_REGISTRY[[l$type]]$package, ""))
  libs <- paste0("library(", c("ggplot2", setdiff(pkgs, "ggplot2")), ")", collapse = "\n")
  paste0(
    libs, "\n\n",
    "# `data` is your dataset as a data frame with the same column names as in jamovi.\n",
    paste(c(head, parts), collapse = " +\n  "), "\n"
  )
}
