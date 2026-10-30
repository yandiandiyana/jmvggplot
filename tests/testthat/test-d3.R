# Stage D3: path, area, ribbon, errorbar, segment, label; position, width

test_that("path, area, label build and match their code", {
  d <- test_data2()
  p <- expect_code_equivalent(spec_from_options(base_opts(l1_type = "path")), d)
  expect_equal(layer_classes(p), "GeomPath")
  expect_match(spec_to_code(spec_from_options(base_opts(l1_type = "path")), d), "geom_path()", fixed = TRUE)

  a <- spec_from_options(base_opts(l1_type = "area", fill = "product", l1_position = "fill"))
  p <- expect_code_equivalent(a, d)
  expect_equal(layer_classes(p), "GeomArea")
  expect_match(spec_to_code(a, d), 'geom_area(position = "fill")', fixed = TRUE)

  l <- spec_from_options(base_opts(l2_type = "label", label = "product"))
  p <- expect_code_equivalent(l, d)
  expect_equal(layer_classes(p), c("GeomPoint", "GeomLabel"))
  expect_match(spec_to_code(l, d), "geom_label(aes(label = product))", fixed = TRUE)
})

test_that("ribbon uses its own min/max variables and keeps layer order", {
  d <- test_data2()
  s <- spec_from_options(base_opts(l1_type = "ribbon", l2_type = "point", ymin = "lo", ymax = "hi", l1_alpha = 0.3))
  p <- expect_code_equivalent(s, d)
  expect_equal(layer_classes(p), c("GeomRibbon", "GeomPoint"))
  expect_match(spec_to_code(s, d), "geom_ribbon(aes(ymin = lo, ymax = hi), alpha = 0.3)", fixed = TRUE)
})

test_that("ribbon / errorbar / segment report missing or wrong-type variables", {
  d <- test_data2()
  r <- validate_spec(spec_from_options(base_opts(l2_type = "ribbon")), d)
  expect_match(r$errors, "needs these aesthetics mapped: ymin, ymax")
  expect_match(r$errors, "choose a variable for ymin, ymax")
  expect_match(validate_spec(spec_from_options(base_opts(l2_type = "ribbon", ymin = "product", ymax = "hi")), d)$errors, "numeric")
  expect_match(validate_spec(spec_from_options(base_opts(l2_type = "segment")), d)$errors, "xend, yend")
})

test_that("errorbar with width and dodge", {
  d <- test_data2()
  s <- spec_from_options(base_opts(l2_type = "errorbar", ymin = "lo", ymax = "hi", l2_width = 0.5, l2_position = "dodge"))
  p <- expect_code_equivalent(s, d)
  expect_equal(layer_classes(p), c("GeomPoint", "GeomErrorbar"))
  expect_match(spec_to_code(s, d), 'geom_errorbar(aes(ymin = lo, ymax = hi), width = 0.5, position = position_dodge(width = 0.9))', fixed = TRUE)
})

test_that("segment uses xend / yend", {
  d <- test_data2()
  s <- spec_from_options(base_opts(l2_type = "segment", xend = "xe", yend = "ye"))
  p <- expect_code_equivalent(s, d)
  expect_equal(layer_classes(p), c("GeomPoint", "GeomSegment"))
  expect_match(spec_to_code(s, d), "geom_segment(aes(xend = xe, yend = ye))", fixed = TRUE)
})

test_that("position adjustments on bars: stack (default), dodge, fill", {
  d <- test_data2()
  for (pos in c("stack", "dodge", "fill", "identity")) {
    s <- spec_from_options(base_opts(x = "product", y = NULL, l1_type = "bar", fill = "site", l1_position = pos))
    expect_length(validate_spec(s, d)$errors, 0)
    expect_code_equivalent(s, d)
    expect_match(spec_to_code(s, d), paste0('geom_bar(position = "', pos, '")'), fixed = TRUE)
  }
  none <- spec_from_options(base_opts(x = "product", y = NULL, l1_type = "bar", fill = "site"))
  expect_match(spec_to_code(none, d), "geom_bar()", fixed = TRUE)
  w <- spec_from_options(base_opts(x = "product", y = NULL, l1_type = "bar", l1_width = 0.4))
  expect_match(spec_to_code(w, d), "geom_bar(width = 0.4)", fixed = TRUE)
  expect_code_equivalent(w, d)
})

test_that("jitter position on points (random, so not compared with its code)", {
  d <- test_data2()
  s <- spec_from_options(base_opts(l1_position = "jitter"))
  p <- build_plot(s, d)
  expect_true(inherits(p$layers[[1]]$position, "PositionJitter"))
  expect_match(spec_to_code(s, d), 'geom_point(position = "jitter")', fixed = TRUE)
})

test_that("incompatible position / setting combinations are reported", {
  d <- test_data2()
  e1 <- validate_spec(spec_from_options(base_opts(l1_position = "stack")), d)$errors
  expect_match(e1, "invalid value for 'position'")
  expect_match(e1, "allowed: identity, jitter, dodge")
  expect_match(validate_spec(spec_from_options(base_opts(l1_type = "line", l1_position = "dodge")), d)$errors,
               "does not support a position adjustment")
  w <- validate_spec(spec_from_options(base_opts(l1_type = "histogram", l1_size = 3)), d)
  expect_length(w$errors, 0)
  expect_true(any(grepl("'size' setting is not used", w$warnings)))
  w2 <- validate_spec(spec_from_options(base_opts(l1_type = "point", l1_width = 2)), d)
  expect_true(any(grepl("'width' setting is not used", w2$warnings)))
})

test_that("all new layer types survive being combined with facets and palettes", {
  d <- test_data2()
  s <- spec_from_options(base_opts(
    colour = "product", l2_type = "ribbon", ymin = "lo", ymax = "hi", l2_alpha = 0.2,
    l3_type = "path", facetType = "wrap", facetVar1 = "site", colourPalette = "viridis"))
  expect_length(validate_spec(s, d)$errors, 0)
  expect_code_equivalent(s, d)
})
