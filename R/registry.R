# Geom registry.
#
# One configuration table drives validation, plot construction AND code
# generation, so the three cannot drift apart. Adding a geom = adding an entry.
#
# Entry fields
#   fn             ggplot2 function name
#   required       aesthetics that must be mapped (after inheritance and `drop`)
#   numeric        aesthetics whose variable must be numeric
#   drop           global aesthetics this layer type cannot take (e.g. y for stat_count);
#                  they are removed for this layer only (see plan.R)
#   layer_mappings aesthetics filled from a dedicated top-level option (text: label)
#   params         fixed (non-mapped) settings, each:
#                    type    "number" | "choice" | "logical"
#                    option  suffix of the jamovi slot option (l<i>_<option>)
#                    default value that is NOT emitted (ggplot2's own default); NULL = always emitted
#   extra_args / extra_code   constant extra arguments (R object / matching code text)

N_SLOTS <- 6L

.p_alpha <- list(type = "number", min = 0, max = 1, default = 1, option = "alpha")
.p_width <- list(type = "number", min = 0, max = Inf, default = 0, option = "size")   # 0 = ggplot2 default
.p_bins  <- list(type = "number", integer = TRUE, min = 1, max = 1000, default = 30, option = "bins")
.p_pos   <- function(option) list(type = "number", min = -Inf, max = Inf, default = NULL, option = option)

.geom <- function(label, fn, required = character(), numeric = character(),
                  drop = character(), layer_mappings = character(), params = list(),
                  variant_option = NULL, dodge_width = NULL, package = "ggplot2",
                  extra_args = function(layer) list(), extra_code = function(layer) character()) {
  list(label = label, fn = fn, required = required, numeric = numeric, drop = drop,
       layer_mappings = layer_mappings, params = params, variant_option = variant_option,
       dodge_width = dodge_width, package = package,
       extra_args = extra_args, extra_code = extra_code)
}

.p_barwidth <- list(type = "number", min = 0, max = Inf, default = 0, option = "width")   # 0 = ggplot2 default
# Position adjustment; only the listed choices are valid for the geom. "default" (not emitted)
# is always allowed and means ggplot2's own default for that geom.
.p_adjust <- function(choices)
  list(type = "choice", choices = choices, default = "default", option = "position")

