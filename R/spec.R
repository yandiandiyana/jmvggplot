# Plot specification
#
# A spec is a plain, structured list (never R source text):
#
#   list(
#     mappings = list(x=, y=, colour=, fill=, shape=, size=, alpha=, group=),  # column names
#     layers   = list(list(slot, type, enabled, inherit_aes, mappings, params)),
#     facets   = list(type = "wrap"|"grid", rows=, cols=, scales=, ncol=)  or NULL,
#     scales   = list(x=list(transform=, limits=), y=..., colour=list(palette=, values=), fill=...),
#     coord    = list(type=, xlim=, ylim=) or NULL,   legend = list(position=) or NULL,
#     theme_details = list(base_size, base_family, hide_grid_major, ...) or NULL,
#     labels   = list(title = , x = , y = ),
#     theme    = "minimal"
#   )
#
# Layer order in `layers` is the drawing order (first = bottom).

# `o` is anything indexable by option name: jamovi's self$options, or a list.
spec_from_options <- function(o, n_slots = N_SLOTS) {
  opt <- function(name) {
    v <- tryCatch(o[[name]], error = function(e) NULL)
    if (is.null(v) || length(v) == 0) return(NULL)
    if (is.character(v) && length(v) == 1 && !nzchar(v)) return(NULL)
    v
  }
  same <- function(v, d) {
    identical(v, d) ||
      (is.numeric(v) && is.numeric(d) && length(v) == 1 && length(d) == 1 &&
         isTRUE(all.equal(v, d)))
  }

  mappings <- list()
  for (a in names(MAPPING_OPTIONS)) {
    v <- opt(MAPPING_OPTIONS[[a]])
    if (!is.null(v)) mappings[[a]] <- v
  }

  layers <- list()
  for (i in seq_len(n_slots)) {
    pre  <- paste0("l", i, "_")
    type <- opt(paste0(pre, "type"))
    if (is.null(type) || identical(type, "none")) next

    def <- GEOM_REGISTRY[[type]]
    params <- list()
    lmap <- list()
    if (!is.null(def)) {
      for (p in names(def$params)) {
        pd <- def$params[[p]]
        v  <- opt(paste0(pre, pd$option))
        if (is.null(v)) next
        if (!is.null(pd$default) && same(v, pd$default)) next
        params[[p]] <- v
      }
      for (a in def$layer_mappings) {
        v <- opt(a)
        if (!is.null(v)) lmap[[a]] <- v
      }
    }
    # Always-visible controls (opacity, size, width, position) set to a non-default value
    # on a layer type that does not use them: record them so validation can say so.
    used_opts <- if (is.null(def)) character() else
      c(vapply(def$params, function(pd) pd$option, ""), def$variant_option)
    variant <- if (!is.null(def) && !is.null(def$variant_option))
      (opt(paste0(pre, def$variant_option)) %||% "mean_se") else NULL
    unused <- character()
    for (o_name in setdiff(names(COMMON_OPTION_DEFAULTS), used_opts)) {
      v <- opt(paste0(pre, o_name))
      if (!is.null(v) && !same(v, COMMON_OPTION_DEFAULTS[[o_name]])) unused <- c(unused, o_name)
    }
    enabled <- opt(paste0(pre, "enabled"))
    inherit <- opt(paste0(pre, "inherit"))
    layers[[length(layers) + 1]] <- list(
      slot = i, type = type,
      enabled = if (is.null(enabled)) TRUE else isTRUE(enabled),
      inherit_aes = if (is.null(inherit)) TRUE else isTRUE(inherit),
      mappings = lmap, params = params, unused = unused, variant = variant
    )
  }

  facets <- NULL
  ftype <- opt("facetType")
  if (!is.null(ftype) && !identical(ftype, "none")) {
    ncol <- opt("facetCols")
    facets <- Filter(Negate(is.null), list(
      type = ftype, rows = opt("facetVar1"), cols = opt("facetVar2"),
      scales = opt("facetScales") %||% "fixed",
      ncol = if (identical(ftype, "wrap") && !is.null(ncol) && ncol > 0) ncol else NULL
    ))
  }

  # ---- axis transforms and ranges ----
  problems <- character()
  parse_limit <- function(name) {
    v <- opt(name)
    if (is.null(v)) return(NA_real_)
    n <- suppressWarnings(as.numeric(trimws(v)))
    if (is.na(n) || !is.finite(n)) {
      problems <<- c(problems, paste0("'", v, "' is not a valid number for ", name,
                                      " (use a dot as decimal separator)."))
      return(NA_real_)
    }
    n
  }
  range_mode <- opt("rangeMode") %||% "zoom"
  scales <- list()
  coord_lim <- list()
  for (ax in c("x", "y")) {
    lim <- c(parse_limit(paste0(ax, "Min")), parse_limit(paste0(ax, "Max")))
    if (all(is.na(lim))) lim <- NULL
    trans <- opt(paste0(ax, "Trans"))
    sc <- list()
    if (!is.null(trans) && !identical(trans, "identity")) sc$transform <- trans
    if (!is.null(lim) && identical(range_mode, "limits")) sc$limits <- lim
    if (length(sc)) scales[[ax]] <- sc
    if (!is.null(lim) && identical(range_mode, "zoom")) coord_lim[[paste0(ax, "lim")]] <- lim
  }

  # ---- colour / fill palettes ----
  parse_values <- function(v) {
    if (is.null(v)) return(character())
    vals <- trimws(strsplit(v, "[,;[:space:]]+")[[1]])
    vals[nzchar(vals)]
  }
  for (aes in c("colour", "fill")) {
    pal <- opt(paste0(aes, "Palette"))
    if (is.null(pal) || identical(pal, "default")) next
    sc <- list(palette = pal)
    if (identical(pal, "manual")) sc$values <- parse_values(opt(paste0(aes, "Values")))
    scales[[aes]] <- sc
  }

  # ---- coordinates, legend ----
  ctype <- opt("coordType") %||% "cartesian"
  coord <- NULL
  if (!identical(ctype, "cartesian") || length(coord_lim))
    coord <- c(list(type = ctype), coord_lim)
  legpos <- opt("legendPosition")
  legend <- if (is.null(legpos) || identical(legpos, "right")) NULL else list(position = legpos)

  labels <- list()
  for (nm in names(LABEL_OPTIONS)) {
    v <- opt(LABEL_OPTIONS[[nm]])
    if (!is.null(v)) labels[[nm]] <- v
  }

  # ---- theme details (only non-default settings are stored) ----
  td <- list()
  bs <- opt("baseSize")
  if (!is.null(bs) && !isTRUE(all.equal(bs, THEME_DEFAULT_BASE_SIZE))) td$base_size <- bs
  fam <- opt("baseFamily")
  if (!is.null(fam) && !identical(fam, "default")) td$base_family <- fam
  if (isTRUE(opt("hideGridMajor"))) td$hide_grid_major <- TRUE
  if (isTRUE(opt("hideGridMinor"))) td$hide_grid_minor <- TRUE
  if (isTRUE(opt("hideTicks")))     td$hide_ticks <- TRUE
  ang <- opt("xTextAngle")
  if (!is.null(ang) && !identical(ang, "default")) td$x_angle <- suppressWarnings(as.numeric(sub("^deg", "", ang)))
  if (isTRUE(opt("boldTitle")))     td$bold_title <- TRUE
  if (!is.null(opt("plotFill")))    td$plot_fill <- opt("plotFill")
  if (!is.null(opt("panelFill")))   td$panel_fill <- opt("panelFill")
  mg <- parse_limit("plotMargin")
  if (!is.na(mg)) td$margin <- mg

  list(mappings = mappings, layers = layers, facets = facets,
       scales = scales, coord = coord, legend = legend,
       labels = labels, theme = opt("theme") %||% "minimal",
       theme_details = if (length(td)) td else NULL,
       problems = problems)
}
