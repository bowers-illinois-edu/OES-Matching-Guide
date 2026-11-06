# Open questions for Jake

A running list of decisions and doubts about the guide. Add to it as we go and
strike items when they are settled (note the decision, don't just delete).

Audience (confirmed): external researchers at local and national governments.
The guide should include a simulated outcome with a known effect.

## Scope and framing

1. **Estimand.** Stage 1 weights blocks by size (an ATE-style weight).
   `balanceTest` reports a descriptive difference weighted by number treated
   (ATT-style). The 1:5 `fullmatch` restriction and `bmatch` both lean toward
   the treated group. Which estimand do we tell readers to target, and where do
   we say so?
2. **Block-size vs precision weights.** The text says precision weights are the
   standard for matched designs (pairs make them nearly equal anyway). Is that
   still the recommendation for full matches, where set sizes vary a lot? The
   claim that precision weighting is "biased in randomized experiments" is
   stated flatly (Stage 1); please check the wording.
3. **Dropping treated units.** `bmatch` with `subset_weight = 1` leaves about 66
   about 67 fewer pairs than `pairmatch` (466 vs 332 units dropped). For
   policy readers who need the whole treated population this changes the
   estimand. What should the default be (`subset_weight = NULL`, a tuned
   value, or full matching in `optmatch`)? How do we explain the choice?
4. **Scope.** Is `nmatch` / non-bipartite matching in scope for this audience
   (the section is an empty heading)? Same question for power / effective
   sample size, which the text defers repeatedly.
5. **Format and home.** One long `.qmd` or a multi-chapter Quarto book? It is
   meant to move into the OES SOP: any constraints on format or voice there?

## The running example

6. **The data-generating process doesn't make the argument.** In the code the
   outcome is `postY = .2*sd(preY)*trtbin + preY + rnorm(N)`. Only `preY`
   affects the outcome, so imbalance on `age` and the other covariates
   cannot bias the estimate, yet the Overview argues we must remove age. The
   naive estimate is also never shown against the truth. Should the outcome
   depend on `age`/`demog` so confounding visibly bites?
7. **True effect is nearly undetectable.** The planted effect is
   `.2*sd(preY)` (a few hundredths, since `preY` is scaled to [0, 1]) against
   noise with sd 1. What true effect and noise level do we want, and do we want
   effect heterogeneity (e.g. by sex)?
8. **No design reaches balance.** All five designs in the new comparison table
   fail the omnibus test (p between 1e-10 and 1e-40). Is that intended as
   motivation for iteration? If so, which iteration ends in a design that
   passes? Observation (not tested): treatment is driven mostly by `age`
   (`demog` is dominated by the `age` term) and `preY`, but Mahalanobis
   distance weights all eight covariates equally, so calipers on `age` and
   `preY` may be the lesson.
9. **Unobserved confounder for the sensitivity chapter.** The DGP has a latent
   `demog` that isn't a covariate, but it is nearly a function of `age`, `sex`,
   `race`. If the sensitivity chapter needs a real unobserved confounder, the
   DGP must add one deliberately.
10. **Outcome-blind design.** `postY` lives in `dat` the whole time, and Stage 1
    estimates effects before any design is chosen. Do we want a separate
    design data frame without the outcome so the code enforces the principle
    the Overview states?

## Assessing balance

11. **What counts as good enough?** The guide uses the omnibus p-value as the
    target. A large p-value is not evidence of equivalence, and p-values depend
    on sample size. Should we add standardized-difference thresholds or an
    equivalence test, and what thresholds for government readers?
12. **Guidance when balance is bad.** Readers need a decision path (tighten
    calipers, exact-match, trim, change the distance, accept and run
    sensitivity). Do we want a short "what to do next" section or flowchart?

## `designmatch` and software

13. **`subset_weight` scale.** Per the package docs it trades total distance
    against number of pairs on the scale of `dist_mat`. We rescale distances to
    mean about 1 and use `subset_weight = 1`; the docs' example uses the median
    of the distance matrix. I rewrote the comment from the docs but have not
    tested other values. Is 1 defensible?
14. **`near_exact` cap.** `devs = 10` per variable barely changes the result
    versus plain pair matching. What cap illustrates the trade-off, and should
    the cap scale with sample size?
15. **Solver.** The guide uses HiGHS with `approximate = 1`; the package docs
    recommend CPLEX or Gurobi for exact solutions. Is HiGHS adequate for the
    data sizes agency readers will have, and do results vary across solvers
    or runs?
16. **`senstrat` vs `sensemakr`.** Both are loaded, but they answer different
    questions (Rosenbaum bounds for matched sets vs regression-based
    robustness). Which is primary?

## Prose and housekeeping

17. **Voice.** The text mixes "this memo", "I already created", and "we", plus
    jargon (strata, caliper, harmonic weight) used before it is defined. Who
    edits for the government audience?
18. **Stale numbers in prose.** Counts such as "334 sets", "33 years", "5.8
    years", "about 13 years", "5 years", "6 percentage points" are typed by hand
    and will drift. Switch to inline R? Also "9 covariates" in the Mahalanobis
    text (the code uses 8), "19 p-values", and `rchisq(df = 16)` next to
    `pchisq(..., 15)`.
19. **Freeze workflow.** Any edit to the `.qmd`, even a comment, invalidates
    `_freeze/`; the Action has no R, so the publish fails until someone
    re-renders locally and commits `_freeze/`. Accept that, or run R in CI?
    Local Quarto is 1.10.x, CI pins 1.9.38.
20. **README.** Says groundhog; the project uses `renv`. Author surname
    spelling differs between the `.qmd` ("Jaques-Leslie") and git config.

## Decisions and findings since the first draft (2026-11-06)

- **Decided with Ben:** the example's spine is the estimand story (matching
  performs about like a correctly adjusted regression; its value is that it
  does not need the outcome model's form, it exposes overlap before outcomes
  are touched, and it forces us to say who the estimate is about). A second
  scenario shows regression and matching diverging under effect heterogeneity.
  Jake to confirm. See `CLAIMS_AUDIT.md` and `checks/`.
- **Questions 6-9 (example data):** the candidate structure in
  `checks/dgp_candidates.R` addresses them (planted effect .3, outcome depends
  on `preY` and `age`, unobserved `motiv`). It has not been put into the guide.
- **Question 8 (no design reaches balance):** answered. Designs that match every
  treated unit cannot balance because 29% of treated units lie above the
  controls' 95th percentile of `preY`; calipers on `age` and `preY` that drop
  about 6% of units reach p of about .8.
- **Questions 1-2 (estimand and weights): now urgent.** Under heterogeneity,
  precision weights gave .149 and treated-count weights gave .346 for the same
  matched design (the true effect on the matched treated was .352). Which weights does the
  guide recommend, and how do we explain the choice to non-statisticians?
- **New:** does the guide claim matching is better than regression, or only
  comparable and more transparent? Simulations support the second.
- **New:** unresolved warning ("Error gathering complete data") in the
  simulation scripts; source not found.
