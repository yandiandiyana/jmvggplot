# Extension mechanism: a layer may declare the R package it needs (none do in this version)

test_that("a layer whose package is missing reports it instead of failing", {
  def <- list(package = "surelyNotInstalledPackageXyz")
  expect_match(package_problem(def), "needs the R package 'surelyNotInstalledPackageXyz'")
  expect_null(package_problem(list(package = "ggplot2")))
  expect_null(package_problem(list()))
})

test_that("every registered layer currently uses ggplot2 only", {
  pkgs <- unique(vapply(GEOM_REGISTRY, function(d) d$package, ""))
  expect_equal(pkgs, "ggplot2")
})

test_that("the generated code only loads ggplot2 for the built-in layers", {
  d <- test_data2()
  code <- spec_to_code(spec_from_options(base_opts()), d)
  expect_match(code, "^library\\(ggplot2\\)\n\n")
})
