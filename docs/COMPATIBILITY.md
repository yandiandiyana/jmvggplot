# Feature compatibility matrix
Status key: **verified** = checked by the user in jamovi 2.7.39.0 or by running tests on the user's machine;
**written** = implemented, tests written, not yet run; **planned** = not implemented.

| Area | Item | Status |
|---|---|---|
| Mappings | x, y, colour, label | verified |
| Mappings | fill, shape, size, alpha, group | verified (D1) |
| Layers | point, line, smooth, jitter, text | verified |
| Layers | histogram, bar, col, density, boxplot, violin | verified (D1) |
| Layers | hline, vline, abline | verified (D1) |
| Layers | path, area, ribbon, errorbar, segment, label | verified (D3) |
| Mappings | ymin, ymax, xend, yend (layer-specific variable boxes) | verified (D3) |
| Positions | per-layer identity, stack, fill, dodge, jitter, validated per geom | verified (D3) |
| Settings | bar/box/error-bar width; warning/error for settings a layer type does not use | verified (D3) |
| Layer manager | add, duplicate, delete, reset, move up/down, enable, inherit | verified (C2b) |
| Layer manager | live layer-type text in section headers | planned |
| Facets | wrap, grid, scales, wrap columns | verified (D1) |
| Stats | summary layers: mean ± SE, mean ± SD, mean, median, median + IQR (point/range, error bars, bars) | verified (D3b) |
| Stats | other explicit statistic choices (count, bin, density, smooth are implied by the layer type) | not planned as separate controls |
| Scales | axis transform (log10, sqrt, reverse), axis range (zoom or limits) | verified (D2) |
| Scales | colour/fill palettes (viridis, Set1, Dark2, Blues, Greys, manual) | verified (D2) |
| Scales | explicit breaks/labels, date/time axes, per-aesthetic palettes for shape/size/alpha | planned |
| Coords | cartesian (zoom), flip, fixed 1:1 | verified (D2) |
| Coords | polar/radial, transforms | planned |
| Labels | title, axis titles | verified |
| Labels | subtitle, caption, legend titles, legend position/hide | verified (D2) |
| Theme details | base size, font family (sans/serif/mono), hide grid lines, hide ticks, X text angle, bold title, plot/panel background colour, plot margin | written (D2b) |
| Theme details | per-element sizes/colours, legend text, strip text, custom fonts | planned |
| Themes | 8 standard themes | verified |
| R code panel | plot and code from the same spec | verified (R tests + jamovi) |
| Save / reopen | options restored | verified |
| References | ggplot2 citation shown with the results | verified |
| Data Library | penguins example dataset (data/ + datasets: in 0000.yaml) | verified |
| Syntax mode (jamovi) | call shown with only the options you set; editing a value and running it updates the plot (Windows, jamovi 2.7.39.0) | verified |
| Calling `layerPlot()` from plain R | works (tests/manual/syntax_check.R) | verified |
| Extensions | ggrepel text / label layers | postponed (implemented, then removed from v1) |
| Extensions | ggridges, ggbeeswarm, ggdist, others | planned |
