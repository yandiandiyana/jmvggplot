# Stage D1: extra mappings, extra geoms, facets

test_that("extra global mappings are passed through and appear in code", {
  d <- test_data2()
  spec <- spec_from_options(base_opts(colour = "product", fill = "site", shape = "site",
                                      sizeBy = "size_v", alphaBy = "size_v", group = "product"))
  expect_equal(names(spec$mappings),
               c("x", "y", "colour", "fill", "shape", "size", "alpha", "group"))
  expect_code_equivalent(spec, d)
  expect_match(spec_to_code(spec), "aes(x = temperature, y = viscosity, colour = product, fill = site, shape = site, size = size_v, alpha = size_v, group = product)", fixed = TRUE)
})

test_that("shape must be categorical", {
  res <- validate_spec(spec_from_options(base_opts(shape = "temperature")), test_data2())
  expect_match(res$errors, "Shape needs a categorical")
})

test_that("fixed alpha/size plus the same mapping gives a warning, not silence", {
  spec <- spec_from_options(base_opts(alphaBy = "size_v", l1_alpha = 0.5))
  res <- validate_spec(spec, test_data2())
  expect_length(res$errors, 0)
  expect_true(any(grepl("overrides the 'alpha' mapping", res$warnings)))
})

test_that("histogram drops a global y, says so, and code matches", {
  d <- test_data2()
  spec <- spec_from_options(base_opts(l1_type = "histogram", l1_bins = 10))
  res <- validate_spec(spec, d)
  expect_length(res$errors, 0)
  expect_true(any(grepl("not used by this layer type", res$warnings)))
  p <- expect_code_equivalent(spec, d)
  expect_equal(layer_classes(p), "GeomBar")
  expect_match(spec_to_code(spec), "geom_histogram(aes(x = temperature), bins = 10, inherit.aes = FALSE)", fixed = TRUE)
})

test_that("histogram without a global y inherits normally (clean code)", {
  d <- test_data2()
  spec <- spec_from_options(base_opts(y = NULL, colour = NULL, l1_type = "histogram"))
  expect_match(spec_to_code(spec), "geom_histogram()", fixed = TRUE)
  expect_code_equivalent(spec, d)
})

test_that("histogram and density need numeric x; bar accepts categorical x", {
  d <- test_data2()
  expect_match(validate_spec(spec_from_options(base_opts(x = "product", l1_type = "histogram")), d)$errors, "categorical")
  expect_match(validate_spec(spec_from_options(base_opts(x = "product", l1_type = "density")), d)$errors, "categorical")
  spec <- spec_from_options(base_opts(x = "product", l1_type = "bar", fill = "site"))
  expect_length(validate_spec(spec, d)$errors, 0)
  p <- expect_code_equivalent(spec, d)
  expect_equal(layer_classes(p), "GeomBar")
})

test_that("column, density, boxplot, violin build and match their code", {
  d <- test_data2()
  expect_code_equivalent(spec_from_options(base_opts(x = "product", l1_type = "col")), d)
  p <- expect_code_equivalent(spec_from_options(base_opts(l1_type = "density", l1_alpha = 0.4, fill = "product")), d)
  expect_equal(layer_classes(p), "GeomDensity")
  p <- expect_code_equivalent(spec_from_options(base_opts(x = "product", l1_type = "boxplot", fill = "site")), d)
  expect_equal(layer_classes(p), "GeomBoxplot")
  p <- expect_code_equivalent(spec_from_options(base_opts(x = "product", l1_type = "violin")), d)
  expect_equal(layer_classes(p), "GeomViolin")
})

test_that("boxplot / violin / col need a numeric y", {
  d <- test_data2()
  expect_match(validate_spec(spec_from_options(base_opts(x = "temperature", y = "product", l1_type = "boxplot")), d)$errors, "numeric")
  expect_match(validate_spec(spec_from_options(base_opts(y = NULL, l1_type = "violin")), d)$errors, "needs these aesthetics")
})

