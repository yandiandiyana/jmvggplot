# Roadmap
Status as of this file: A, B, C, D1, D2, D2b, D3, D3b done and user-verified; ggrepel postponed by decision; ggplot2 reference added (awaiting check).

| Stage | Content | Status |
|---|---|---|
| A | Feasibility and architecture (docs/STAGE_A_REPORT.md) | done |
| B | Minimal working module | verified |
| C | Layer manager (fixed slots + JS action dropdowns) | verified |
| D1 | More mappings, geoms, facets | verified |
| D2 | Axes, palettes, coordinates, legend, labels | verified |
| D3 | path/area/ribbon/errorbar/segment/label, positions, width | verified |
| D3b | Summary layers via `stat_summary` (mean ± SE / SD, mean, median, median + IQR) | verified |
| D2b | Theme details: typography, grid lines, ticks, X text angle, bold title, backgrounds, margin | verified |
| E | Syntax-mode behaviour (test, do not claim), code reproducibility wording | partly done (code panel) |
| F1 | ggrepel layers via the registry (see EXTENSIONS.md) | implemented and R-tested, then **postponed** (removed from v1) |
| F2 | Further extensions (ggridges, ggbeeswarm, ggdist) | planned |
| G | Release: clean side-load test, syntax-mode check, licence/dependency check, `.jmo`, docs (see docs/RELEASE.md) | in preparation |

Possible later work: true buttons / live layer headings via a custom control (documented but riskier),
more than 6 layers, layer-specific data, date/time axes, explicit breaks and labels.
