# A Guide to Creating, Assessing, and Using Matched Designs for Impact Evaluation

This is a guide to using modern matching methods to create, assess, and use
stratified research designs in impact evaluation.

## Notes for contributors

### Location of the repository

For now we are working in bowers-illinois-edu but plan to transition this guide to be a part of the broader OES SOP.

### Package Management

We are using this little repo to try out the [groundhog](https://groundhogr.com/) approach to handling R packages since we tend to use the `renv` approach.

## Building the guide

The guide is a single Quarto document, `making_and_evaluating_matched_designs.qmd`.
Rendering it requires R, Quarto (>= 1.4), and the following R packages:

```r
install.packages(c(
  "tidyverse", "RItools", "optmatch", "designmatch", "highs", "coin",
  "conflicted", "estimatr", "senstrat", "sensemakr", "formula.tools",
  "gridExtra", "arm", "MASS", "renv"
))
```

`designmatch` solves an integer program; this guide uses the open-source
`highs` solver, so no commercial solver (Gurobi, CPLEX) is needed.

To render:

```sh
quarto render
```

The full render takes several minutes because the matching and balance
computations are heavy.

## Hosting on GitHub Pages

`_quarto.yml` sends the rendered output to the `docs/` directory. The published
site is served from there:

1. Render locally with `quarto render` (this writes
   `docs/making_and_evaluating_matched_designs.html`).
2. Commit the contents of `docs/` along with your source changes.
3. In the repository on GitHub, go to Settings -> Pages and set the source to
   the `main` branch, `/docs` folder.

`docs/index.html` redirects the site root to the guide, and `docs/.nojekyll`
tells GitHub Pages not to run the files through Jekyll. The rendered HTML is
self-contained (`embed-resources: true`), so it carries its own CSS, fonts, and
images in one file.