GEOM_REGISTRY <- list(
  point     = .geom("Points", "geom_point", required = c("x", "y"), dodge_width = 0.9,
                    params = list(alpha = .p_alpha, size = .p_width,
                                  position = .p_adjust(c("identity", "jitter", "dodge")))),
  line      = .geom("Line", "geom_line", required = c("x", "y"),
                    params = list(alpha = .p_alpha, linewidth = .p_width)),
  path      = .geom("Path (data order)", "geom_path", required = c("x", "y"),
                    params = list(alpha = .p_alpha, linewidth = .p_width)),
  smooth    = .geom("Smooth / regression", "geom_smooth", required = c("x", "y"),
                    numeric = c("x", "y"),
                    params = list(
                      method = list(type = "choice", choices = c("lm", "loess", "glm"),
                                    default = NULL, option = "method"),
                      se = list(type = "logical", default = NULL, option = "se"),
                      linewidth = .p_width),
                    extra_args = function(layer) list(formula = y ~ x),
                    extra_code = function(layer) "formula = y ~ x"),
  jitter    = .geom("Jittered points", "geom_jitter", required = c("x", "y"),
                    params = list(alpha = .p_alpha, size = .p_width)),
  text      = .geom("Text labels", "geom_text", required = c("x", "y", "label"), dodge_width = 0.9,
                    layer_mappings = "label",
                    params = list(alpha = .p_alpha, size = .p_width,
                                  position = .p_adjust(c("identity", "jitter", "dodge")))),
  label     = .geom("Boxed labels", "geom_label", required = c("x", "y", "label"), dodge_width = 0.9,
                    layer_mappings = "label",
                    params = list(alpha = .p_alpha, size = .p_width,
                                  position = .p_adjust(c("identity", "jitter", "dodge")))),
  histogram = .geom("Histogram", "geom_histogram", required = "x", numeric = "x", drop = "y",
                    params = list(alpha = .p_alpha, bins = .p_bins,
                                  position = .p_adjust(c("identity", "stack", "fill", "dodge")))),
  bar       = .geom("Bar (counts)", "geom_bar", required = "x", drop = "y",
                    params = list(alpha = .p_alpha, width = .p_barwidth,
                                  position = .p_adjust(c("identity", "stack", "fill", "dodge")))),
  col       = .geom("Column (values)", "geom_col", required = c("x", "y"), numeric = "y",
                    params = list(alpha = .p_alpha, width = .p_barwidth,
                                  position = .p_adjust(c("identity", "stack", "fill", "dodge")))),
  density   = .geom("Density", "geom_density", required = "x", numeric = "x", drop = "y",
                    params = list(alpha = .p_alpha, linewidth = .p_width,
                                  position = .p_adjust(c("identity", "stack", "fill")))),
  area      = .geom("Area", "geom_area", required = c("x", "y"), numeric = c("x", "y"),
                    params = list(alpha = .p_alpha, linewidth = .p_width,
                                  position = .p_adjust(c("identity", "stack", "fill")))),
  ribbon    = .geom("Ribbon (min to max)", "geom_ribbon",
                    required = c("x", "ymin", "ymax"), numeric = c("ymin", "ymax"),
                    layer_mappings = c("ymin", "ymax"),
                    params = list(alpha = .p_alpha)),
  errorbar  = .geom("Error bars", "geom_errorbar", dodge_width = 0.9,
                    required = c("x", "ymin", "ymax"), numeric = c("ymin", "ymax"),
                    layer_mappings = c("ymin", "ymax"),
                    params = list(alpha = .p_alpha, linewidth = .p_width, width = .p_barwidth,
                                  position = .p_adjust(c("identity", "dodge")))),
  segment   = .geom("Segments", "geom_segment",
                    required = c("x", "y", "xend", "yend"), numeric = c("xend", "yend"),
                    layer_mappings = c("xend", "yend"),
                    params = list(alpha = .p_alpha, linewidth = .p_width)),
  summary   = .geom("Summary (point / range)", "stat_summary", required = c("x", "y"), numeric = "y",
                    dodge_width = 0.9, variant_option = "stat",
                    params = list(alpha = .p_alpha, size = .p_width,
                                  position = .p_adjust(c("identity", "dodge"))),
                    extra_args = function(layer) summary_extra(layer, "summary")$args,
                    extra_code = function(layer) summary_extra(layer, "summary")$code),
  summary_errorbar = .geom("Summary error bars", "stat_summary", required = c("x", "y"), numeric = "y",
                    dodge_width = 0.9, variant_option = "stat",
                    params = list(alpha = .p_alpha, linewidth = .p_width, width = .p_barwidth,
                                  position = .p_adjust(c("identity", "dodge"))),
                    extra_args = function(layer) summary_extra(layer, "summary_errorbar")$args,
                    extra_code = function(layer) summary_extra(layer, "summary_errorbar")$code),
  summary_bar = .geom("Summary bars", "stat_summary", required = c("x", "y"), numeric = "y",
                    variant_option = "stat",
                    params = list(alpha = .p_alpha, width = .p_barwidth,
                                  position = .p_adjust(c("identity", "dodge", "stack", "fill"))),
                    extra_args = function(layer) summary_extra(layer, "summary_bar")$args,
                    extra_code = function(layer) summary_extra(layer, "summary_bar")$code),
  boxplot   = .geom("Boxplot", "geom_boxplot", required = "y", numeric = "y",
                    params = list(alpha = .p_alpha, width = .p_barwidth,
                                  position = .p_adjust(c("identity", "dodge")))),
  violin    = .geom("Violin", "geom_violin", required = c("x", "y"), numeric = "y",
                    params = list(alpha = .p_alpha, width = .p_barwidth,
                                  position = .p_adjust(c("identity", "dodge")))),
  hline     = .geom("Horizontal line", "geom_hline",
                    params = list(yintercept = .p_pos("intercept"), linewidth = .p_width)),
  vline     = .geom("Vertical line", "geom_vline",
                    params = list(xintercept = .p_pos("intercept"), linewidth = .p_width)),
  abline    = .geom("Diagonal line", "geom_abline",
                    params = list(intercept = .p_pos("intercept"), slope = .p_pos("slope"),
                                  linewidth = .p_width))
)

# Slot options that are always visible in the UI, with their 'not set' value.
COMMON_OPTION_DEFAULTS <- list(alpha = 1, size = 0, width = 0, position = "default", stat = "mean_se")

