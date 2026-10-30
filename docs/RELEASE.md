# Release guide (first version)

Facts below come from dev.jamovi.org "Distributing Modules" and "Additional Notes". Items marked **to do / unverified** are not done yet.

## What `jmvtools::install()` produces
A `.jmo` file in the project root. It works only on the OS, CPU architecture and jamovi series it was built on, so it is
suitable for side-loading on your own machine or a matching tester (jamovi library "+" → Side-load tab), not for general distribution.

## Before submitting to the jamovi library
- [x] Builds without errors with `jmvtools::install()` (verified on Windows, jamovi 2.7.39.0).
- [x] License declared in `DESCRIPTION`: `GPL (>= 2)` (GPL2+ is the recommended choice; consistent with jmvcore).
- [x] Module available in English.
- [x] `.gitignore` excludes `build/`, `dist/`, `*.jmo`.
- [x] Author / maintainer / e-mail set in `DESCRIPTION` and `jamovi/0000.yaml` (Yandi Andiyana).
- [ ] **to do:** a public source repository (GitHub account given: `yandiandiyana`; proposed URL `https://github.com/yandiandiyana/jmvggplot`, repository name to be confirmed). Needed so the jamovi team can build for all platforms; add it as `URL:` in `DESCRIPTION` once it exists.
- [x] First version number: 0.0.1 (identical in `DESCRIPTION` and `jamovi/0000.yaml`).
- [x] Example dataset in the Data Library (verified: appears and opens). **to do:** commit `data/penguins.csv` + the `datasets:` block to the repository.
- [ ] **to do:** the manual checklists in `docs/MANUAL_CHECKLIST.md` re-run once on the final build (clean side-load test below).
- [ ] **to do:** syntax-mode result (below) recorded in README.
- Submit by e-mail to contact@jamovi.org with the repository link (you may attach the `.jmo` for initial testing).
- Updates: increment the version in both files; the jamovi team publishes updates roughly weekly.

## Dependencies bundled by the build
`jmvtools::install()` bundles every package in `DESCRIPTION` (R6, jmvcore, ggplot2 and, transitively, their dependencies);
library builds use a fixed CRAN snapshot per jamovi series, so bundled versions can lag CRAN. This module needs
ggplot2 >= 3.5.0 (for `transform =` in scales and `linewidth`). **Unverified:** whether the snapshot's ggplot2 meets that floor.
Check the version bundled in your `build/` folder (`build/R/ggplot2/DESCRIPTION`) and tell me if it is below 3.5.0.

## Clean side-load test (instead of a separate machine)
1. In jamovi: library "+" → Installed → remove "jmvggplot" (if present).
2. Close jamovi. Do NOT run `jmvtools::install()`.
3. Open jamovi → library "+" → Side-load → choose the `jmvggplot.jmo` from the project folder.
4. In jamovi: hamburger menu → Open → Data Library → jmvggplot → penguins. Run the "Quick check" below.
This shows that the single `.jmo` file works without the development tools.

## Quick check (about 3 minutes)
Data: palmer penguins, from the Data Library (hamburger menu → Open → Data Library → jmvggplot → penguins). Set it up once with `source("tools/add_example_data.R")` before `jmvtools::install()` (see `docs/DATASETS.md`).
1. X = flipper_length_mm, Y = body_mass_g, Colour = species → coloured scatter plot and R code. (The data have a few missing values: a note about them appears and the plot still draws.)
2. Layer 2 = Smooth / regression → one fitted line per species.
3. Facets: wrap by island.
4. Colour palette Viridis; Theme details: base size 14; Title and axis titles.
5. Replace the points by Summary layers: X = species, Y = body_mass_g, Summary (point / range) with Mean ± SE, plus Layer 2 error bars; sex as Colour with Dodge.
6. Copy the R code panel into RStudio with the same data loaded as `data` and run it → same picture.
7. Save as .omv, close, reopen → settings and layers restored.

## Syntax mode
**Verified** (Windows, jamovi 2.7.39.0):
- jamovi's syntax mode shows the call with only the options you changed, e.g.
  `jmvggplot::layerPlot(data = data, x = flipper_length_mm, y = body_mass_g, colour = species, l2_type = "smooth")`, plus the results.
- Editing a value in that call and running it updates the plot.
- `tests/manual/syntax_check.R` runs `layerPlot()` from plain R (found and fixed a bug: variable options needed `default: null`).
Not tested: other operating systems / jamovi versions.

## Remaining before release
- [x] Clean side-load test with the `.jmo` (verified by the author: side-load works).
- [x] ggplot2 citation confirmed against `citation("ggplot2")`.
- [x] Repository URL in `DESCRIPTION` (`https://github.com/yandiandiyana/jmvggplot`).
- [ ] Push the source to that repository (see "Publishing the source" below); commit `data/penguins.csv`; do not commit `build/`, `dist/`, `*.jmo` (`.gitignore` covers them).
- [ ] Optional: add a `LICENSE` file (GitHub: Add file → Create new file → name it `LICENSE` → "Choose a license template" → GNU GPL v3.0; `DESCRIPTION` says GPL (>= 2), i.e. version 2 or later, so the v3 text is compatible).
- [ ] Send the submission e-mail (draft: `docs/SUBMISSION_EMAIL.md`).
- [ ] Optional / cannot be checked locally: ggplot2 version in the jamovi library's CRAN snapshot.

## Publishing the source (from the project folder, in a terminal or RStudio's Terminal tab)
If the GitHub repository is empty:
```
git init
git add .
git status          # check: no build/, dist/ or .jmo files are listed
git commit -m "jmvggplot 0.0.1"
git branch -M main
git remote add origin https://github.com/yandiandiyana/jmvggplot.git
git push -u origin main
```
If the repository already has files (for example a README created on GitHub), run `git pull origin main --allow-unrelated-histories` before the push.
