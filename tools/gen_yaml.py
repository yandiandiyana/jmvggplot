#!/usr/bin/env python3
"""Generates jamovi/layerplot.a.yaml and jamovi/layerplot.u.yaml (run from project root).
Keep N_SLOTS in sync with R/registry.R and jamovi/js/layerplot.js."""
import yaml

NS = 6
TYPES = [("none","None"),("point","Points"),("line","Line"),("smooth","Smooth / regression"),
         ("jitter","Jittered points"),("text","Text labels"),("histogram","Histogram"),
         ("bar","Bar (counts)"),("col","Column (values)"),("density","Density"),
         ("boxplot","Boxplot"),("violin","Violin"),("hline","Horizontal line"),
         ("vline","Vertical line"),("abline","Diagonal line"),
         ("path","Path (data order)"),("area","Area"),("ribbon","Ribbon (min to max)"),
         ("errorbar","Error bars"),("segment","Segments"),("label","Boxed labels"),
         ("summary","Summary (point / range)"),("summary_errorbar","Summary error bars"),("summary_bar","Summary bars")]
THEMES = [("grey","Grey"),("minimal","Minimal"),("bw","Black & white"),("classic","Classic"),
          ("light","Light"),("dark","Dark"),("linedraw","Line draw"),("void","Void")]
ACTIONS = [("none","Choose an action..."),("up","Move up"),("down","Move down"),
           ("duplicate","Duplicate"),("reset","Reset settings"),("delete","Delete")]
VARS = [  # name, title, permitted
    ("x","X axis",["numeric","factor"]), ("y","Y axis",["numeric","factor"]),
    ("colour","Colour",["numeric","factor"]), ("fill","Fill",["numeric","factor"]),
    ("shape","Shape (categorical)",["factor"]), ("sizeBy","Size",["numeric","factor"]),
    ("alphaBy","Opacity",["numeric","factor"]), ("group","Group",["numeric","factor"]),
    ("label","Label (text and label layers)",["numeric","factor"]),
    ("ymin","Y min (ribbons, error bars)",["numeric"]), ("ymax","Y max (ribbons, error bars)",["numeric"]),
    ("xend","X end (segments)",["numeric"]), ("yend","Y end (segments)",["numeric"]),
    ("facetVar1","Facet by (wrap) / rows (grid)",["factor"]),
    ("facetVar2","Facet columns (grid only)",["factor"]),
]

def lst(name, title, opts, default):
    s = f'  - name: {name}\n    title: "{title}"\n    type: List\n    options:\n'
    for n, t in opts:
        s += f'      - name: "{n}"\n        title: "{t}"\n'
    return s + f'    default: "{default}"\n'

a = """---
name: layerPlot
title: Layered ggplot
menuGroup: .
version: '0.0.1'
jas: '1.2'
category: plots
description:
    main: Builds a ggplot2 plot from an ordered list of layers and shows the equivalent R code.
    R:
        dontrun: true
        usage: |
            # not intended for use outside jamovi in this stage
options:
  - name: data
    type: Data
    description:
        R: the data as a data frame

"""
for n, t, perm in VARS:
    a += f"  - name: {n}\n    title: \"{t}\"\n    type: Variable\n    permitted: [{', '.join(perm)}]\n    default: null\n"
a += "\n" + lst("addLayer","Add layer",[("none","Choose a type to add...")]+TYPES[1:],"none") + "\n"
a += lst("facetType","Facet type",[("none","No facets"),("wrap","Facet wrap"),("grid","Facet grid")],"none")
a += lst("facetScales","Facet scales",[("fixed","Fixed"),("free","Free"),("free_x","Free X"),("free_y","Free Y")],"fixed")
a += "  - name: facetCols\n    title: \"Facet wrap: number of columns (0 = automatic)\"\n    type: Integer\n    min: 0\n    default: 0\n\n"
for i in range(1, NS+1):
    a += lst(f"act{i}","Layer actions",ACTIONS,"none")
    a += lst(f"l{i}_type",f"Layer {i}: type",TYPES,"point" if i==1 else "none")
    a += f"  - name: l{i}_enabled\n    title: \"Layer {i}: enabled\"\n    type: Bool\n    default: true\n"
    a += f"  - name: l{i}_inherit\n    title: \"Layer {i}: inherit global aesthetics\"\n    type: Bool\n    default: true\n"
    a += f"  - name: l{i}_alpha\n    title: \"Layer {i}: opacity (0-1)\"\n    type: Number\n    min: 0\n    max: 1\n    default: 1\n"
    a += f"  - name: l{i}_size\n    title: \"Layer {i}: size / line width (0 = default)\"\n    type: Number\n    min: 0\n    default: 0\n"
    a += f"  - name: l{i}_width\n    title: \"Layer {i}: bar / box / error-bar width (0 = default)\"\n    type: Number\n    min: 0\n    default: 0\n"
    a += lst(f"l{i}_position",f"Layer {i}: position adjustment",[("default","Default"),("identity","Identity (overlap)"),("stack","Stack"),("fill","Fill (100%)"),("dodge","Dodge (side by side)"),("jitter","Jitter")],"default")
    a += lst(f"l{i}_stat",f"Layer {i}: summary statistic",[("mean_se","Mean ± standard error"),("mean_sd","Mean ± standard deviation"),("mean","Mean"),("median","Median"),("median_iqr","Median with interquartile range")],"mean_se")
    a += lst(f"l{i}_method",f"Layer {i}: smoothing method",[("lm","Linear (lm)"),("loess","LOESS"),("glm","GLM")],"lm")
    a += f"  - name: l{i}_se\n    title: \"Layer {i}: confidence band\"\n    type: Bool\n    default: true\n"
    a += f"  - name: l{i}_bins\n    title: \"Layer {i}: histogram bins\"\n    type: Integer\n    min: 1\n    max: 1000\n    default: 30\n"
    a += f"  - name: l{i}_intercept\n    title: \"Layer {i}: line position / intercept\"\n    type: Number\n    default: 0\n"
    a += f"  - name: l{i}_slope\n    title: \"Layer {i}: slope (diagonal line)\"\n    type: Number\n    default: 1\n\n"
