# Example data

`penguins.csv` is created on your machine by `make_penguins_csv.R` from the **palmerpenguins** R package
(344 penguins, 8 variables: species, island, bill_length_mm, bill_depth_mm, flipper_length_mm, body_mass_g, sex, year;
a few values are missing, which is useful for testing the missing-data note).

Run in R (project root):
```r
install.packages("palmerpenguins")
source("examples/make_penguins_csv.R")
```
Then open `examples/penguins.csv` in jamovi (File → Open).

Data licence: CC0 ("no rights reserved"), per the palmerpenguins documentation.
Please credit: Gorman KB, Williams TD, Fraser WR (2014) Ecological Sexual Dimorphism and Environmental Variability within a
Community of Antarctic Penguins (Genus *Pygoscelis*). PLoS ONE 9(3): e90081; and Horst AM, Hill AP, Gorman KB (2020)
palmerpenguins: Palmer Archipelago (Antarctica) penguin data. R package. https://allisonhorst.github.io/palmerpenguins/
The CSV is not shipped inside the module (the script keeps the repository free of copied data).
