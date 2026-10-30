# Adds the example dataset to the module so it shows up in jamovi's Data Library
# (hamburger menu -> Open -> Data Library -> jmvggplot).
#
# Run once from the project root, in R:
#   install.packages("palmerpenguins")
#   source("tools/add_example_data.R")
#
# It (1) writes data/penguins.csv from the palmerpenguins package (data licence: CC0),
#    (2) registers the dataset in a `datasets:` block of jamovi/0000.yaml (skipped if one exists).
# Then run jmvtools::install().

if (!requireNamespace("palmerpenguins", quietly = TRUE))
  stop("Please run install.packages('palmerpenguins') first.", call. = FALSE)
if (!file.exists("jamovi/0000.yaml"))
  stop("Run this from the module's root folder (the one containing jamovi/0000.yaml).", call. = FALSE)

dir.create("data", showWarnings = FALSE)
d <- as.data.frame(palmerpenguins::penguins)
write.csv(d, "data/penguins.csv", row.names = FALSE, na = "")   # missing values stay blank
if (!file.exists("data/penguins.csv") || nrow(read.csv("data/penguins.csv")) != nrow(d))
  stop("Writing data/penguins.csv failed.", call. = FALSE)
cat("Wrote data/penguins.csv:", nrow(d), "rows,", ncol(d), "columns\n")

manifest <- "jamovi/0000.yaml"
txt <- readLines(manifest, warn = FALSE)
if (any(grepl("^datasets:", txt))) {
  cat("jamovi/0000.yaml already has a datasets: block; left unchanged.\n")
} else {
  block <- c(
    "datasets:",
    "  - name: penguins",
    "    path: penguins.csv",
    "    description: \"Size measurements of 344 penguins of three species (palmerpenguins package, CC0 licence)\"",
    "    tags:",
    "      - plots",
    "      - ggplot2",
    "      - scatterplot"
  )
  writeLines(c(txt, block), manifest)
  cat("Registered the dataset in jamovi/0000.yaml.\n")
}
cat("Next: jmvtools::install(), then in jamovi: menu -> Open -> Data Library -> jmvggplot.\n")
