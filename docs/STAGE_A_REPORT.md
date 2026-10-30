# Stage A report: feasibility (condensed)
Based on the official jamovi developer docs read during Stage A (analysis, UI, results definitions;
`Image`; plot modules; advanced UI customisation) and later confirmed by building and running the module.
`jmvplots`, `vijPlots`, `jjstatsplot` source and licences were **not** audited; nothing was copied from them.

1. **Options/data/results:** YAML definitions (`.a/.r/.u.yaml`) + R6 class in `.b.R`; `self$data` holds only
   columns named in variable options; results elements are filled in `.run`.
2. **ggplot display:** an `Image` result with `renderFun`; the render function prints the plot and returns TRUE;
   state is kept with `setState`. Confirmed working.
3. **Dependencies:** a module is an R package; dependencies must exist in jamovi's R library (compiled
   packages are the main risk for extensions).
4. **Dynamic layers:** declarative controls only give fixed groups; the documented JS customisation
   (`{option}_changed`, `setValue`, `beginEdit/endEdit`) allows a layer manager without custom DOM.
5. **Outcome:** fixed 6-slot storage + JS action dropdowns (verified in jamovi 2.7.39.0).
6. **Not claimed:** syntax mode, other jamovi versions, `.jmo` distribution.
7. **Reuse:** none; documented APIs and dependencies only.
