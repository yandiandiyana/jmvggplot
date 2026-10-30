# Changelog

## 0.0.1 (first release candidate)
- Layered ggplot2 builder: 15 variable boxes, 6 layer slots, 23 layer types (including summary statistics), layer manager actions,
  facets, axis transformations and ranges, colour/fill palettes, coordinates, legend, labels, 8 themes plus theme details.
- Equivalent R code generated from the same validated spec; ggplot2 reference; penguins example dataset in the Data Library.
- Verified by the author in jamovi 2.7.39.0 on Windows (install, all manual checklists, save/reopen, syntax mode) and with R tests.
- Not in this version: extension packages (ggrepel postponed), date axes, explicit breaks/labels, per-aesthetic scales for shape/size/opacity.

## Development log
## 0.0.1 (unreleased) — Stage B scaffold
- Spec/validate/build/code-generation core, 5 geoms, 4 layer slots, themes, labels.
- Unit tests written; **not yet run**. Module **not yet installed** in jamovi.
- Test run on user's machine (R 4.5.3): 6 failures, all in the test helper (named layer list in
  current ggplot2); helper fixed with unname(). Core logic tests passed.
- User-verified on jamovi 2.7.39.0: installs, appears under Plots, plot+code render, regression layer works,
  save/reopen restores settings.
- Hand-written jamovi/layerplot.u.yaml (compilerMode: tame): collapsible layer sections,
  smooth-only controls enabled by `enable: (lN_type:smooth)` (syntax unverified).
- Stage C2: 6 layer slots; per-layer action dropdowns (up/down/duplicate/reset/delete) and Add layer,
  via jamovi/js/layerplot.js. Logic tested with node (13 tests); NOT yet run in jamovi.
- C2 user test (jamovi 2.7.39.0): installs; add/duplicate/delete/reset/save-reopen work; BUG: "Add layer"
  dropdown stayed on the chosen type. Fix (unverified in jamovi): reset dropdown after the batch, deferred.
- User confirmed C2b in jamovi: Add layer / Layer actions / order in code panel / save-reopen work.
  ('Add layer' returning to 'Choose a type to add...' is intended.)
- Stage D1 (written, R tests written, NOT yet run): fill/shape/size/alpha/group mappings; histogram, bar, col,
  density, boxplot, violin, hline, vline, abline; facet wrap/grid; layer_plan() drops global aesthetics a stat
  layer cannot take; warnings for mapped-vs-fixed conflicts; tools/gen_yaml.py; docs/COMPATIBILITY.md.
- D1 verified by user: R tests pass (core + d1) and manual checklist works in jamovi.
- Stage D2 (written, tests written, NOT yet run): axis transform + range (zoom/limits), colour/fill palettes
  (palette_plan), coordinate systems, legend position and titles, subtitle/caption; validate_scales();
  spec_to_code(spec, data) now takes data (needed for discrete vs continuous palette code).
  Removed obsolete skipped placeholder test.
- Fix: tests/run_standalone.R now sources R/ into a fresh environment (a stale R session made D2 tests call an
  old spec_to_code()). No module code changed.
- D2 verified by user: R tests and manual checklist pass in jamovi.
- Stage D3 (written, tests written, NOT yet run): path, area, ribbon, errorbar, segment, label layers;
  ymin/ymax/xend/yend variable boxes; per-layer position + width; validation of unsupported
  position/width/size/opacity settings (error for position, warning otherwise).
- Docs: ARCHITECTURE, ROADMAP, EXTENSIONS (ggrepel verified on CRAN), STAGE_A_REPORT; DEPENDENCIES now states what
  was verified (jmvcore GPL >= 2; ggrepel GPL-3, compiled).
- D3 verified by user: R tests and manual checklist pass in jamovi.
- Stage D3b (written, tests written, NOT yet run): summary, summary_errorbar, summary_bar layer types with a per-layer
  statistic (mean_se, mean_sd, mean, median, median_iqr); registry extras are now function(layer); DESCRIPTION
  declares stats/utils/grDevices.
