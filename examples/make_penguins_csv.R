# Writes examples/penguins.csv from the palmerpenguins package (data: CC0).
# Run once from the project root:   source("examples/make_penguins_csv.R")
# Needs:  install.packages("palmerpenguins")
if (!requireNamespace("palmerpenguins", quietly = TRUE))
  stop("Please install.packages('palmerpenguins') first.")
d <- as.data.frame(palmerpenguins::penguins)
write.csv(d, "examples/penguins.csv", row.names = FALSE, na = "")   # missing values stay blank
cat("Wrote examples/penguins.csv:", nrow(d), "rows,", ncol(d), "columns\n")
