# Stage D2b: theme details

eval_code <- function(spec, d) {
  eval(parse(text = spec_to_code(spec, d)), envir = list2env(list(data = d), parent = globalenv()))
}

test_that("untouched theme emits nothing extra", {
  d <- test_data2()
  s <- spec_from_options(base_opts(baseSize = 11, baseFamily = "default", xTextAngle = "default"))
  expect_null(s$theme_details)
  code <- spec_to_code(s, d)
  expect_match(code, "theme_minimal()", fixed = TRUE)
  expect_false(grepl("theme(", code, fixed = TRUE))
})

test_that("base size and family go into the theme function", {
  d <- test_data2()
  s <- spec_from_options(base_opts(baseSize = 14, baseFamily = "serif"))
  expect_equal(s$theme_details, list(base_size = 14, base_family = "serif"))
  expect_match(spec_to_code(s, d), 'theme_minimal(base_size = 14, base_family = "serif")', fixed = TRUE)
  p1 <- build_plot(s, d)
  p2 <- eval_code(s, d)
  expect_equal(p1$theme$text$size, 14)
  expect_equal(p1$theme$text$family, "serif")
  expect_equal(p2$theme$text$size, 14)
  expect_code_equivalent(s, d)
})

test_that("grid, ticks, text angle, title, backgrounds and margin: plot matches code", {
  d <- test_data2()
  s <- spec_from_options(base_opts(
    hideGridMajor = TRUE, hideGridMinor = TRUE, hideTicks = TRUE, xTextAngle = "deg45", boldTitle = TRUE,
    plotFill = "white", panelFill = "grey95", plotMargin = "10", title = "T"))
  expect_length(validate_spec(s, d)$errors, 0)
  code <- spec_to_code(s, d)
  expect_match(code, paste0(
    'theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(), ',
    'axis.ticks = element_blank(), axis.text.x = element_text(angle = 45, hjust = 1), ',
    'plot.title = element_text(face = "bold"), ',
    'plot.background = element_rect(fill = "white", colour = NA), ',
    'panel.background = element_rect(fill = "grey95", colour = NA), ',
    'plot.margin = margin(10, 10, 10, 10))'), fixed = TRUE)
  p1 <- build_plot(s, d)
  p2 <- eval_code(s, d)
  for (n in c("panel.grid.major", "panel.grid.minor", "axis.ticks", "axis.text.x", "plot.title",
              "plot.background", "panel.background", "plot.margin"))
    expect_equal(p1$theme[[n]], p2$theme[[n]], info = n)
  expect_s3_class(p1$theme[["panel.grid.major"]], "element_blank")
  expect_equal(p1$theme[["axis.text.x"]]$angle, 45)
  expect_code_equivalent(s, d)
})

test_that("x text angle 90 uses a vertical justification", {
  d <- test_data2()
  s <- spec_from_options(base_opts(xTextAngle = "deg90"))
  expect_match(spec_to_code(s, d), "axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5)", fixed = TRUE)
  expect_equal(build_plot(s, d)$theme[["axis.text.x"]]$angle, 90)
})

test_that("theme details combine with palettes, legend position and facets", {
  d <- test_data2()
  s <- spec_from_options(base_opts(
    colour = "product", colourPalette = "viridis", legendPosition = "bottom",
    facetType = "wrap", facetVar1 = "site", baseSize = 13, hideGridMinor = TRUE, theme = "bw"))
  expect_length(validate_spec(s, d)$errors, 0)
  code <- spec_to_code(s, d)
  expect_match(code, "theme_bw(base_size = 13)", fixed = TRUE)
  expect_match(code, "theme(panel.grid.minor = element_blank())", fixed = TRUE)
  expect_match(code, 'theme(legend.position = "bottom")', fixed = TRUE)
  expect_code_equivalent(s, d)
})

test_that("invalid theme settings are reported", {
  d <- test_data2()
  err <- function(...) validate_spec(spec_from_options(base_opts(...)), d)$errors
  expect_match(err(baseSize = 100), "between 4 and 40")
  expect_match(err(baseSize = 2), "between 4 and 40")
  expect_match(err(plotFill = "notacolour"), "Not a valid colour for the plot background")
  expect_match(err(panelFill = "#12345"), "Not a valid colour for the panel background")
  expect_match(err(plotMargin = "abc"), "not a valid number")
  expect_match(err(plotMargin = "-5"), "between 0 and 200")
  expect_match(err(plotMargin = "500"), "between 0 and 200")
  s <- spec_from_options(base_opts(baseFamily = "serif")); s$theme_details$base_family <- "comic"
  expect_match(validate_spec(s, d)$errors, "Unknown font family")
})

test_that("code for theme details cannot be injected", {
  d <- test_data2()
  s <- spec_from_options(base_opts(plotFill = "white"))
  s$theme_details$plot_fill <- 'x"); stop("pwned"); ("'      # bypass validation on purpose
  expect_length(parse(text = spec_to_code(s, d)), 2)
})
