# spec + data -> ggplot object. Uses real ggplot2 calls only; variable names
# are looked up with .data[["name"]], never pasted into source text.

make_aes <- function(m) {
  m <- as.list(m)
  if (length(m) == 0) return(ggplot2::aes())
  exprs <- lapply(m, function(v) call("[[", quote(.data), v))
  do.call(ggplot2::aes, exprs)
}

make_vars <- function(v) {
  do.call(ggplot2::vars, lapply(v, function(n) call("[[", quote(.data), n)))
}

add_facets <- function(p, f) {
  if (is.null(f)) return(p)
  args <- list()
  if (!identical(f$scales, "fixed")) args$scales <- f$scales
  if (identical(f$type, "wrap")) {
    args$facets <- make_vars(f$rows)
    if (!is.null(f$ncol)) args$ncol <- f$ncol
    return(p + do.call(ggplot2::facet_wrap, args))
  }
  if (length(f$rows)) args$rows <- make_vars(f$rows)
  if (length(f$cols)) args$cols <- make_vars(f$cols)
  p + do.call(ggplot2::facet_grid, args)
}

add_scales <- function(p, spec, data) {
  for (ax in c("x", "y")) {
    sc <- spec$scales[[ax]]
    if (is.null(sc)) next
    p <- p + do.call(getExportedValue("ggplot2", paste0("scale_", ax, "_continuous")), sc)
  }
  for (aes in c("colour", "fill")) {
    plan <- palette_plan(spec, aes, data)
    if (is.null(plan)) next
    p <- p + do.call(getExportedValue("ggplot2", plan$fn), plan$args)
  }
  p
}

add_coord <- function(p, coord) {
  if (is.null(coord)) return(p)
  args <- coord[intersect(c("xlim", "ylim"), names(coord))]
  p + do.call(getExportedValue("ggplot2", COORD_TYPES[[coord$type]]), args)
}

build_plot <- function(spec, data) {
  res <- validate_spec(spec, data)
  if (length(res$errors))
    stop(paste(res$errors, collapse = "\n"), call. = FALSE)

  p <- ggplot2::ggplot(data = data, mapping = make_aes(spec$mappings))

  for (l in spec$layers) {
    if (!isTRUE(l$enabled)) next
    def  <- GEOM_REGISTRY[[l$type]]
    plan <- layer_plan(spec, l)
    args <- l$params
    if (!is.null(args$position)) args$position <- position_arg(def, args$position)$value
    if (length(plan$mapping)) args$mapping <- make_aes(plan$mapping)
    if (!isTRUE(plan$inherit)) args$inherit.aes <- FALSE
    args <- c(args, def$extra_args(l))
    p <- p + do.call(getExportedValue(def$package, def$fn), args)
  }

  p <- add_facets(p, spec$facets)
  p <- add_scales(p, spec, data)
  p <- add_coord(p, spec$coord)
  if (length(spec$labels)) p <- p + do.call(ggplot2::labs, as.list(spec$labels))
  p <- p + do.call(getExportedValue("ggplot2", THEMES[[spec$theme]]), theme_base_args(spec$theme_details))
  tw <- theme_tweaks(spec$theme_details)
  if (length(tw$args)) p <- p + do.call(ggplot2::theme, tw$args)
  if (!is.null(spec$legend))
    p <- p + ggplot2::theme(legend.position = spec$legend$position)
  p
}