test_that("reference lines carry their position and combine with points", {
  d <- test_data2()
  spec <- spec_from_options(base_opts(l2_type = "hline", l2_intercept = 5.5,
                                      l3_type = "vline", l3_intercept = 20,
                                      l4_type = "abline", l4_intercept = 4, l4_slope = 0.1))
  p <- expect_code_equivalent(spec, d)
  expect_equal(layer_classes(p), c("GeomPoint", "GeomHline", "GeomVline", "GeomAbline"))
  code <- spec_to_code(spec)
  expect_match(code, "geom_hline(yintercept = 5.5)", fixed = TRUE)
  expect_match(code, "geom_vline(xintercept = 20)", fixed = TRUE)
  expect_match(code, "geom_abline(intercept = 4, slope = 0.1)", fixed = TRUE)
})

test_that("facet wrap and facet grid build, match code, and make the right panels", {
  d <- test_data2()
  w <- spec_from_options(base_opts(facetType = "wrap", facetVar1 = "product"))
  p <- expect_code_equivalent(w, d)
  expect_s3_class(p$facet, "FacetWrap")
  expect_equal(nrow(ggplot2::ggplot_build(p)$layout$layout), 2)
  expect_match(spec_to_code(w), "facet_wrap(vars(product))", fixed = TRUE)

  g <- spec_from_options(base_opts(facetType = "grid", facetVar1 = "product", facetVar2 = "site",
                                   facetScales = "free"))
  p <- expect_code_equivalent(g, d)
  expect_s3_class(p$facet, "FacetGrid")
  expect_equal(nrow(ggplot2::ggplot_build(p)$layout$layout), 4)
  expect_match(spec_to_code(g), 'facet_grid(rows = vars(product), cols = vars(site), scales = "free")', fixed = TRUE)

  w2 <- spec_from_options(base_opts(facetType = "wrap", facetVar1 = "product", facetCols = 1))
  expect_match(spec_to_code(w2), "facet_wrap(vars(product), ncol = 1)", fixed = TRUE)
  expect_code_equivalent(w2, d)
})

test_that("facet validation reports problems", {
  d <- test_data2()
  expect_match(validate_spec(spec_from_options(base_opts(facetType = "wrap")), d)$errors, "needs a facet variable")
  expect_match(validate_spec(spec_from_options(base_opts(facetType = "grid")), d)$errors, "rows variable")
  expect_match(validate_spec(spec_from_options(base_opts(facetType = "wrap", facetVar1 = "temperature")), d)$errors, "categorical")
  res <- validate_spec(spec_from_options(base_opts(facetType = "wrap", facetVar1 = "product", facetVar2 = "site")), d)
  expect_length(res$errors, 0)
  expect_true(any(grepl("ignored for facet wrap", res$warnings)))
  expect_match(validate_spec(spec_from_options(base_opts(facetType = "wrap", facetVar1 = "nope")), d)$errors, "not found")
})

test_that("facet variables with awkward names are safe in plot and code", {
  d <- test_data2()
  names(d)[names(d) == "product"] <- "prod \u00e9 (\"q\")"
  nm <- "prod \u00e9 (\"q\")"
  spec <- spec_from_options(base_opts(facetType = "wrap", facetVar1 = nm, colour = nm))
  expect_length(parse(text = spec_to_code(spec)), 2)
  expect_code_equivalent(spec, d)
})

test_that("layer order matters for composition with the new geoms", {
  d <- test_data2()
  a <- spec_from_options(base_opts(l2_type = "hline", l2_intercept = 5))
  b <- spec_from_options(base_opts(l1_type = "hline", l1_intercept = 5, l2_type = "point"))
  expect_equal(layer_classes(build_plot(a, d)), c("GeomPoint", "GeomHline"))
  expect_equal(layer_classes(build_plot(b, d)), c("GeomHline", "GeomPoint"))
})
