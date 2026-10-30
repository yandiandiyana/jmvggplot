# How a layer receives aesthetics. Shared by validation, plotting and code
# generation so the three always agree.

# Aesthetics the layer will actually see (for validation).
effective_mapping <- function(spec, layer) {
  def <- GEOM_REGISTRY[[layer$type]]
  own <- as.list(layer$mappings)
  if (!isTRUE(layer$inherit_aes)) return(own)
  eff <- utils::modifyList(as.list(spec$mappings), own)
  eff[intersect(names(eff), def$drop)] <- NULL
  eff
}

# What to pass to ggplot2 for this layer.
# Normal case: inherit global aesthetics, add layer-specific ones.
# If a global aesthetic cannot be used by this layer type (def$drop), ggplot2 would
# fail, so the layer gets an explicit mapping without it and inherit.aes = FALSE.
layer_plan <- function(spec, layer) {
  def <- GEOM_REGISTRY[[layer$type]]
  global <- as.list(spec$mappings)
  own <- as.list(layer$mappings)
  if (isTRUE(layer$inherit_aes) && any(def$drop %in% names(global))) {
    keep <- global[setdiff(names(global), def$drop)]
    return(list(mapping = utils::modifyList(keep, own), inherit = FALSE))
  }
  list(mapping = own, inherit = isTRUE(layer$inherit_aes))
}

# Which scale function/arguments a colour or fill palette becomes. Depends on whether
# the mapped variable is numeric (continuous scale) or categorical (discrete scale),
# so it needs the data. Returns NULL if nothing applies (aesthetic unmapped, or the
# palette cannot be used for that kind of variable; validation reports the latter).
palette_plan <- function(spec, aes, data) {
  sc <- spec$scales[[aes]]
  var <- spec$mappings[[aes]]
  if (is.null(sc) || is.null(var)) return(NULL)
  kind <- if (is.numeric(data[[var]])) "continuous" else "discrete"
  entry <- PALETTES[[sc$palette]][[kind]]
  if (is.null(entry)) return(NULL)
  args <- entry$args
  if (identical(sc$palette, "manual")) args$values <- sc$values
  list(fn = sprintf(entry$fn, aes), args = args, kind = kind)
}
