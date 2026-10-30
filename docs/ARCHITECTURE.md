# Architecture

## Flow
```
jamovi options ──► spec_from_options() ──► spec (plain list)
                                              │ validate_spec(spec, data)  → errors / warnings
                              ┌───────────────┴───────────────┐
                        build_plot(spec, data)        spec_to_code(spec, data)
                        (ggplot object, printed        (readable R text, shown in
                         by jamovi's Image)             the "Equivalent R code" panel)
```
Plot and code share one spec, one geom registry (`R/registry.R`) and one layer-inheritance rule
(`R/plan.R`), so they cannot drift apart. This is enforced by tests that evaluate the generated code and
compare `ggplot_build()` output with the directly built plot.

## Files
| File | Responsibility |
|---|---|
| `R/registry.R` | geoms (required aesthetics, parameters, allowed positions), summary statistics, themes and theme tweaks, palettes, labels |
| `R/plan.R` | which aesthetics a layer receives; palette → scale function |
| `R/spec.R` | jamovi options → spec |
| `R/validate.R` | all checks and messages |
| `R/build_plot.R` | spec → ggplot object (real function calls, `.data[["name"]]`) |
| `R/spec_to_code.R` | spec → code text (all strings via `deparse`) |
| `R/layerplot.b.R` | jamovi glue only (messages, state, rendering) |
| `jamovi/*.yaml`, `jamovi/js/layerplot.js` | option definitions, UI, layer manager |
| `tools/gen_yaml.py` | generates `layerplot.a.yaml` and `layerplot.u.yaml` |

## Layer manager (UI)
Layers are stored in ordinary options (6 slots × 13 fields), so jamovi saves and restores them like any
option. `jamovi/js/layerplot.js` only rearranges those option values when the user picks an action in a
dropdown (move up/down, duplicate, reset, delete, add), using documented handlers (`{option}_changed`,
`setValue`, `beginEdit/endEdit`). The dropdown is reset after the batched edit. Trade-offs: a fixed maximum of
6 layers; actions pack empty slots to the end; no true buttons or live layer-type headings.

## Safety
No user text is evaluated. Variable names reach ggplot2 as strings inside `.data[["…"]]`; code output
quotes names/labels with `deparse`. Colour lists are validated with `grDevices::col2rgb`. Tests cover hostile
names, labels and colour strings. Extension packages are never installed at run time.

## Known limits (see COMPATIBILITY.md for the full matrix)
Fixed 6 layers; generated code assumes `data` is a data frame with jamovi's column names (jamovi may convert
types, e.g. integer nominal → factor); the layer-type text cannot be shown in section headers; syntax-mode
support is untested and not claimed.