- D3b test run (user): all pass; two ggplot2 warnings ("Width not defined") exposed a real issue: position Dodge on
  points/labels/error bars/summary layers did not separate groups. Fix: those layers use position_dodge(width = 0.9);
  bars/boxes keep the plain string. Tests added.
- D3b verified by user (R tests clean; jamovi checks 1-9 incl. dodge fix).
- Stage D2b (written, tests written, NOT yet run): theme details (base size, family, grid lines, ticks, X text angle,
  bold title, plot/panel background, margin); theme_tweaks()/theme_base_args() shared by plot and code;
  validate_theme_details(); test-d2b.R.
- Fix (found by jmvtools compile on user's machine): List option names "45"/"90" were read as numbers by YAML and rejected
  by jamovi's schema. Renamed to deg45/deg90; generator now quotes all List names/defaults and asserts they are strings.
- D2b verified by user (R tests clean; jamovi checks 1-7 work) after the deg45/deg90 fix.
- Stage F1 (written, tests written, NOT yet run): text_repel / label_repel layers (ggrepel), registry `package` field,
  package_problem() check, library() lines in generated code, ggrepel in Suggests. Docs: bundling facts, licence note.
- F1 tested by user (R tests clean incl. ggrepel); decision: ggrepel postponed. Layer types and ggrepel in DESCRIPTION removed;
  generic package mechanism kept (test-f1.R now tests it without ggrepel).
- Added ggplot2 reference: jamovi/00refs.yaml + `refs: [ggplot2]` in layerplot.r.yaml (format taken from published jmv-family modules; not yet verified in jamovi).
- User confirmed v1rc1: R tests clean, ggrepel layer types gone from the dropdown.
- Release preparation: docs/RELEASE.md (facts from dev.jamovi.org), examples/viscosity*.csv, .gitignore, .Rbuildignore,
  tests/manual/syntax_check.R. Syntax mode still untested.
- Author/maintainer set (Yandi Andiyana); version stays 0.0.1; ggplot2 reference confirmed by user (3 references shown).
- Example data switched from synthetic viscosity to palmerpenguins (CC0), created by examples/make_penguins_csv.R;
  syntax_check.R and RELEASE.md updated. (v1rc2 was never installed by the user; v1rc3 supersedes it.)
- Example data moved into the module's Data Library mechanism (data/ + datasets: in 0000.yaml; documented on dev.jamovi.org).
  tools/add_example_data.R creates data/penguins.csv and registers it; examples/ folder removed. Not yet verified in jamovi.
- rc4 verified by user: install OK (`jmvggplot_0.0.1.jmo` written), R tests clean, penguins dataset appears in the Data Library and opens.
- Bug found by tests/manual/syntax_check.R: calling layerPlot() from R failed with `argument "shape" is missing, with no default`:
  Variable options had no default, so the generated function required them (this would also break syntax-mode calls that omit them).
  Fix: `default: null` on every Variable option (tools/gen_yaml.py). Not yet re-tested.
- rc5 verified by user: syntax_check.R passes from plain R; install OK; R tests clean.
- Fix: penguins disappeared from the Data Library after unzipping rc5 because rc5's jamovi/0000.yaml had no `datasets:` block and overwrote the user's
  local one (build output lacked `copied penguins.csv`). 0000.yaml now ships with the block (requires data/penguins.csv, created by tools/add_example_data.R).
- Syntax mode verified in jamovi 2.7.39.0 (call shown with set options; editing and running updates the plot).
- Licences verified on CRAN pages: ggplot2 MIT + file LICENSE, R6 MIT + file LICENSE, jmvcore GPL (>= 2). Final README written.
- Final checks by author: citation("ggplot2") matches 00refs.yaml; side-load of jmvggplot_0.0.1.jmo works.
  Repository URL and BugReports added to DESCRIPTION; release guide (git steps), submission e-mail draft added.
