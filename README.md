# jmvggplot

Build **ggplot2** plots **layer by layer** in jamovi, with point-and-click controls, and see the equivalent **R code**.

Pipeline: jamovi options → structured spec → validation → ggplot object **and** R code text.
The plot and the code come from the same validated spec and the same geom registry, so they cannot drift apart
(this is checked by tests that evaluate the generated code and compare it with the plot).

Source: https://github.com/yandiandiyana/jmvggplot

Status: version 0.0.1, first release candidate. Verified on Windows with jamovi 2.7.39.0 (details in `docs/COMPATIBILITY.md`).

## Install
- **From a built file:** `jmvggplot_0.0.1.jmo` (made by `jmvtools::install()`, it only fits the same OS / jamovi series): jamovi library "+" → Side-load.
- **From source (developers):** R + `jmvtools`, then in the project folder: `jmvtools::install()`.
- Example data: see "Try it".

## What you can do
- **Mappings:** x, y, colour, fill, shape, size, opacity, group, label; layer-specific ymin/ymax and xend/yend.
- **Layers (up to 6, each with its own settings):** points, line, path, smooth/regression, jitter, text, boxed labels, histogram, bar, column, density, area, ribbon, error bars, segments, boxplot, violin, horizontal/vertical/diagonal lines, summary layers (mean ± SE / SD, mean, median, median + IQR).
  Per layer: enable, inherit global aesthetics, opacity, size/width, position (identity, stack, fill, dodge, jitter), bins, smoothing method, intercept/slope.
- **Layer manager:** add, duplicate, delete, reset, move up/down (dropdown actions).
- **Facets:** wrap or grid, with scales and columns.
- **Axes and scales:** log10 / square-root / reverse; ranges as zoom or limits; colour and fill palettes (viridis, Brewer, greys, manual).
- **Coordinates, legend, labels:** flipped / fixed; legend position and titles; title, subtitle, caption, axis titles.
- **Theme:** 8 themes plus details (text size, font family, grid lines, ticks, X text angle, bold title, backgrounds, margin).
- **Safe by design:** invalid combinations give a message (not a blank plot); variable names and labels are never evaluated as code.
- **References:** the results show the ggplot2 citation next to jamovi's.

## Try it
Penguins example data (palmerpenguins, CC0) in jamovi's Data Library: run `source("tools/add_example_data.R")` once
(writes `data/penguins.csv`, needs the `palmerpenguins` package), then `jmvtools::install()`, then in jamovi:
hamburger menu → Open → Data Library → jmvggplot. Follow "Quick check" in `docs/RELEASE.md`. Details: `docs/DATASETS.md`.

## Syntax mode
Works. jamovi shows `jmvggplot::layerPlot(data = data, x = ..., y = ..., l2_type = "smooth")` with only the options you set;
edit a value and run it to update the plot. You can also call `layerPlot()` from plain R (`tests/manual/syntax_check.R`).

## The generated R code
The "Equivalent R code" panel shows code that rebuilds the plot from a data frame called `data` with the same column names.
Differences from jamovi: jamovi may convert variable types (e.g. integer nominal → factor) and applies its own missing-value handling;
results can differ if your standalone data types differ.

## Known limitations
- Maximum 6 layers; layers are rearranged with action dropdowns (no true buttons; headings do not show the layer type; actions pack empty slots to the end).
- The options panel is large (138 options), organised in collapsible sections.
- Not implemented: date/time axes, explicit breaks and labels, scales for shape/size/opacity, layer-specific data, per-element theme controls, multi-plot layouts, extension packages (ggrepel was implemented and tested, then postponed).
- Tested only on Windows with jamovi 2.7.39.0 (bundled R 4.5.0) and a current ggplot2; other systems and versions are untested.
- The jamovi library build uses a fixed CRAN snapshot per jamovi series; its ggplot2 version (needs >= 3.5.0) is not verified.

## Development
- Standalone R tests (no jamovi): `Rscript tests/run_standalone.R` (needs `ggplot2`, `testthat`). JavaScript layer logic: `node tests/js/test-layerops.js`.
- `jamovi/layerplot.a.yaml` and `layerplot.u.yaml` are generated: edit `tools/gen_yaml.py`, then run `python3 tools/gen_yaml.py`.
- Architecture: `docs/ARCHITECTURE.md`; feature matrix: `docs/COMPATIBILITY.md`; roadmap: `docs/ROADMAP.md`; release steps: `docs/RELEASE.md`;
  manual test checklists: `docs/MANUAL_CHECKLIST.md`; dependencies and licences: `docs/DEPENDENCIES.md`; extensions: `docs/EXTENSIONS.md`.

## Licence and credits
Module: GPL (>= 2) (consistent with jmvcore). Dependencies: ggplot2 (MIT), R6 (MIT), jmvcore (GPL >= 2). No code copied from other jamovi plotting modules.
Author: Yandi Andiyana. Example data: palmerpenguins (CC0), see `docs/DATASETS.md` for credit.
