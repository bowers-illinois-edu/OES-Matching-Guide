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

The render takes several minutes because the matching and balance
computations are heavy. To avoid re-running that code on every publish, the
document sets `execute.freeze: auto`: rendering locally stores the computed
results under `_freeze/`, which is committed to the repository.

## Publishing to GitHub Pages

Publishing is automated by the GitHub Action in
`.github/workflows/publish.yml`. The Action does **not** run R. It renders
from the committed `_freeze/` results, so it only needs Quarto, and a build
takes about a minute. The Pages source is set to "GitHub Actions" (Settings ->
Pages), so nothing rendered is committed to `git` and `docs/` is gitignored.

The workflow to update the published guide:

1. Edit `making_and_evaluating_matched_designs.qmd` (or `big.bib`).
2. Render locally with `quarto render`. This re-executes the R code and
   refreshes `_freeze/`.
3. Commit your source changes **and** the updated `_freeze/`, then push to
   `main`. (You do not need to commit `docs/`.)
4. The Action renders and deploys; the guide goes live at
   <https://bowers-illinois-edu.github.io/OES-Matching-Guide/>.

If you push a change to the `.qmd` without refreshing `_freeze/`, the Action
will try to re-execute the R code, find no R available, and fail --- a
deliberate signal that you need to render locally first. You can also trigger
a publish by hand from the Actions tab ("Run workflow").
