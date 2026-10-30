# Validation of a spec against a dataset. Returns list(errors, warnings).
# Called before plotting AND before code generation.

validate_param <- function(name, value, def) {
  ok <- switch(
    def$type,
    number  = is.numeric(value) && length(value) == 1 && is.finite(value) &&
              value >= def$min && value <= def$max &&
              (!isTRUE(def$integer) || value == round(value)),
    choice  = is.character(value) && length(value) == 1 && value %in% def$choices,
    logical = is.logical(value) && length(value) == 1 && !is.na(value),
    FALSE
  )
  if (isTRUE(ok)) return(NULL)
  if (identical(def$type, "choice"))
    return(paste0("invalid value for '", name, "' (allowed: ", paste(def$choices, collapse = ", "), ")"))
  paste0("invalid value for '", name, "'")
}

validate_facets <- function(f, data) {
  errs <- character(); warns <- character()
  if (is.null(f)) return(list(errors = errs, warnings = warns))
  if (!(f$type %in% FACET_TYPES))
    return(list(errors = paste0("Unknown facet type '", f$type, "'."), warnings = warns))
  if (!((f$scales %||% "fixed") %in% FACET_SCALES))
    errs <- c(errs, paste0("Unknown facet scales option '", f$scales, "'."))
  if (identical(f$type, "wrap")) {
    if (length(f$rows) == 0) errs <- c(errs, "Facet wrap needs a facet variable.")
    if (length(f$cols)) warns <- c(warns, "The facet columns variable is only used by facet grid; it is ignored for facet wrap.")
    if (!is.null(f$ncol) && !(is.numeric(f$ncol) && f$ncol >= 1 && f$ncol == round(f$ncol)))
      errs <- c(errs, "Number of facet columns must be a whole number of at least 1.")
  } else if (length(f$rows) == 0 && length(f$cols) == 0) {
    errs <- c(errs, "Facet grid needs a rows variable, a columns variable, or both.")
  }
  for (v in unique(c(f$rows, f$cols))) {
    if (v %in% names(data) && is.numeric(data[[v]]))
      errs <- c(errs, paste0("Facet variable '", v, "' is numeric; facets need a categorical variable."))
  }
  list(errors = errs, warnings = warns)
}


valid_colour <- function(v) {
  is.character(v) && length(v) == 1 && !is.na(v) && nzchar(v) &&
    !inherits(try(grDevices::col2rgb(v), silent = TRUE), "try-error")
}