# Global aesthetic -> jamovi option name
MAPPING_OPTIONS <- c(x = "x", y = "y", colour = "colour", fill = "fill", shape = "shape",
                     size = "sizeBy", alpha = "alphaBy", group = "group")

THEMES <- c(
  grey = "theme_grey", minimal = "theme_minimal", bw = "theme_bw",
  classic = "theme_classic", light = "theme_light", dark = "theme_dark",
  linedraw = "theme_linedraw", void = "theme_void"
)

FACET_TYPES  <- c("wrap", "grid")
FACET_SCALES <- c("fixed", "free", "free_x", "free_y")

# ---- D2: scales, coordinates, legend, labels -------------------------------

AXIS_TRANSFORMS  <- c("identity", "log10", "sqrt", "reverse")
COORD_TYPES      <- c(cartesian = "coord_cartesian", flip = "coord_flip", fixed = "coord_fixed")
LEGEND_POSITIONS <- c("right", "left", "top", "bottom", "none")

# label name (as used by labs()) -> jamovi option; order = order in generated code
LABEL_OPTIONS <- c(title = "title", subtitle = "subtitle", caption = "caption",
                   x = "xlab", y = "ylab", colour = "colourTitle", fill = "fillTitle",
                   shape = "shapeTitle", size = "sizeTitle", alpha = "alphaTitle")

# Colour/fill palettes. `fn` has %s for the aesthetic ("colour" / "fill").
# NULL entry = palette cannot be used for that kind of variable.
PALETTES <- list(
  viridis = list(label = "Viridis",
                 discrete   = list(fn = "scale_%s_viridis_d", args = list()),
                 continuous = list(fn = "scale_%s_viridis_c", args = list())),
  set1    = list(label = "Brewer Set1",
                 discrete   = list(fn = "scale_%s_brewer", args = list(palette = "Set1")),
                 continuous = NULL),
  dark2   = list(label = "Brewer Dark2",
                 discrete   = list(fn = "scale_%s_brewer", args = list(palette = "Dark2")),
                 continuous = NULL),
  blues   = list(label = "Blues",
                 discrete   = list(fn = "scale_%s_brewer", args = list(palette = "Blues")),
                 continuous = list(fn = "scale_%s_distiller", args = list(palette = "Blues"))),
  greys   = list(label = "Greys",
                 discrete   = list(fn = "scale_%s_grey", args = list()),
                 continuous = list(fn = "scale_%s_distiller", args = list(palette = "Greys"))),
  manual  = list(label = "Manual colours",
                 discrete   = list(fn = "scale_%s_manual", args = list()),
                 continuous = NULL)
)

# ---- D3b: summary statistics (stat_summary) --------------------------------
# Built only from base R and ggplot2's own mean_se (no Hmisc dependency).
# args(): the R objects handed to ggplot2.  code: the matching text (same meaning).
SUMMARY_STATS <- list(
  mean_se = list(label = "Mean \u00b1 standard error", range = TRUE,
    args = function() list(fun.data = getExportedValue("ggplot2", "mean_se")),
    code = c(fun.data = "mean_se")),
  mean_sd = list(label = "Mean \u00b1 standard deviation", range = TRUE,
    args = function() list(fun = mean,
                           fun.min = function(x) mean(x) - stats::sd(x),
                           fun.max = function(x) mean(x) + stats::sd(x)),
    code = c(fun = "mean", fun.min = "function(x) mean(x) - sd(x)",
             fun.max = "function(x) mean(x) + sd(x)")),
  mean = list(label = "Mean", range = FALSE,
    args = function() list(fun = mean),
    code = c(fun = "mean")),
  median = list(label = "Median", range = FALSE,
    args = function() list(fun = stats::median),
    code = c(fun = "median")),
  median_iqr = list(label = "Median with interquartile range", range = TRUE,
    args = function() list(fun = stats::median,
                           fun.min = function(x) stats::quantile(x, 0.25, names = FALSE),
                           fun.max = function(x) stats::quantile(x, 0.75, names = FALSE)),
    code = c(fun = "median", fun.min = "function(x) quantile(x, 0.25, names = FALSE)",
             fun.max = "function(x) quantile(x, 0.75, names = FALSE)"))
)

