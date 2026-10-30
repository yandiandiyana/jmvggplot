# ggplot2 extension survey (Stage F planning)

Only facts checked in this project are stated as such. Everything else is marked *to check*.
Rule: no package is downloaded at run time. **Verified (dev.jamovi.org, "Additional Notes"):** `jmvtools::install()`
identifies, downloads and bundles every dependency listed in `DESCRIPTION`, so users do not need R packages installed;
for the official jamovi library, dependencies come from a fixed CRAN snapshot taken at the start of each jamovi series,
so bundled versions can lag CRAN. The docs recommend `::` over `import()` in NAMESPACE (lazy loading); this module does that.
**Not verified:** what that snapshot contains (e.g. whether ggrepel and a new enough ggplot2 are in it) and how
compiled packages are built for every platform.

## Compatibility standard for an extension
1. Returns layers/components that can be added with `+` to a ggplot object.
2. Fits the layer model (registry entry: function, required aesthetics, parameters, validation).
3. Works when printed by jamovi's `Image` render function (no extra graphics device requirements).
4. Available as a binary for jamovi's R on Windows, macOS and Linux (compiled packages are the risk).
5. Licence compatible with this module's GPL (>= 2) distribution.

## ggrepel (first candidate) — POSTPONED, not part of the first version
Decision (project owner): ggrepel is deferred. The layer types were implemented and R-tested (the plot-versus-code tests passed),
then removed from the registry and UI so the first release has no extra bundled/compiled dependency. The generic mechanism
(`package` field, `package_problem()`, `library()` lines in generated code) stays in place; re-adding ggrepel is a registry entry
plus two layer types in `tools/gen_yaml.py`. The notes below are kept for that later work.
- Contributes: `geom_text_repel()`, `geom_label_repel()` (non-overlapping labels). Fits the existing
  text/label layers: same aesthetics (x, y, label), same size/opacity settings.
- **Verified (CRAN 0.9.8, 2026-03-17):** licence GPL-3 | file LICENSE; Depends R >= 4.1.0, ggplot2 >= 3.5.2;
  Imports grid, Rcpp, rlang, S7, scales, withr; **NeedsCompilation: yes**.
- Risks: compiled code must be available inside jamovi's bundled R on every platform; GPL-3 licence
  means the combined module should be distributed under GPL-3-compatible terms (jmvcore's "GPL >= 2" allows GPL-3).
- Repel layers are placement-dependent (random seed): use a fixed `seed` for reproducible output and code.
- **Implemented then removed from this version (F1):** layer types `text_repel` and `label_repel` (`geom_text_repel`, `geom_label_repel`),
  with `seed = 1` and `max.overlaps = Inf` fixed so the layout is reproducible and no label is silently dropped.
  Listed under `Suggests` (still bundled by jmvtools), loaded with `getExportedValue("ggrepel", ...)`; if the package
  cannot be loaded the layer reports a message. Generated code adds `library(ggrepel)`.
- Effective ggplot2 floor with ggrepel is >= 3.5.2 (this module's own floor is 3.5.0).
- Test result in jamovi: **not yet tested**.

## Others (all *to check*: licence, versions, compilation, jamovi availability)
| Package | Contributes | Fits layer model? | Notes |
|---|---|---|---|
| ggridges | ridgeline plots | yes (geom + y discrete) | to check |
| ggdist | distribution / uncertainty geoms and stats | partly (many stat/geom pairs) | large API; start with a few |
| ggbeeswarm | beeswarm / quasirandom points | yes (position or geom) | random layout, seed needed |
| patchwork | combine several plots | no: output is a composite, not a layer | would need a separate "multi-plot" concept |
| ggnewscale | second colour/fill scale | no: modifies scales mid-plot | needs a scale-ordering concept |
| ggforce | extra geoms, facets | partly | to check |
| ggtext | rich text rendering | no: element/theme level | to check |
| ggbreak | axis breaks | no: modifies the plot object | to check |
