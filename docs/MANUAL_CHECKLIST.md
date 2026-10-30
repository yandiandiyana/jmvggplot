# Verify first (Stage B), in this order
1. `jmvtools::install()` succeeds. Note any errors from `0000.yaml`, `category: plots`, `menuGroup: .`,
   `jas: '1.2'` (jamovi >= the version with the Plots tab; no `minApp` set yet).
2. Open jamovi, load a dataset: does "Layered ggplot" appear under **Plots**?
3. Hand-written UI: layer sections collapse, and method/band controls enable only for smooth layers.
4. X=numeric, Y=numeric: plot + code appear. Add layer 2 = smooth: regression line appears.
5. `self$data` column names: do they equal the jamovi variable names (incl. spaces/non-ASCII)?
6. Missing values and an empty dataset: message appears, no crash.
7. Save as .omv, reopen: are all options restored?
8. Does `visible: (showCode)` in `.r.yaml` hide the code panel?
9. `Rscript tests/run_standalone.R` passes (needs ggplot2 >= 3.5; `formula = y ~ x` and `linewidth` assumed).
Record every deviation; do not assume anything above works.

# Stage C2 checks (layer manager, in jamovi)
1. Build/install succeeds with `jamovi/js/layerplot.js` (any JS error: press F10 in jamovi, copy the Console message).
2. Layer 1 = Points. Top "Add layer" -> Smooth: Layer 2 becomes Smooth; the plot gains a line; the dropdown returns to "Choose a type...".
3. Layer 1 "Layer actions" -> Duplicate: Layer 2 is an identical Points layer, old Layer 2 shifts to Layer 3.
4. Move down / Move up: the order changes and the drawing order on the plot changes (e.g. line over/under points).
5. Delete: layer disappears, later layers shift up. Reset settings: opacity/size/etc. return to defaults, type kept.
6. Does each action cause ONE plot refresh (not a flicker of several)?
7. Save, close, reopen: the rearranged layers are restored; the action dropdowns show "Choose an action...".
8. With 6 layers in use, Add and Duplicate do nothing (expected; no message yet).

# Stage D1 checks
Run first: `Rscript tests/run_standalone.R` and `node tests/js/test-layerops.js`. Send me any failure text.
In jamovi (install with `jmvtools::install()`):
1. Options panel: does it open? Variable boxes for X, Y, Colour, Fill, Shape, Size, Opacity, Group, Label, Facet by, Facet columns.
2. Layer 1 = Points with Colour = a categorical variable; then Fill / Shape / Size mapped: legend entries appear. Shape box accepts categorical variables only.
3. Layer 1 = Histogram with only X (numeric) selected: histogram + code `geom_histogram()`. Now ALSO select Y: histogram still draws, a note says Y is not used, code shows `inherit.aes = FALSE`.
4. Bar with a categorical X: bar counts. Column with categorical X and numeric Y: bars of values.
5. Boxplot / Violin with categorical X and numeric Y.
6. Layer = Horizontal line: the "line position" box sets the height; Diagonal line: slope box enables only for this type; Histogram: bins box enables only for histogram.
7. Facets: Facet wrap + a categorical variable in "Facet by": panels appear and the code has `facet_wrap(vars(...))`. Facet grid with rows and columns. Does "columns (0 = automatic)" enable only for wrap?
8. Set a fixed opacity on a layer while Opacity is also mapped: a warning appears.
9. Layer actions (up/down/duplicate/delete) still work with the new layer types and their line position / bins / slope settings travel with the layer.
10. Save, close, reopen: everything restored.

# Stage D2 checks
Run first: `Rscript tests/run_standalone.R` (new file test-d2.R). Send me any failure text.
Note: two assertions read ggplot2 internals (`p$theme$legend.position`, `panel_params$x.range`); if only those fail it is a ggplot2-version detail, tell me.
In jamovi:
1. New sections exist: Axes and coordinates, Colour and fill scales, Legend, Labels and theme.
2. X axis transformation = Log10 with a numeric positive X: axis becomes logarithmic and code shows `scale_x_continuous(transform = "log10")`.
3. X min = 5, max = 30, range mode Zoom: plot is cropped, all points still used by e.g. a regression layer; code shows `coord_cartesian(xlim = c(5, 30))`. Switch to Limits: points outside are removed, regression changes; code shows `scale_x_continuous(limits = c(5, 30))`.
4. Zoom plus a transformation: a clear message appears (not a blank plot).
5. Type `abc` in X min: message says it is not a valid number.
6. Colour = categorical variable, Colour palette = Viridis / Set1 / Manual (type `red, blue`): colours change; code shows the matching scale line. Colour = numeric variable + Set1: message says it needs a categorical variable. Manual box enables only for Manual.
7. Coordinate system Flipped and Fixed: plot changes, code shows `coord_flip()` / `coord_fixed()`.
8. Legend position Bottom / Hidden; legend titles; subtitle and caption appear on the plot and in `labs(...)`.
9. Layer actions, facets and save/reopen still work with the new settings.