validate_scales <- function(spec, data) {
  errs <- character(); warns <- character()
  e <- function(m) errs <<- c(errs, m)
  w <- function(m) warns <<- c(warns, m)

  for (m in spec$problems) e(m)

  for (ax in c("x", "y")) {
    sc   <- spec$scales[[ax]]
    zoom <- spec$coord[[paste0(ax, "lim")]]
    var  <- spec$mappings[[ax]]
    if (!is.null(sc$transform) && !(sc$transform %in% AXIS_TRANSFORMS))
      e(paste0("Unknown ", ax, " axis transformation '", sc$transform, "'."))
    if ((!is.null(sc) || !is.null(zoom)) && !is.null(var)) {
      col <- data[[var]]
      if (!is.numeric(col)) {
        e(paste0("The ", ax, " axis transformation/range needs a numeric variable, but '",
                 var, "' is categorical."))
      } else if (!is.null(sc$transform)) {
        mn <- suppressWarnings(min(col, na.rm = TRUE))
        if (identical(sc$transform, "log10") && mn <= 0)
          e(paste0("log10 needs positive values, but '", var, "' has values of zero or below."))
        if (identical(sc$transform, "sqrt") && mn < 0)
          e(paste0("The square-root transformation needs non-negative values, but '", var, "' has negative values."))
      }
    }
    for (lim in list(sc$limits, zoom))
      if (!is.null(lim) && !anyNA(lim) && lim[1] >= lim[2])
        e(paste0("The ", ax, " axis minimum must be smaller than the maximum."))
    if (!is.null(zoom) && !is.null(sc$transform))
      e(paste0("Zooming the ", ax, " axis is not supported together with a transformation. ",
               "Use range mode 'limits' instead."))
  }

  for (aes in c("colour", "fill")) {
    sc <- spec$scales[[aes]]
    if (is.null(sc)) next
    if (!(sc$palette %in% names(PALETTES))) { e(paste0("Unknown ", aes, " palette '", sc$palette, "'.")); next }
    var <- spec$mappings[[aes]]
    if (is.null(var)) {
      w(paste0("The ", aes, " palette is ignored because ", aes, " is not mapped to a variable."))
      next
    }
    kind <- if (is.numeric(data[[var]])) "continuous" else "discrete"
    if (is.null(PALETTES[[sc$palette]][[kind]])) {
      e(paste0("The '", PALETTES[[sc$palette]]$label, "' palette for ", aes, " needs ",
               if (kind == "continuous") "a categorical" else "a numeric",
               " variable, but '", var, "' is ", if (kind == "continuous") "numeric" else "categorical", "."))
      next
    }
    if (identical(sc$palette, "manual")) {
      vals <- sc$values
      if (length(vals) == 0) {
        e(paste0("Manual ", aes, " palette: enter colours separated by commas (names like red or hex like #1b9e77)."))
      } else {
        bad <- vals[!vapply(vals, valid_colour, TRUE)]
        if (length(bad)) e(paste0("Manual ", aes, " palette: not a valid colour: ", paste(bad, collapse = ", "), "."))
        n <- length(unique(stats::na.omit(data[[var]])))
        if (length(vals) < n)
          e(paste0("Manual ", aes, " palette has ", length(vals), " colour(s) but '", var, "' has ", n, " levels."))
      }
    }
  }

  if (!is.null(spec$coord) && !(spec$coord$type %in% names(COORD_TYPES)))
    e(paste0("Unknown coordinate system '", spec$coord$type, "'."))
  if (!is.null(spec$legend) && !(spec$legend$position %in% LEGEND_POSITIONS))
    e(paste0("Unknown legend position '", spec$legend$position, "'."))

  list(errors = errs, warnings = warns)
}

validate_theme_details <- function(td) {
  errs <- character()
  e <- function(m) errs <<- c(errs, m)
  if (is.null(td)) return(errs)
  if (!is.null(td$base_size) &&
      !(is.numeric(td$base_size) && length(td$base_size) == 1 && is.finite(td$base_size) &&
        td$base_size >= 4 && td$base_size <= 40))
    e("Base text size must be a number between 4 and 40.")
  if (!is.null(td$base_family) && !(td$base_family %in% THEME_FAMILIES))
    e(paste0("Unknown font family '", td$base_family, "' (allowed: ", paste(THEME_FAMILIES, collapse = ", "), ")."))
  if (!is.null(td$x_angle) && !(isTRUE(td$x_angle %in% X_TEXT_ANGLES)))
    e("X axis text angle must be 45 or 90 degrees.")
  for (nm in c("plot_fill", "panel_fill"))
    if (!is.null(td[[nm]]) && !valid_colour(td[[nm]]))
      e(paste0("Not a valid colour for the ", if (nm == "plot_fill") "plot" else "panel",
               " background: ", td[[nm]], "."))
  if (!is.null(td$margin) &&
      !(is.numeric(td$margin) && length(td$margin) == 1 && is.finite(td$margin) &&
        td$margin >= 0 && td$margin <= 200))
    e("Plot margin must be a number between 0 and 200 points.")
  errs
}