summary_extra <- function(layer, kind) {
  v <- SUMMARY_STATS[[layer$variant %||% "mean_se"]]
  geom <- switch(kind,
                 summary = if (isTRUE(v$range)) "pointrange" else "point",
                 summary_errorbar = "errorbar",
                 summary_bar = "col")
  list(args = c(list(geom = geom), v$args()),
       code = c(paste0("geom = ", paste(deparse(geom), collapse = "")),
                paste0(names(v$code), " = ", unname(v$code))))
}

# "dodge" on a layer without an inherent width (points, labels, point ranges) makes ggplot2
# warn "Width not defined" and not separate the groups. For those layers (def$dodge_width)
# dodge becomes position_dodge(width = 0.9), ggplot2's default bar width, so dodged points,
# error bars and bars line up. build_plot() uses $value and spec_to_code() uses $code.
position_arg <- function(def, value) {
  if (identical(value, "dodge") && !is.null(def$dodge_width))
    return(list(value = ggplot2::position_dodge(width = def$dodge_width),
                code = paste0("position_dodge(width = ", def$dodge_width, ")")))
  list(value = value, code = paste(deparse(value), collapse = ""))
}

# ---- D2b: theme details -----------------------------------------------------
THEME_FAMILIES <- c("sans", "serif", "mono")   # generic R graphics families (always available)
X_TEXT_ANGLES  <- c(45, 90)
THEME_DEFAULT_BASE_SIZE <- 11

# Turns the (validated) theme_details of a spec into theme(...) arguments and the matching code text.
# Only non-default settings are present in `td`, so nothing is emitted for an untouched theme.
theme_tweaks <- function(td) {
  args <- list(); code <- character()
  add <- function(name, value, text) { args[[name]] <<- value; code[[name]] <<- text }
  if (isTRUE(td$hide_grid_major)) add("panel.grid.major", ggplot2::element_blank(), "element_blank()")
  if (isTRUE(td$hide_grid_minor)) add("panel.grid.minor", ggplot2::element_blank(), "element_blank()")
  if (isTRUE(td$hide_ticks))      add("axis.ticks", ggplot2::element_blank(), "element_blank()")
  if (!is.null(td$x_angle)) {
    if (td$x_angle == 90)
      add("axis.text.x", ggplot2::element_text(angle = 90, hjust = 1, vjust = 0.5),
          "element_text(angle = 90, hjust = 1, vjust = 0.5)")
    else
      add("axis.text.x", ggplot2::element_text(angle = td$x_angle, hjust = 1),
          paste0("element_text(angle = ", td$x_angle, ", hjust = 1)"))
  }
  if (isTRUE(td$bold_title))
    add("plot.title", ggplot2::element_text(face = "bold"), 'element_text(face = "bold")')
  if (!is.null(td$plot_fill))
    add("plot.background", ggplot2::element_rect(fill = td$plot_fill, colour = NA),
        paste0("element_rect(fill = ", paste(deparse(td$plot_fill), collapse = ""), ", colour = NA)"))
  if (!is.null(td$panel_fill))
    add("panel.background", ggplot2::element_rect(fill = td$panel_fill, colour = NA),
        paste0("element_rect(fill = ", paste(deparse(td$panel_fill), collapse = ""), ", colour = NA)"))
  if (!is.null(td$margin)) {
    m <- paste(deparse(td$margin), collapse = "")
    add("plot.margin", ggplot2::margin(td$margin, td$margin, td$margin, td$margin),
        paste0("margin(", m, ", ", m, ", ", m, ", ", m, ")"))
  }
  list(args = args, code = code)
}

# Arguments for the theme_*() function itself (base_size, base_family).
theme_base_args <- function(td) {
  args <- list()
  if (!is.null(td$base_size))   args$base_size <- td$base_size
  if (!is.null(td$base_family)) args$base_family <- td$base_family
  args
}

# ---- F1: extension packages ------------------------------------------------
# Layers from extension packages declare `package`. The package is loaded lazily with
# getExportedValue(); if it is not available the layer reports a message instead of failing.
package_problem <- function(def) {
  pkg <- def$package
  if (is.null(pkg) || identical(pkg, "ggplot2")) return(NULL)
  if (requireNamespace(pkg, quietly = TRUE)) return(NULL)
  paste0("needs the R package '", pkg, "', which is not available in this R installation.")
}
