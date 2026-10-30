# Stage D2: axis transforms/ranges, palettes, coordinates, legend, labels

test_that("axis transformation: plot, code and validation", {
  d <- test_data2()
  spec <- spec_from_options(base_opts(xTrans = "log10", yTrans = "sqrt"))
  expect_code_equivalent(spec, d)
  code <- spec_to_code(spec, d)
  expect_match(code, 'scale_x_continuous(transform = "log10")', fixed = TRUE)
  expect_match(code, 'scale_y_continuous(transform = "sqrt")', fixed = TRUE)
  d2 <- d; d2$temperature[1] <- 0
  expect_match(validate_spec(spec, d2)$errors, "log10 needs positive")
  expect_match(validate_spec(spec_from_options(base_opts(x = "product", xTrans = "log10")), d)$errors, "numeric variable")
})

test_that("axis range: zoom (coord) vs limits (scale)", {
  d <- test_data2()
  z <- spec_from_options(base_opts(xMin = "5", xMax = "30", rangeMode = "zoom"))
  expect_code_equivalent(z, d)
  expect_match(spec_to_code(z, d), "coord_cartesian(xlim = c(5, 30))", fixed = TRUE)
  l <- spec_from_options(base_opts(xMin = "5", rangeMode = "limits"))
  expect_code_equivalent(l, d)
  expect_match(spec_to_code(l, d), "scale_x_continuous(limits = c(5, NA))", fixed = TRUE)
})

test_that("axis range problems are reported", {
  d <- test_data2()
  expect_match(validate_spec(spec_from_options(base_opts(xMin = "abc")), d)$errors, "not a valid number")
  expect_match(validate_spec(spec_from_options(base_opts(xMin = "9", xMax = "3")), d)$errors, "smaller than the maximum")
  expect_match(validate_spec(spec_from_options(base_opts(xMin = "1", xTrans = "log10")), d)$errors, "not supported together")
  ok <- validate_spec(spec_from_options(base_opts(xMin = "1", xTrans = "log10", rangeMode = "limits")), d)
  expect_length(ok$errors, 0)
})

test_that("viridis chooses the discrete or continuous scale from the variable type", {
  d <- test_data2()
  s1 <- spec_from_options(base_opts(colour = "product", colourPalette = "viridis"))
  expect_code_equivalent(s1, d)
  expect_match(spec_to_code(s1, d), "scale_colour_viridis_d()", fixed = TRUE)
  s2 <- spec_from_options(base_opts(colour = "size_v", colourPalette = "viridis"))
  expect_code_equivalent(s2, d)
  expect_match(spec_to_code(s2, d), "scale_colour_viridis_c()", fixed = TRUE)
})

test_that("brewer / blues / greys palettes for fill", {
  d <- test_data2()
  s <- spec_from_options(base_opts(x = "product", l1_type = "boxplot", fill = "site", fillPalette = "dark2"))
  expect_code_equivalent(s, d)
  expect_match(spec_to_code(s, d), 'scale_fill_brewer(palette = "Dark2")', fixed = TRUE)
  s2 <- spec_from_options(base_opts(colour = "size_v", colourPalette = "blues"))
  expect_code_equivalent(s2, d)
  expect_match(spec_to_code(s2, d), 'scale_colour_distiller(palette = "Blues")', fixed = TRUE)
  s3 <- spec_from_options(base_opts(colour = "product", colourPalette = "greys"))
  expect_code_equivalent(s3, d)
})

test_that("palette misuse is reported", {
  d <- test_data2()
  expect_match(validate_spec(spec_from_options(base_opts(colour = "size_v", colourPalette = "set1")), d)$errors, "needs a categorical")
  expect_match(validate_spec(spec_from_options(base_opts(colour = "size_v", colourPalette = "manual", colourValues = "red, blue")), d)$errors, "needs a categorical")
  w <- validate_spec(spec_from_options(base_opts(colourPalette = "viridis")), d)
  expect_length(w$errors, 0)
  expect_true(any(grepl("palette is ignored", w$warnings)))
})

test_that("manual colours: parsed, validated, matched in code", {
  d <- test_data2()
  s <- spec_from_options(base_opts(colour = "product", colourPalette = "manual", colourValues = "red, #0000FF"))
  expect_equal(s$scales$colour$values, c("red", "#0000FF"))
  expect_code_equivalent(s, d)
  expect_match(spec_to_code(s, d), 'scale_colour_manual(values = c("red", "#0000FF"))', fixed = TRUE)
  few <- spec_from_options(base_opts(colour = "product", colourPalette = "manual", colourValues = "red"))
  expect_match(validate_spec(few, d)$errors, "has 1 colour")
  bad <- spec_from_options(base_opts(colour = "product", colourPalette = "manual", colourValues = "red, notacolour"))
  expect_match(validate_spec(bad, d)$errors, "not a valid colour")
  none <- spec_from_options(base_opts(colour = "product", colourPalette = "manual"))
  expect_match(validate_spec(none, d)$errors, "enter colours")
})

test_that("code for palettes cannot be injected", {
  d <- test_data2()
  s <- spec_from_options(base_opts(colour = "product", colourPalette = "manual", colourValues = "red, blue"))
  s$scales$colour$values <- c('x"); stop("pwned"); ("', "blue")   # bypass validation on purpose
  expect_length(parse(text = spec_to_code(s, d)), 2)
})

test_that("code generation without data fails clearly when a palette needs it", {
  s <- spec_from_options(base_opts(colour = "product", colourPalette = "viridis"))
  expect_error(spec_to_code(s), "data. is required")
})

test_that("coordinate systems", {
  d <- test_data2()
  f <- spec_from_options(base_opts(coordType = "flip"))
  p <- expect_code_equivalent(f, d)
  expect_s3_class(p$coordinates, "CoordFlip")
  expect_match(spec_to_code(f, d), "coord_flip()", fixed = TRUE)
  x <- spec_from_options(base_opts(coordType = "fixed", xMin = "0", xMax = "50"))
  expect_code_equivalent(x, d)
  expect_match(spec_to_code(x, d), "coord_fixed(xlim = c(0, 50))", fixed = TRUE)
})

test_that("legend position, legend titles, subtitle and caption", {
  d <- test_data2()
  s <- spec_from_options(base_opts(colour = "product", legendPosition = "bottom",
                                   colourTitle = "Product", subtitle = "Sub", caption = "Cap"))
  expect_code_equivalent(s, d)
  code <- spec_to_code(s, d)
  expect_match(code, 'theme(legend.position = "bottom")', fixed = TRUE)
  expect_match(code, 'labs(subtitle = "Sub", caption = "Cap", colour = "Product")', fixed = TRUE)
  p <- build_plot(s, d)
  expect_equal(p$theme$legend.position, "bottom")
  hide <- spec_from_options(base_opts(colour = "product", legendPosition = "none"))
  expect_equal(build_plot(hide, d)$theme$legend.position, "none")
  # default position emits nothing
  expect_null(spec_from_options(base_opts(legendPosition = "right"))$legend)
})

test_that("everything combined still matches its code", {
  d <- test_data2()
  s <- spec_from_options(base_opts(
    colour = "product", l2_type = "smooth", facetType = "wrap", facetVar1 = "site",
    xTrans = "sqrt", colourPalette = "viridis", legendPosition = "top",
    title = "All together", theme = "classic"))
  expect_length(validate_spec(s, d)$errors, 0)
  expect_code_equivalent(s, d)
})
