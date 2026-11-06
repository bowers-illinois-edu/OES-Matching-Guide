# Claims audit

What the guide currently asserts, what I checked, and what is left for Jake.
Scripts are in `checks/` (run from the repo root with `Rscript checks/<name>.R`).
Numbers below come from those scripts or from the 2026-11-06 local render.

Intended destination (Ben, 2026-11-06): readers should come away believing
matched designs are a legitimate way to learn about an effect, knowing how to
do one and why, and willing to try it. A technical bedrock comes first; we
reframe it for different audiences afterwards.

## What the checks show about the running example

*These findings describe the original data (outcome driven by `preY` only). The
guide's `makedata` chunk now uses the revised outcome with a person-level
`effect`; its results are in `checks/guide_data_check.R`. On the revised data:
naive 1.94 vs true effect on the treated 1.01; matching everyone fails (p < 1e-3);
propensity distance with calipers of 5 years on `age` and .08 on `preY` balances
(p = .84) and drops 75 units (42 treated).*

| Finding | Evidence |
|---|---|
| Treatment is driven by `preY` (cor .41) and `age` (.30). `demog` is 96% `age`. | `dgp_check.R` |
| The outcome depends on `preY` only (coefficient .89); `age` has coefficient ~0. So imbalance on `age` cannot bias the estimate here. | `dgp_check.R` |
| True effect = 0.033 (`.2*sd(preY)`); the naive difference in means averages 0.17 over 200 simulations (one draw: 0.26), so the naive bias is real. Adjusting linearly for `preY` recovers it (0.029), but the standard error is about 0.07, so even the right estimate is not distinguishable from zero. | `dgp_check.R` |
| Overlap is poor on `preY`: 29% of treated units sit above the controls' 95th percentile, and 9.6% sit above the largest control value. | `design_check.R` |
| Designs that must match every treated unit stay badly imbalanced on `preY` and `age`, whichever distance they use (omnibus p from 1e-36 to 1e-48; `preY` std. diff .56-.72). | `design_check.R` |
| A design that drops units balances: propensity distance plus calipers of 5 years on `age` and .08 on `preY` gives omnibus p = .84, 75 of 1000 units dropped; tighter calipers (3, .05) give p = .23, 132 dropped. | `design_check.R` |
| The same calipers with Mahalanobis distance instead of the propensity distance do not balance (p = 1.6e-19). A `preY` caliper alone fixes `preY` but leaves `age` badly off (std. diff .91). | `design_check.R` |

So the reason the guide's designs fail is not tuning: some treated units have no
comparable controls, and a design that insists on matching all of them cannot
balance. Matching shows who can be compared; getting balance means narrowing
the claim to those people. That is a candidate backbone for the guide.

## Candidate causal structure (`checks/dgp_candidates.R`)

Keeps the existing covariates and treatment mechanism. Changes: a planted
effect of 0.3 (detectable: SE about .085), an outcome that depends on `preY`
(nonlinearly) and `age`, and an unobserved `motiv` that raises both treatment
probability and (optionally) the outcome. 20 simulations per scenario; truth
is 0.30. Mean estimates:

| Estimator | No unobserved confounding | `motiv` affects outcome (.4) | Extra kink in `preY` effect |
|---|---|---|---|
| Naive difference | 1.24 | 1.46 | 1.75 |
| Match everyone (1:5, propensity) | 0.89 | 1.15 | 1.26 |
| Linear regression on `preY`, `age` | 0.31 | 0.62 | 0.32 |
| Regression with the true functional form | 0.31 | 0.61 | 0.31 |
| Match with calipers (5 yrs, .08), fixed effects | 0.31 | 0.63 | 0.32 |

- Calipers drop about 59 of 1000 units (27 of 334 treated, so the estimate
  describes about 92% of the treated group); median omnibus p = .89.
  Matching everyone: p < 1e-3 in every run. Balance results do not change
  across scenarios because the design never sees the outcome.
- **Regression is not biased where we expected it to fail.** With the outcome's
  slope changing sharply at `preY` .45 or .50 (where treated units exist and
  controls are scarce), linear regression stays close to unbiased (mean .309 and
  .286 vs truth .30). What changes is precision: its standard deviation across
  simulations rises from .08 to .125 and .165, while matching stays at .087-.088.
  So extrapolation costs regression stability here, not bias. (`ols_right_form`
  is only the right form when there is no kink.)
- With `motiv` active, every adjusted estimate is biased by about +0.3, which
  gives the sensitivity chapter something concrete to bound.
- **The repeated warning is understood.** The simulation scripts emit one
  warning per simulation, "Error gathering complete data...". It comes from
  `match_on(psmod, data = d)`: inside `optmatch`, `scores()` tries to rebuild
  the model frame, falls back, and warns that it will not impute missing
  values. A likely reason it appears only in the scripts: `scores()` re-evaluates
  the model's original `data = d`, and `d` is a local variable inside the
  simulation function, whereas the guide's `dat` is global. (I inferred this; I
  did not test it.) These data have no missing values, so the matches are
  unaffected either way.

### Where regression and matching really diverge: effect heterogeneity (`checks/dgp_heterogeneity.R`)

