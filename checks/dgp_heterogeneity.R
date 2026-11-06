# Run from the repository root: Rscript checks/dgp_heterogeneity.R
#
# What if the effect is larger where baseline outcome (preY) is high, which is
# where controls are scarce? Then "the effect on all treated units" and "the
# effect on treated units that have comparable controls" differ, and a
# regression and a caliper-matched design answer different questions.
# Reuses gen() and helpers from dgp_candidates.R (everything before `nrep`).
src <- readLines("checks/dgp_candidates.R")
eval(parse(text = src[seq_len(grep("^warn_log <- ", src) - 1)]))

het <- 4  # effect = tau + het * (preY - .3) for treated units

rep_het <- function(seed, tau = .3) {
  d <- gen(seed, tau, motiv_out = 0, kink = 0)
  d$postY <- d$postY + het * d$trtbin * (d$preY - .3)  # add heterogeneity
  d$eff <- tau + het * (d$preY - .3)
  psmod <- arm::bayesglm(cov_fmla, data = d, family = binomial())
  ps_dist <- match_on(psmod, data = d)
  abs_age <- match_on(trtbin ~ age, data = d, method = "euclidean")
  abs_pre <- match_on(trtbin ~ preY, data = d, method = "euclidean")
  cal <- fullmatch(ps_dist + caliper(abs_age, 5) + caliper(abs_pre, .08), data = d)
  inset <- !is.na(cal)
  # ATT-style matched estimate: weight each set's difference by its number treated
  dd <- d[inset, ]; dd$set <- droplevels(factor(cal[inset]))
  sets <- dd %>% group_by(set) %>%
    summarize(diff = mean(postY[trtbin == 1]) - mean(postY[trtbin == 0]), nT = sum(trtbin))
  m <- mean(d$preY[d$trtbin == 1])
  c(truth_att_all_treated = mean(d$eff[d$trtbin == 1]),
    truth_att_matched_treated = mean(d$eff[d$trtbin == 1 & inset]),
    ols_no_interaction = coef(lm(postY ~ trtbin + preY + age, d))[["trtbin"]],
    ols_with_interaction = coef(lm(postY ~ trtbin * I(preY - m) + age, d))[["trtbin"]],
    match_precision_weights = fe_est(d, cal),
    match_att_weights = weighted.mean(sets$diff, sets$nT))
}

res <- sapply(1:20, function(i) rep_het(1000 + i))
cat(sprintf("\nEffect = .3 + %g*(preY - .3) for treated; 20 simulations\n", het))
print(round(data.frame(mean = rowMeans(res), sd = apply(res, 1, sd)), 3))

cat("\n== which call emits the warning? ==\n")
d <- gen(1001, .3, 0, 0)
psmod <- arm::bayesglm(cov_fmla, data = d, family = binomial())
ps_dist <- match_on(psmod, data = d)
abs_age <- match_on(trtbin ~ age, data = d, method = "euclidean")
abs_pre <- match_on(trtbin ~ preY, data = d, method = "euclidean")
all15 <- fullmatch(ps_dist, min.controls = 1, max.controls = 5, data = d)
cal <- fullmatch(ps_dist + caliper(abs_age, 5) + caliper(abs_pre, .08), data = d)
options(warn = 1)
cat("omni on match-everyone (no NA sets): "); invisible(omni(d, all15)); cat("done\n")
cat("omni on calipers (has NA sets): "); invisible(omni(d, cal)); cat("done\n")