def stropt(name, title):
    return f"  - name: {name}\n    title: \"{title}\"\n    type: String\n    default: ''\n"
TRANS = [("identity","None"),("log10","Log10"),("sqrt","Square root"),("reverse","Reverse")]
PALS = [("default","Default"),("viridis","Viridis"),("set1","Brewer Set1 (categorical)"),
        ("dark2","Brewer Dark2 (categorical)"),("blues","Blues"),("greys","Greys"),
        ("manual","Manual colours (categorical)")]
a += lst("xTrans","X axis transformation",TRANS,"identity") + lst("yTrans","Y axis transformation",TRANS,"identity")
for n,t in [("xMin","X axis minimum (blank = automatic)"),("xMax","X axis maximum (blank = automatic)"),
            ("yMin","Y axis minimum (blank = automatic)"),("yMax","Y axis maximum (blank = automatic)")]:
    a += stropt(n,t)
a += lst("rangeMode","Axis range mode",[("zoom","Zoom (keep all data)"),("limits","Limits (remove data outside)")],"zoom")
a += lst("coordType","Coordinate system",[("cartesian","Cartesian"),("flip","Flipped (swap X and Y)"),("fixed","Fixed aspect ratio (1:1)")],"cartesian")
a += lst("colourPalette","Colour palette",PALS,"default") + stropt("colourValues","Manual colours (comma separated)")
a += lst("fillPalette","Fill palette",PALS,"default") + stropt("fillValues","Manual colours (comma separated)")
a += lst("legendPosition","Legend position",[("right","Right"),("left","Left"),("top","Top"),("bottom","Bottom"),("none","Hidden")],"right")
for n,t in [("colourTitle","Colour legend title"),("fillTitle","Fill legend title"),("shapeTitle","Shape legend title"),
            ("sizeTitle","Size legend title"),("alphaTitle","Opacity legend title"),
            ("title","Title"),("subtitle","Subtitle"),("caption","Caption"),("xlab","X axis title"),("ylab","Y axis title")]:
    a += stropt(n,t)
a += "  - name: baseSize\n    title: \"Base text size\"\n    type: Number\n    min: 4\n    max: 40\n    default: 11\n"
a += lst("baseFamily","Font family",[("default","Default"),("sans","Sans-serif"),("serif","Serif"),("mono","Monospace")],"default")
for n,t in [("hideGridMajor","Hide major grid lines"),("hideGridMinor","Hide minor grid lines"),
            ("hideTicks","Hide axis ticks"),("boldTitle","Bold title")]:
    a += f"  - name: {n}\n    title: \"{t}\"\n    type: Bool\n    default: false\n"
a += lst("xTextAngle","X axis text angle",[("default","Default"),("deg45","45 degrees"),("deg90","90 degrees")],"default")
a += stropt("plotFill","Plot background colour (blank = theme default)") + stropt("panelFill","Panel background colour (blank = theme default)")
a += stropt("plotMargin","Plot margin in points (blank = theme default)")
a += lst("theme","Theme",THEMES,"minimal") + "  - name: showCode\n    title: Show R code\n    type: Bool\n    default: true\n"
open("jamovi/layerplot.a.yaml","w").write(a)

