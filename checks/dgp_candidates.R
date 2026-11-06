# Run from the repository root: Rscript checks/dgp_candidates.R
#
# Candidate causal structure for the guide's simulated data. It keeps the
# existing covariates and treatment mechanism, and changes only the outcome
# (plus one unobserved variable, `motiv`). The script asks, over repeated
# simulations, whether the candidate does what the guide needs:
#   1. the naive difference in means is visibly wrong;
#   2. a design that must match every treated unit does not balance;
#   3. a design with calipers (dropping some units) balances;
#   4. the matched estimate is close to the planted truth;
#   5. the planted effect is detectable;
#   6. an unobserved confounder (motiv_out > 0) biases every estimate by an
#      amount a sensitivity analysis could speak to.
suppressMessages({
  library(tidyverse); library(optmatch); library(RItools); library(estimatr); library(conflicted)
})
conflicts_prefer(dplyr::select); conflicts_prefer(dplyr::filter); conflicts_prefer(optmatch::strata)

ln <- readLines("making_and_evaluating_matched_designs.qmd")
s <- grep("^```\\{r makedata\\}", ln); e <- which(ln == "```" & seq_along(ln) > s)[1]
chunk <- ln[(s + 4):(e - 1)]

gen <- function(seed, tau = .3, motiv_out = 0, kink = 0, kink_at = .35) {
  # existing covariates and treatment, with the seed made a parameter
  eval(parse(text = sub("set.seed(12345)", sprintf("set.seed(%d)", seed), chunk, fixed = TRUE)))
  # NEW: an unobserved variable that pushes both treatment and outcome
  dat$motiv <- rnorm(N)
  sdx <- sd(dat$demog + dat$preY)
  dat$trtcont <- rnorm(N, mean = dat$demog + dat$preY + .5 * sdx * dat$motiv, sd = sdx)
  dat$trtbin <- as.numeric(dat$trtcont >= quantile(dat$trtcont, 2 / 3))
  # NEW outcome: nonlinear in preY, depends on age, optionally on motiv
  dat$postY <- tau * dat$trtbin + 2 * dat$preY + 4 * dat$preY^2 +
    kink * pmax(dat$preY - kink_at, 0) +
    .03 * (dat$age - 45) + motiv_out * dat$motiv + rnorm(N)
  dat
}

covs <- c("sso", "age", "sex", "race", "edu", "grade", "tenure", "preY")
cov_fmla <- reformulate(covs, response = "trtbin")

fe_est <- function(d, set) {
  k <- !is.na(set)
  d <- d[k, ]; d$set <- droplevels(factor(set[k]))
  coef(lm_robust(postY ~ trtbin, fixed_effects = ~set, data = d))[["trtbin"]]
}
omni <- function(d, set) {
  d$st <- set
  balanceTest(update(cov_fmla, . ~ . + strata(st)), data = d)$overall["st", 3]
}

warn_log <- character()
one_rep <- function(seed, tau, motiv_out, kink = 0, kink_at = .35) {
  withCallingHandlers(one_rep_inner(seed, tau, motiv_out, kink, kink_at),
    warning = function(w) {
      warn_log <<- c(warn_log, paste(deparse(conditionCall(w))[1], "|", substr(conditionMessage(w), 1, 60)))
      invokeRestart("muffleWarning")
    })
}
one_rep_inner <- function(seed, tau, motiv_out, kink = 0, kink_at = .35) {
  d <- gen(seed, tau, motiv_out, kink, kink_at)
  psmod <- arm::bayesglm(cov_fmla, data = d, family = binomial())
  ps_dist <- match_on(psmod, data = d)
  abs_age <- match_on(trtbin ~ age, data = d, method = "euclidean")
  abs_pre <- match_on(trtbin ~ preY, data = d, method = "euclidean")
  all15 <- fullmatch(ps_dist, min.controls = 1, max.controls = 5, data = d)
  cal <- fullmatch(ps_dist + caliper(abs_age, 5) + caliper(abs_pre, .08), data = d)
  c(naive = coef(lm(postY ~ trtbin, d))[["trtbin"]],
    ols_linear = coef(lm(postY ~ trtbin + preY + age, d))[["trtbin"]],
    ols_right_form = coef(lm(postY ~ trtbin + preY + I(preY^2) + age, d))[["trtbin"]],
    match_everyone = fe_est(d, all15),
    match_calipers = fe_est(d, cal),
    p_everyone = omni(d, all15),
    p_calipers = omni(d, cal),
    dropped_calipers = sum(is.na(cal)),
    treated_dropped = sum(is.na(cal) & d$trtbin == 1),
    se_naive = coef(summary(lm(postY ~ trtbin, d)))["trtbin", "Std. Error"])
}

nrep <- 20; tau <- .3
# kink > 0 adds a slope change in the outcome's dependence on preY at kink_at.
# Controls' preY: 95th percentile about .39, maximum about .60. A kink at .45 or
# .50 therefore sits where treated units exist but controls are scarce, so a
# regression must extrapolate there. ("ols_right_form" is only the right form
# when kink = 0.)
scen <- list(list(mo = 0, kink = 0, at = .35), list(mo = .4, kink = 0, at = .35),
             list(mo = 0, kink = 8, at = .35),
             list(mo = 0, kink = 20, at = .45), list(mo = 0, kink = 40, at = .50))
for (sc in scen) {
  cat(sprintf("\n=== planted effect %.2f, motiv effect %.1f, kink %g at preY=%.2f, %d simulations ===\n",
              tau, sc$mo, sc$kink, sc$at, nrep))
  res <- sapply(seq_len(nrep), function(i) one_rep(1000 + i, tau, sc$mo, sc$kink, sc$at))
  out <- data.frame(mean = rowMeans(res), sd = apply(res, 1, sd), median = apply(res, 1, median))
  print(round(out, 3))
  cat("bias (mean - truth):\n")
  print(round(rowMeans(res)[c("naive", "ols_linear", "ols_right_form", "match_everyone", "match_calipers")] - tau, 3))
}

cat("\nwarnings by call and message (count):\n")
print(sort(table(warn_log), decreasing = TRUE))
