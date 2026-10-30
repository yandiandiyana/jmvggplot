# Syntax-mode / plain-R check (manual; needs R with devtools + jmvcore; jamovi is NOT needed).
# Run from the project root:
#   1. jmvtools::prepare()      # (re)creates R/layerplot.h.R from the yaml files
#   2. source("tests/manual/syntax_check.R")
# It calls the generated analysis function the way jamovi's syntax mode does, outside jamovi.
# It does NOT test jamovi's syntax mode itself: see docs/RELEASE.md, section "Syntax mode".
stopifnot(file.exists("R/layerplot.h.R"))
devtools::load_all(".", quiet = TRUE)

if (!file.exists("data/penguins.csv")) source("tools/add_example_data.R")
d <- read.csv("data/penguins.csv", stringsAsFactors = TRUE, na.strings = c("", "NA"))

res <- layerPlot(data = d, x = "flipper_length_mm", y = "body_mass_g", colour = "species",
                 l1_type = "point", l2_type = "smooth", l2_method = "lm",
                 title = "Syntax check", theme = "bw")
cat("class:", class(res)[1], "\n")
cat("---- generated code ----\n")
cat(res$code$content, "\n")
cat("---- messages ----\n")
print(res$messages$content)
cat("Done. If no error appeared above, the analysis function runs from plain R.\n")