validate_spec <- function(spec, data) {
  errors <- character()
  warnings <- character()
  err  <- function(msg) errors <<- c(errors, msg)
  warn <- function(msg) warnings <<- c(warnings, msg)

  if (!is.data.frame(data) || nrow(data) == 0)
    return(list(errors = "The dataset has no rows.", warnings = character()))

  layers <- spec$layers %||% list()
  enabled <- Filter(function(l) isTRUE(l$enabled), layers)
  if (length(enabled) == 0)
    return(list(errors = "There are no enabled layers. Add or enable at least one layer.",
                warnings = character()))

  facet_vars <- unique(c(spec$facets$rows, spec$facets$cols))
  all_vars <- unique(c(unlist(spec$mappings), facet_vars,
                       unlist(lapply(enabled, function(l) unlist(l$mappings)))))
  missing_vars <- setdiff(all_vars, names(data))
  if (length(missing_vars))
    return(list(errors = paste0("Variable(s) not found in the data: ",
                                paste(missing_vars, collapse = ", ")),
                warnings = character()))

  if (!(spec$theme %in% names(THEMES)))
    err(paste0("Unknown theme '", spec$theme, "'."))

  shape_var <- spec$mappings[["shape"]]
  if (!is.null(shape_var) && is.numeric(data[[shape_var]]))
    err(paste0("Shape needs a categorical variable, but '", shape_var, "' is numeric."))

  for (l in enabled) {
    tag <- paste0("Layer ", l$slot, " (", l$type, "): ")
    def <- GEOM_REGISTRY[[l$type]]
    if (is.null(def)) { err(paste0(tag, "unsupported layer type.")); next }
    pp <- package_problem(def)
    if (!is.null(pp)) { err(paste0(tag, pp)); next }

    eff <- effective_mapping(spec, l)

    if (!is.null(def$variant_option)) {
      if (is.null(l$variant) || !(l$variant %in% names(SUMMARY_STATS))) {
        err(paste0(tag, "unknown summary statistic."))
      } else if (identical(l$type, "summary_errorbar") && !isTRUE(SUMMARY_STATS[[l$variant]]$range)) {
        err(paste0(tag, "error bars need a statistic that has a range (mean \u00b1 SE, mean \u00b1 SD, or median with IQR)."))
      }
    }

    if (isTRUE(l$inherit_aes)) {
      dropped <- intersect(def$drop, names(spec$mappings))
      if (length(dropped))
        warn(paste0(tag, "the global ", paste(dropped, collapse = "/"),
                    " mapping is not used by this layer type (values are computed by ggplot2)."))
    }

    miss <- setdiff(def$required, names(eff))
    if (length(miss))
      err(paste0(tag, "needs these aesthetics mapped: ", paste(miss, collapse = ", "),
                 if (length(intersect(miss, def$layer_mappings)))
                   paste0(" (choose a variable for ", paste(intersect(miss, def$layer_mappings), collapse = ", "),
                          " in the variable list)") else "",
                 if (!isTRUE(l$inherit_aes)) " (this layer does not inherit the global mappings)" else ""))

    for (a in intersect(def$numeric, names(eff))) {
      col <- data[[eff[[a]]]]
      if (!is.numeric(col))
        err(paste0(tag, "'", eff[[a]], "' is mapped to ", a,
                   " but is categorical; this layer needs a numeric variable."))
    }

    for (u in l$unused) {
      if (identical(u, "position"))
        err(paste0(tag, "this layer type does not support a position adjustment."))
      else
        warn(paste0(tag, "the '", u, "' setting is not used by this layer type."))
    }

    for (p in names(l$params)) {
      pd <- def$params[[p]]
      if (is.null(pd)) {
        err(paste0(tag, if (identical(p, "position")) "this layer type does not support a position adjustment."
                        else paste0("unsupported setting '", p, "'.")))
        next
      }
      msg <- validate_param(p, l$params[[p]], pd)
      if (!is.null(msg)) err(paste0(tag, msg, "."))
      if (p %in% c("alpha", "size") && p %in% names(eff))
        warn(paste0(tag, "the fixed '", p, "' setting overrides the '", p, "' mapping."))
    }
  }

  fv <- validate_facets(spec$facets, data)
  errors <- c(errors, fv$errors)
  warnings <- c(warnings, fv$warnings)

  sv <- validate_scales(spec, data)
  errors <- c(errors, sv$errors)
  warnings <- c(warnings, sv$warnings)

  errors <- c(errors, validate_theme_details(spec$theme_details))

  for (nm in names(spec$labels)) {
    v <- spec$labels[[nm]]
    if (!(is.character(v) && length(v) == 1))
      err(paste0("Label '", nm, "' must be a single text value."))
  }

  if (length(errors) == 0) {
    used <- intersect(all_vars, names(data))
    n_inc <- sum(!stats::complete.cases(data[, used, drop = FALSE]))
    if (n_inc > 0)
      warn(paste0(
        n_inc, " of ", nrow(data), " rows have missing values in the mapped variables; ",
        "ggplot2 drops them where a layer needs them."))
  }

  list(errors = errors, warnings = warnings)
}
