test_that("1. scatterplot with two numeric variables", {
  spec <- spec_from_options(base_opts())
  p <- build_plot(spec, test_data())
  expect_s3_class(p, "ggplot")
  expect_equal(layer_classes(p), "GeomPoint")
})

test_that("2. categorical colour mapping", {
  spec <- spec_from_options(base_opts(colour = "product"))
  p <- build_plot(spec, test_data())
  expect_true("colour" %in% names(ggplot2::ggplot_build(p)$data[[1]]))
  expect_equal(length(unique(ggplot2::ggplot_build(p)$data[[1]]$colour)), 2)
})

test_that("3. point + regression layer, in order, with code", {
  spec <- spec_from_options(base_opts(l2_type = "smooth", l2_method = "lm", l2_se = TRUE))
  p <- build_plot(spec, test_data())
  expect_equal(layer_classes(p), c("GeomPoint", "GeomSmooth"))
  code <- spec_to_code(spec)
  expect_match(code, 'geom_smooth(method = "lm", se = TRUE, formula = y ~ x)', fixed = TRUE)
})

test_that("4. point + text layer needs a label variable", {
  bad <- spec_from_options(base_opts(l2_type = "text"))
  expect_error(build_plot(bad, test_data()), "label")
  ok <- spec_from_options(base_opts(l2_type = "text", label = "name"))
  p <- build_plot(ok, test_data())
  expect_equal(layer_classes(p), c("GeomPoint", "GeomText"))
  expect_match(spec_to_code(ok), "geom_text(aes(label = name))", fixed = TRUE)
})

test_that("6. disabling and reordering layers changes the composition", {
  o <- base_opts(l2_type = "smooth", l2_enabled = FALSE)
  expect_equal(layer_classes(build_plot(spec_from_options(o), test_data())), "GeomPoint")

  a <- base_opts(l1_type = "point", l2_type = "line")
  b <- base_opts(l1_type = "line",  l2_type = "point")
  expect_equal(layer_classes(build_plot(spec_from_options(a), test_data())), c("GeomPoint", "GeomLine"))
  expect_equal(layer_classes(build_plot(spec_from_options(b), test_data())), c("GeomLine", "GeomPoint"))
})

test_that("8. missing data gives a warning, not a failure", {
  d <- test_data(); d$viscosity[2] <- NA
  spec <- spec_from_options(base_opts())
  res <- validate_spec(spec, d)
  expect_length(res$errors, 0)
  expect_length(res$warnings, 1)
  expect_s3_class(build_plot(spec, d), "ggplot")
})

test_that("9. empty data is reported", {
  spec <- spec_from_options(base_opts())
  res <- validate_spec(spec, test_data()[0, ])
  expect_match(res$errors, "no rows")
})

test_that("10. invalid mappings and incompatible types are reported", {
  d <- test_data()
  spec <- spec_from_options(base_opts(x = "product", l2_type = "smooth"))
  res <- validate_spec(spec, d)
  expect_match(res$errors, "categorical")
  expect_error(build_plot(spec, d), "categorical")

  res2 <- validate_spec(spec_from_options(base_opts(x = "nope")), d)
  expect_match(res2$errors, "not found")

  res3 <- validate_spec(spec_from_options(base_opts(l1_alpha = 2)), d)
  expect_match(res3$errors, "invalid value")
})

test_that("11. unusual and non-ASCII column names", {
  d <- test_data()
  names(d)[1:2] <- c("temp (\u00b0C)", "viscosit\u00e9")
  spec <- spec_from_options(base_opts(x = "temp (\u00b0C)", y = "viscosit\u00e9",
                                      title = "Titre \u00e9\u00e8 \"quoted\""))
  p <- build_plot(spec, d)
  expect_s3_class(p, "ggplot")
  expect_no_error(ggplot2::ggplot_build(p))
})

test_that("12. generated code reproduces the plot", {
  d <- test_data()
  spec <- spec_from_options(base_opts(
    colour = "product", l1_alpha = 0.7, l1_size = 2,
    l2_type = "smooth", l2_method = "lm", l2_se = FALSE,
    title = "Temperature vs. Viscosity", xlab = "Temperature", theme = "bw"))
  p1 <- build_plot(spec, d)
  env <- list2env(list(data = d), parent = globalenv())
  p2 <- eval(parse(text = spec_to_code(spec)), envir = env)
  expect_equal(ggplot2::ggplot_build(p1)$data, ggplot2::ggplot_build(p2)$data)
  expect_match(spec_to_code(spec), "labs(title = \"Temperature vs. Viscosity\"", fixed = TRUE)
})

test_that("generated code cannot be injected through names or labels", {
  d <- test_data()
  evil <- 'x"); stop("pwned"); ("'
  names(d)[1] <- evil
  spec <- spec_from_options(base_opts(x = evil, title = evil))
  code <- spec_to_code(spec)
  parsed <- parse(text = code)
  expect_length(parsed, 2)          # library(...) and one ggplot expression
  env <- list2env(list(data = d), parent = globalenv())
  expect_no_error(eval(parsed, envir = env))
})