# Stage D3 checks
Run first (restart R): `Rscript tests/run_standalone.R` (new file test-d3.R). Send me failure text.
In jamovi (Layer 1 = Points, X and Y numeric; you also need numeric columns for min/max, e.g. a lower and upper bound):
1. New variable boxes exist: Y min, Y max, X end, Y end.
2. Layer 2 = Ribbon with nothing selected: a message tells you to choose ymin and ymax. Fill the boxes: a shaded band appears; code shows `geom_ribbon(aes(ymin = ..., ymax = ...))`.
3. Layer 2 = Error bars with the same boxes; set width 0.3: bars narrower; code shows `width = 0.3`.
4. Layer 2 = Segments with X end / Y end; Path; Area (numeric X and Y); Boxed labels (Label box).
5. Bar (X categorical, Fill categorical): Position adjustment Dodge / Stack / Fill changes the bars; code shows `position = "..."`.
6. Points with Position = Stack: message says position is invalid and lists the allowed ones. Line with Position = Dodge: message says it does not support position.
7. Histogram with Size = 3: a note that the setting is not used (plot still draws).
8. Points with Position = Jitter: points jitter; the R code shows `position = "jitter"` (jitter is random, so each run differs).
9. Layer actions (duplicate/move) carry width and position with the layer; save/reopen restores everything.

# Stage D3b checks
Run first (restart R): `Rscript tests/run_standalone.R` (new file test-d3b.R). Send me failure text.
In jamovi, use a numeric Y and a categorical X (e.g. group):
1. Layer 1 = Summary (point / range), statistic Mean ± standard error: one dot with a vertical range per group; code shows `stat_summary(geom = "pointrange", fun.data = mean_se)`.
2. Change the statistic to Mean ± standard deviation: ranges get wider; code shows `fun = mean, fun.min = function(x) mean(x) - sd(x), ...`. Median with interquartile range: median dot, IQR range. Mean or Median: a dot only.
3. Layer 1 = Points (opacity 0.3), Layer 2 = Summary error bars with statistic Mean ± SE and width 0.2: raw points with error bars on top.
4. Layer 2 = Summary error bars with statistic Mean: a message says error bars need a statistic that has a range.
5. Layer 1 = Summary bars, statistic Mean, X categorical, Fill = second categorical variable, Position = Dodge: bars side by side.
6. A numeric X and categorical Y with a summary layer: message says Y must be numeric.
7. Points layer with the statistic set to Median: a note says the setting is not used.
8. Duplicate / move a summary layer: its statistic travels with it. Save and reopen: restored.

# D3b follow-up: dodge fix
9. X categorical, Colour = a second categorical variable. Layer 1 = Summary (point / range), Position = Dodge; Layer 2 = Summary error bars, same statistic, Position = Dodge, width 0.2.
   Expect: the groups' dots are side by side (not on top of each other) and each error bar sits on its dot. The code shows `position = position_dodge(width = 0.9)`.

# Stage D2b checks
Run first (restart R): `Rscript tests/run_standalone.R` (new file test-d2b.R). Send me failure text.
If only lines using `p$theme[[...]]` fail it is likely a ggplot2-version detail: send the message.
In jamovi, open **Theme details** (new section at the bottom):
1. Base text size 16 (default 11): all text larger; code shows `theme_minimal(base_size = 16)`. Font family Serif: serif text; code adds `base_family = "serif"`.
2. Hide major grid lines / Hide minor grid lines / Hide axis ticks: the corresponding lines disappear; code gets `theme(panel.grid.major = element_blank(), ...)`.
3. X axis text angle 45 and 90 (use a categorical X with long labels): labels rotate and stay readable.
4. Bold title (type a Title first): title is bold.
5. Plot background colour `lightyellow`, Panel background colour `white`: backgrounds change. Type `notacolour`: a message names the problem. Colour like `#FFF8DC` works.
6. Plot margin `30`: more white space around the plot. Type `abc`: message says not a valid number. Type `-5`: message says between 0 and 200.
7. Combine with a legend position, a palette and facets: all still apply; save/reopen restores everything.

# Stage F1 checks (ggrepel)
Run first (restart R): `Rscript tests/run_standalone.R`. test-f1.R skips two tests if ggrepel is not installed in YOUR R
(that is fine); tell me whether it ran or skipped.
In jamovi:
1. `jmvtools::install()`: does it succeed? It should download/bundle ggrepel. If it fails, paste the exact message (this is the
   main open risk: compiled package bundling). If it fails I will move ggrepel out of DESCRIPTION.
2. Points layer + new layer "Repelled text labels (ggrepel)" with a Label variable (a categorical variable with many repeated
   values is fine): labels appear without overlapping the points/each other. Code shows `library(ggrepel)` and
   `geom_text_repel(aes(label = ...), seed = 1, max.overlaps = Inf)`.
3. Change a setting (e.g. title) and watch: the label layout stays the same between refreshes (fixed seed).
4. "Repelled boxed labels": labels with boxes. With no Label variable chosen: a message asks for it.
5. If the layer says it "needs the R package 'ggrepel'": tell me. That means the package was not bundled.
6. Layer actions (move/duplicate) and save/reopen still work with these layer types.

# Reference check (ggplot2) and ggrepel removal
Run first (restart R): `Rscript tests/run_standalone.R`.
1. `jmvtools::install()` succeeds. If it fails mentioning `00refs.yaml` or `refs`, paste the message (the file format is the one thing I could not verify).
2. Open the analysis and scroll to the bottom of the results: the References list should now show ggplot2 (Wickham, 2016) in addition to jamovi and R.
3. The two ggrepel layer types are gone from the layer-type dropdown; everything else still works.
