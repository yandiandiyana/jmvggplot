# Stage D3b: summary statistics (stat_summary)

stat_class <- function(p, i = 1) class(p$layers[[i]]$stat)[1]

test_that("mean +- SE: pointrange, code and values", {
  d <- test_data2()
  s <- spec_from_options(base_opts(x = "product", l1_type = "summary", l1_stat = "mean_se"))
  p <- expect_code_equivalent(s, d)
  expect_equal(stat_class(p), "StatSummary")
  expect_equal(layer_classes(p), "GeomPointrange")
  expect_match(spec_to_code(s, d), 'stat_summary(geom = "pointrange", fun.data = mean_se)', fixed = TRUE)
  b <- ggplot2::ggplot_build(p)$data[[1]]
  a <- d$viscosity[d$product == "A"]
  expect_equal(b$y[1], mean(a))
  expect_equal(b$ymin[1], mean(a) - sqrt(stats::var(a) / length(a)))
})

test_that("mean +- SD and median with IQR give the stated values", {
  d <- test_data2()
  a <- d$viscosity[d$product == "A"]
  sd1 <- spec_from_options(base_opts(x = "product", l1_type = "summary", l1_stat = "mean_sd"))
  b <- ggplot2::ggplot_build(expect_code_equivalent(sd1, d))$data[[1]]
  expect_equal(b$ymin[1], mean(a) - stats::sd(a))
  expect_equal(b$ymax[1], mean(a) + stats::sd(a))
  expect_match(spec_to_code(sd1, d),
               "stat_summary(geom = \"pointrange\", fun = mean, fun.min = function(x) mean(x) - sd(x), fun.max = function(x) mean(x) + sd(x))",
               fixed = TRUE)
  iq <- spec_from_options(base_opts(x = "product", l1_type = "summary", l1_stat = "median_iqr"))
  b2 <- ggplot2::ggplot_build(expect_code_equivalent(iq, d))$data[[1]]
  expect_equal(b2$y[1], stats::median(a))
  expect_equal(b2$ymin[1], unname(stats::quantile(a, 0.25)))
  expect_equal(b2$ymax[1], unname(stats::quantile(a, 0.75)))
})

test_that("statistics without a range use a point", {
  d <- test_data2()
  for (st in c("mean", "median")) {
    s <- spec_from_options(base_opts(x = "product", l1_type = "summary", l1_stat = st))
    p <- expect_code_equivalent(s, d)
    expect_equal(layer_classes(p), "GeomPoint")
    expect_match(spec_to_code(s, d), paste0('stat_summary(geom = "point", fun = ', st, ")"), fixed = TRUE)
  }
})

test_that("summary error bars with width, combined with a summary point layer", {
  d <- test_data2()
  s <- spec_from_options(base_opts(x = "product", l1_type = "summary", l1_stat = "mean",
                                   l2_type = "summary_errorbar", l2_stat = "mean_se", l2_width = 0.2))
  p <- expect_code_equivalent(s, d)
  expect_equal(layer_classes(p), c("GeomPoint", "GeomErrorbar"))
  expect_match(spec_to_code(s, d), 'stat_summary(width = 0.2, geom = "errorbar", fun.data = mean_se)', fixed = TRUE)
})

test_that("error bars need a statistic with a range", {
  d <- test_data2()
  s <- spec_from_options(base_opts(x = "product", l1_type = "summary_errorbar", l1_stat = "mean"))
  expect_match(validate_spec(s, d)$errors, "need a statistic that has a range")
  expect_error(build_plot(s, d), "range")
})

test_that("summary bars (mean) with dodge and a grouping colour", {
  d <- test_data2()
  s <- spec_from_options(base_opts(x = "product", colour = NULL, fill = "site", l1_type = "summary_bar",
                                   l1_stat = "mean", l1_position = "dodge"))
  p <- expect_code_equivalent(s, d)
  expect_equal(stat_class(p), "StatSummary")
  expect_match(spec_to_code(s, d), 'stat_summary(position = "dodge", geom = "col", fun = mean)', fixed = TRUE)
})

test_that("summary needs a numeric y; stat setting on other layers is reported", {
  d <- test_data2()
  expect_match(validate_spec(spec_from_options(base_opts(x = "temperature", y = "product", l1_type = "summary")), d)$errors, "numeric")
  w <- validate_spec(spec_from_options(base_opts(l1_type = "point", l1_stat = "median")), d)
  expect_length(w$errors, 0)
  expect_true(any(grepl("'stat' setting is not used", w$warnings)))
})

test_that("summary layers work with facets, palettes and the layer order", {
  d <- test_data2()
  s <- spec_from_options(base_opts(
    x = "product", colour = "site", l1_type = "point", l1_alpha = 0.3,
    l2_type = "summary", l2_stat = "mean_sd", l2_position = "dodge",
    facetType = "wrap", facetVar1 = "site", colourPalette = "viridis"))
  expect_length(validate_spec(s, d)$errors, 0)
  p <- expect_code_equivalent(s, d)
  expect_equal(layer_classes(p), c("GeomPoint", "GeomPointrange"))
})

test_that("dodge on layers without a width really separates groups and does not warn", {
  d <- test_data2()
  s <- spec_from_options(base_opts(
    x = "product", colour = "site", l1_type = "summary", l1_stat = "mean_se", l1_position = "dodge",
    l2_type = "summary_errorbar", l2_stat = "mean_se", l2_position = "dodge", l2_width = 0.2))
  expect_no_warning(b <- ggplot2::ggplot_build(build_plot(s, d)))
  expect_equal(length(unique(round(b$data[[1]]$x, 3))), 4)      # 2 products x 2 sites
  expect_equal(round(b$data[[1]]$x, 3), round(b$data[[2]]$x, 3)) # points and error bars line up
  code <- spec_to_code(s, d)
  expect_match(code, "position = position_dodge(width = 0.9)", fixed = TRUE)
  expect_code_equivalent(s, d)
})

test_that("dodge keeps the plain string for layers that have their own width", {
  d <- test_data2()
  s <- spec_from_options(base_opts(x = "product", y = NULL, l1_type = "bar", fill = "site", l1_position = "dodge"))
  expect_match(spec_to_code(s, d), 'geom_bar(position = "dodge")', fixed = TRUE)
})
