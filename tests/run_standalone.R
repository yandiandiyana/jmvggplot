# Run the unit tests without jamovi (from the project root):
#   Rscript tests/run_standalone.R
# Requires: ggplot2, testthat.
# Always loads the CURRENT R/ files into a fresh environment, so functions left over
# from an earlier run in the same R session can never be used by mistake.
env <- new.env(parent = globalenv())
for (f in c("utils.R", "registry.R", "plan.R", "spec.R", "validate.R", "build_plot.R", "spec_to_code.R"))
  sys.source(file.path("R", f), envir = env)
testthat::test_dir("tests/testthat", env = env, reporter = "summary", stop_on_failure = TRUE)
