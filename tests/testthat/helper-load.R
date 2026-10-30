# Normally tests/run_standalone.R loads R/ into a fresh environment first (preferred, so stale
# functions from an earlier session are never used). This is only a fallback if test_dir()
# is called directly and the module functions are not visible at all.
if (!exists("build_plot", mode = "function")) {
  for (f in c("utils.R", "registry.R", "plan.R", "spec.R", "validate.R", "build_plot.R", "spec_to_code.R"))
    source(file.path("..", "..", "R", f), local = FALSE)
}

test_data <- function() {
  data.frame(
    temperature = c(10, 20, 30, 40, 50, 60),
    viscosity   = c(5.1, 4.2, 3.9, 3.0, 2.2, 1.9),
    product     = factor(c("A", "A", "A", "B", "B", "B")),
    name        = c("a", "b", "c", "d", "e", "f"),
    stringsAsFactors = FALSE
  )
}

base_opts <- function(...) {
  utils::modifyList(
    list(x = "temperature", y = "viscosity", theme = "minimal", l1_type = "point"),
    list(...)
  )
}

layer_classes <- function(p) unname(vapply(p$layers, function(l) class(l$geom)[1], ""))

# Larger deterministic dataset (no RNG) for distribution / facet tests
test_data2 <- function() {
  n <- 40
  data.frame(
    temperature = seq_len(n),
    viscosity   = sin(seq_len(n) / 4) + seq_len(n) / 10 + 5,
    product     = factor(rep(c("A", "B"), each = n / 2)),
    site        = factor(rep(c("N", "S"), times = n / 2)),
    size_v      = seq_len(n) %% 7 + 1,
    lo          = sin(seq_len(n) / 4) + seq_len(n) / 10 + 4.5,
    hi          = sin(seq_len(n) / 4) + seq_len(n) / 10 + 5.5,
    xe          = seq_len(n) + 1,
    ye          = sin(seq_len(n) / 4) + seq_len(n) / 10 + 5.5,
    stringsAsFactors = FALSE
  )
}

# Evaluate generated code and compare with the directly built plot.
expect_code_equivalent <- function(spec, data) {
  p1 <- build_plot(spec, data)
  env <- list2env(list(data = data), parent = globalenv())
  p2 <- eval(parse(text = spec_to_code(spec, data)), envir = env)
  b1 <- ggplot2::ggplot_build(p1)
  b2 <- ggplot2::ggplot_build(p2)
  testthat::expect_equal(b1$data, b2$data)
  testthat::expect_equal(nrow(b1$layout$layout), nrow(b2$layout$layout))
  testthat::expect_equal(b1$layout$panel_params[[1]]$x.range, b2$layout$panel_params[[1]]$x.range)
  testthat::expect_equal(b1$layout$panel_params[[1]]$y.range, b2$layout$panel_params[[1]]$y.range)
  invisible(p1)
}