If the effect grows with `preY` (effect = .3 + 4 * (preY - .3) for treated),
the question "what is the effect?" has more than one answer. 20 simulations:

| Quantity | Mean |
|---|---|
| True average effect on all treated units | .466 |
| True average effect on the treated units that have comparable controls | .352 |
| Matched estimate, sets weighted by number treated | .346 |
| Matched estimate, precision (fixed-effects) weights | .149 |
| Regression without interaction | .163 |
| Regression with interaction, evaluated at treated mean | .551 |

- Matching with treated-count weights recovers the effect for the comparable
  treated (.346 vs .352); it does not recover the effect for all treated, and
  the guide should say so.
- **The weighting choice moves the answer by more than a factor of two.**
  Precision weights (the fixed-effects default the guide recommends) give .149
  because they emphasize sets where the treated share is near one half, not the
  treated units. Open question 1 and 2 are therefore not cosmetic.
- Regression with an interaction extrapolates to the treated units with no
  comparable controls and overshoots (.551 vs .466, SD .19).
- Estimates are noisy (SDs .15-.19 across simulations), so differences of
  about .05 are not reliable at 20 simulations.

## Claim ledger

Status: **verified** (checked by running it), **wrong/stale** (the guide is
inconsistent with its own output), **unverified** (reasoned from definitions or
docs, not run), **judgment** (needs Jake).

| # | Claim in the guide | Status | Notes |
|---|---|---|---|
| 1 | Block-size and precision weighted estimates match their by-hand versions (lm, lm_robust, fixed effects, `difference_in_means`) | verified | .2645 four ways; .2639 four ways |
| 2 | `balanceTest`, `xBalance` and `coin` give the same omnibus statistic | verified | all 228.8 on 15 df, p = 2.9e-40 |
| 3 | A hand-built permutation of d² agrees with the chi-squared reference | verified (approximately) | by hand 230.5 vs 228.8; p below 1 in 10,000 either way |
| 4 | Omnibus df is 15 | verified | 18 columns minus dependent dummies. The unused `rchisq(df = 16)` in the text is wrong |
| 5 | "19 p-values" in the balance table | wrong | the table has 18 rows |
| 6 | "Worst set differs by 33 years, a 15-year-old and a 49-year-old" | wrong | the worst set differs by 47.1 (ages 30.8-77.9); the 33.3 set is second worst |
| 7 | "Half of sets differ by less than 5.8 years, 90% by less than about 13" | wrong | output: median 4.9, 90th percentile 12.2 |
| 8 | "the worst 100 sets out of 334" in the age figure | likely wrong (not run) | the code keeps rows above the 90th percentile of per-person differences, which should be roughly a tenth of the 334 sets, not 100 |
| 9 | Inline `r max(dat_plot1$agediff)` | wrong | the inline code is split across a line, so the text shows the literal `r max(...)` |
| 10 | "about 5 years" of age difference and "about 6 points" for White respondents after matching | verified | 5.03 years; 5.9 points |
| 11 | "Mahalanobis distance weights each covariate equally" | unverified, likely wrong | Mahalanobis uses the inverse covariance, so correlated columns are down-weighted and multi-level factors (race 3, edu 8) contribute many columns. The optmatch help does not elaborate |
| 12 | "9 covariates" in the Mahalanobis text | wrong | the formula has 8 variables (18 columns) |
| 13 | near_exact `devs` caps the number of mismatched pairs per column | verified | `devs = 10` gave exactly 10 mismatched pairs on grade and 10 on sex |
| 14 | Omnibus p-value is a sufficient single target | judgment, partly wrong | it can be 1 even when a standardized difference is sizeable: unrestricted full matching on the propensity score gives p = 1 with `preY` std. diff .19 and `age` -.11. I have not isolated why; one candidate is that very lopsided sets (the caliper full match in the guide has sets of 1 treated to 55-57 controls and an effective sample size of 268.6 vs 334 pairs) leave the test little to work with. Report effective sample size and standardized differences alongside the p-value |
| 15 | Block-size weights are unbiased in randomized experiments, precision weights biased | judgment | true only for the ATE under varying treatment proportions and heterogeneous effects; pairs make them identical. Needs a precise sentence and a citation |
| 16 | "p = .8 means smaller imbalance than 80% of randomized experiments" | verified by definition | p is the share of equivalent experiments with imbalance at least as large as ours |
| 17 | The matched design adjusts away the alternative explanations that matter | wrong for this data | only `preY` affects the outcome, so the example cannot show age mattering |

Not yet audited: the estimation and sensitivity chapters (empty), the
non-bipartite section (empty), and the citations themselves.

## Proposed order for setting the bedrock

1. Decide the example's causal structure on purpose (see open questions 6-9),
   so that the numbers in the guide are the truth we planted.
2. Make each step of the argument a short chunk whose output we have checked,
   in this order: naive estimate vs truth; a design that insists on matching
   everyone, and why it fails; overlap and the estimand it implies; a design
   that balances and what it costs; estimate and test within sets;
   sensitivity.
3. For every sentence that states a fact, point to the chunk or reference that
   backs it, so review is "does this evidence support this claim", not
   re-deriving the statistics.
