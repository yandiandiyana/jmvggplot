# Draft e-mail to the jamovi team (not sent)

To: contact@jamovi.org
Subject: New module submission: jmvggplot (layer-by-layer ggplot2 plots)

Hello,

I would like to submit a module for the jamovi library.

- Name: jmvggplot (analysis: "Layered ggplot", under Plots)
- Version: 0.0.1
- Author / maintainer: Yandi Andiyana <yandi.andiyana@yandex.com>
- Source: https://github.com/yandiandiyana/jmvggplot
- Licence: GPL (>= 2)

What it does: it builds ggplot2 plots layer by layer (up to 6 layers with 23 layer types, facets, scales, coordinates, themes),
and shows the equivalent R code generated from the same validated plot specification. It includes an example dataset
(palmerpenguins, CC0) in the Data Library.

Testing so far: installed with jmvtools and side-loaded as a .jmo on Windows with jamovi 2.7.39.0; syntax mode works;
R unit tests (testthat) pass; manual checklists are in docs/MANUAL_CHECKLIST.md. I have not tested macOS or Linux.

Dependencies: jmvcore, R6, ggplot2 (>= 3.5.0), all permissive or GPL-compatible. No extension packages.
One question: does the library's CRAN snapshot for the current jamovi series include ggplot2 3.5.0 or newer?

Thank you,
Yandi Andiyana
