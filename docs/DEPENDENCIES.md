# Dependencies and licences

Status: **verified** = read from the package's CRAN page in this project; **not verified** = from general
knowledge only, check before release. No code has been copied from jmv, jmvplots, vijPlots or jjstatsplot.

## References shown in jamovi
`jamovi/00refs.yaml` defines the ggplot2 citation (Wickham, 2016, Springer-Verlag New York, the book); `layerplot.r.yaml` attaches it with `refs: [ggplot2]`. **Confirmed** by the author against `citation("ggplot2")` in R 4.5.3 (same book entry, ISBN 978-3-319-24277-4). jamovi adds its own jamovi and R references.

## Runtime (Imports)
| Package | Role | Licence | Status |
|---|---|---|---|
| jmvcore | jamovi analysis framework | GPL (>= 2), i.e. GPL-2 or GPL-3 (CRAN, v2.7.7 checked) | verified |
| R6 | classes for the analysis | MIT + file LICENSE (CRAN, v2.6.1) | verified |
| ggplot2 (>= 3.5.0) | plotting engine | MIT + file LICENSE (CRAN; current release 4.0.3) | verified |

`DESCRIPTION` declares `GPL (>= 2)`, consistent with jmvcore. Version floor 3.5.0 because the code uses
`transform =` in scale functions and `linewidth`.

## Postponed extension (NOT a dependency of the first version)
| Package | Role | Licence | Status |
|---|---|---|---|
| ggrepel (0.9.8 on CRAN) | repelled text/label layers | GPL-3 \| file LICENSE; Depends ggplot2 >= 3.5.2, R >= 4.1.0; Imports grid, Rcpp, rlang, S7, scales, withr; compiled | verified (CRAN page) |

Licence note (for when ggrepel is added later): bundling ggrepel (GPL-3) in the distributed module makes the combined work GPL-3. This module's own
`GPL (>= 2)` allows that. Not legal advice; re-check before publishing a `.jmo`.

## Tests only
testthat (>= 3.0.0): development only, not part of the distributed module; licence not checked here. Node (built-in `assert`) is used for the JavaScript layer logic tests.

## Environments in which this was exercised (by the project owner)
Windows; RStudio R 4.5.3 for the tests; jamovi 2.7.39.0 whose bundled R is 4.5.0; a current ggplot2 (built under R 4.5.3). The module's `transform =` scales and `linewidth` need ggplot2 >= 3.5.0 and work in this jamovi, so the ggplot2 used there is new enough. **Not verified:** the ggplot2 version in the jamovi library's CRAN snapshot; other OS, older jamovi / R / ggplot2.

## Candidate extensions (not dependencies yet): see docs/EXTENSIONS.md
