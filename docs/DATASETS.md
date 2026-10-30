# Example data (jamovi Data Library)

Verified in dev.jamovi.org ("Module Datasets"): files in a `data/` folder at the module root (`.omv` recommended, `.csv` allowed)
registered under `datasets:` in `jamovi/0000.yaml` (name, path, description, tags) appear in jamovi under
hamburger menu → Open → Data Library, in a section named after the module. Datasets should be small.

This module ships one dataset: **penguins** (palmerpenguins, 344 penguins, 8 variables, a few missing values by design).
`jamovi/0000.yaml` already contains the `datasets:` block; the CSV itself is not shipped. Create it with `source("tools/add_example_data.R")` (writes `data/penguins.csv`; adds the block only if it is missing, so it is safe to repeat).
**If `data/penguins.csv` is missing when you build, the dataset is not copied** (check the build output for the line `copied penguins.csv`). Unzipping a new module version over your folder keeps `data/penguins.csv` but replaces `jamovi/0000.yaml`; this version ships with the block so nothing is lost.
Commit `data/penguins.csv` to the repository so library builds include it.

Licence and credit: the data are CC0 ("no rights reserved") per the palmerpenguins documentation. Please credit:
Gorman KB, Williams TD, Fraser WR (2014). Ecological Sexual Dimorphism and Environmental Variability within a Community of
Antarctic Penguins (Genus *Pygoscelis*). PLoS ONE 9(3): e90081; and Horst AM, Hill AP, Gorman KB (2020). palmerpenguins:
Palmer Archipelago (Antarctica) penguin data. R package. https://allisonhorst.github.io/palmerpenguins/

Possible improvement (not done): an `.omv` file keeps variable types and descriptions (e.g. species/island/sex as nominal, year as ordinal);
open the CSV in jamovi, set the types, and save as `data/penguins.omv` to replace the CSV.