def var(label, name):
    return f"""      - type: TargetLayoutBox
        label: "{label}"
        children:
          - type: VariablesListBox
            name: '{name}'
            maxItemCount: 1
            isTarget: true
"""
u = """title: Layered ggplot
name: layerPlot
jus: '3.0'
stage: 0
compilerMode: tame
children:
  - type: VariableSupplier
    persistentItems: false
    stretchFactor: 1
    children:
""" + "".join(var(t, n) for n, t, _ in VARS)
u += """  - type: LayoutBox
    margin: large
    children:
      - type: ComboBox
        name: addLayer
"""
for i in range(1, NS+1):
    u += f"""  - type: CollapseBox
    label: Layer {i}
    collapsed: {'false' if i<=2 else 'true'}
    children:
      - type: ComboBox
        name: act{i}
      - type: ComboBox
        name: l{i}_type
      - type: CheckBox
        name: l{i}_enabled
      - type: CheckBox
        name: l{i}_inherit
      - type: TextBox
        name: l{i}_alpha
        format: number
      - type: TextBox
        name: l{i}_size
        format: number
      - type: TextBox
        name: l{i}_width
        format: number
      - type: ComboBox
        name: l{i}_position
      - type: ComboBox
        name: l{i}_stat
      - type: ComboBox
        name: l{i}_method
        enable: (l{i}_type:smooth)
      - type: CheckBox
        name: l{i}_se
        enable: (l{i}_type:smooth)
      - type: TextBox
        name: l{i}_bins
        format: number
        enable: (l{i}_type:histogram)
      - type: TextBox
        name: l{i}_intercept
        format: number
      - type: TextBox
        name: l{i}_slope
        format: number
        enable: (l{i}_type:abline)
"""
u += """  - type: CollapseBox
    label: Facets
    collapsed: true
    children:
      - type: ComboBox
        name: facetType
      - type: ComboBox
        name: facetScales
      - type: TextBox
        name: facetCols
        format: number
        enable: (facetType:wrap)
  - type: CollapseBox
    label: Axes and coordinates
    collapsed: true
    children:
      - type: ComboBox
        name: xTrans
      - type: ComboBox
        name: yTrans
      - type: TextBox
        name: xMin
        format: string
      - type: TextBox
        name: xMax
        format: string
      - type: TextBox
        name: yMin
        format: string
      - type: TextBox
        name: yMax
        format: string
      - type: ComboBox
        name: rangeMode
      - type: ComboBox
        name: coordType
  - type: CollapseBox
    label: Colour and fill scales
    collapsed: true
    children:
      - type: ComboBox
        name: colourPalette
      - type: TextBox
        name: colourValues
        format: string
        enable: (colourPalette:manual)
      - type: ComboBox
        name: fillPalette
      - type: TextBox
        name: fillValues
        format: string
        enable: (fillPalette:manual)
  - type: CollapseBox
    label: Legend
    collapsed: true
    children:
      - type: ComboBox
        name: legendPosition
      - type: TextBox
        name: colourTitle
        format: string
      - type: TextBox
        name: fillTitle
        format: string
      - type: TextBox
        name: shapeTitle
        format: string
      - type: TextBox
        name: sizeTitle
        format: string
      - type: TextBox
        name: alphaTitle
        format: string
  - type: CollapseBox
    label: Labels and theme
    collapsed: true
    children:
      - type: TextBox
        name: title
        format: string
      - type: TextBox
        name: subtitle
        format: string
      - type: TextBox
        name: caption
        format: string
      - type: TextBox
        name: xlab
        format: string
      - type: TextBox
        name: ylab
        format: string
      - type: ComboBox
        name: theme
      - type: CheckBox
        name: showCode
  - type: CollapseBox
    label: Theme details
    collapsed: true
    children:
      - type: TextBox
        name: baseSize
        format: number
      - type: ComboBox
        name: baseFamily
      - type: CheckBox
        name: hideGridMajor
      - type: CheckBox
        name: hideGridMinor
      - type: CheckBox
        name: hideTicks
      - type: ComboBox
        name: xTextAngle
      - type: CheckBox
        name: boldTitle
      - type: TextBox
        name: plotFill
        format: string
      - type: TextBox
        name: panelFill
        format: string
      - type: TextBox
        name: plotMargin
        format: string
"""
open("jamovi/layerplot.u.yaml","w").write(u)

# consistency check: every option has exactly one control and vice versa
names = []
def walk(n):
    if isinstance(n, dict):
        if 'name' in n and n.get('type') != 'VariableSupplier' and 'children' not in n:
            names.append(n['name'])
        for c in n.get('children', []): walk(c)
walk(yaml.safe_load(u))
opts = [o['name'] for o in yaml.safe_load(a)['options'] if o['name'] != 'data']
assert sorted(names) == sorted(opts), (set(opts)^set(names))
assert len(names) == len(set(names))
for o in yaml.safe_load(a)['options']:
    if o.get('type') == 'List':
        assert all(isinstance(x['name'], str) for x in o['options']), o['name']
        assert isinstance(o['default'], str) and o['default'] in [x['name'] for x in o['options']], o['name']
print(len(opts), "options; UI and options match; List names/defaults are strings")
