# Run from the repository root: Rscript checks/guide_data_check.R
#
# Checks the data actually used in the guide (the `makedata` chunk of the .qmd)
# against what the text claims: naive vs true effect, whether a design that
# matches everyone fails, whether calipers balance, and how the weighting choice
# changes the matched estimate. Seed 12345 is the guide's own data; the other
# seeds show how typical that draw is.
suppressMessages({
  library(tidyverse); library(optmatch); library(RItools); library(estimatr); library(conflicted)
})
conflicts_prefer(dplyr::select); conflicts_prefer(dplyr::filter); conflicts_prefer(optmatch::strata)

ln <- readLines("making_and_evaluating_matched_designs.qmd")
s <- grep("^```\\{r makedata\\}", ln); e <- which(ln == "```" & seq_along(ln) > s)[1]
chunk <- ln[(s + 4):(e - 1)]
make <- function(seed) {
  eval(parse(text = sub("set.seed(12345)", sprintf("set.seed(%d)", seed), chunk, fixed = TRUE)))
  dat
}
covs <- c("sso", "age", "sex", "race", "edu", "grade", "tenure", "preY")
cov_fmla <- reformulate(covs, response = "trtbin")

omni <- function(d, set) {
  d$st <- set
  balanceTest(update(cov_fmla, . ~ . + strata(st)), data = d)$overall["st", 3]
}
design_est <- function(d) {
  # propensity distance + calipers (5 years age, .08 preY), full match; ATT-weighted estimate
  psmod <- arm::bayesglm(cov_fmla, data = d, family = binomial())
  ps_dist <- match_on(psmod, data = d)
  abs_age <- match_on(trtbin ~ age, data = d, method = "euclidean")
  abs_pre <- match_on(trtbin ~ preY, data = d, method = "euclidean")
  all15 <- fullmatch(ps_dist, min.controls = 1, max.controls = 5, data = d)
  cal <- fullmatch(ps_dist + caliper(abs_age, 5) + caliper(abs_pre, .08), data = d)
  inset <- !is.na(cal)
  dd <- d[inset, ]; dd$set <- droplevels(factor(cal[inset]))
  sets <- dd %>% group_by(set) %>%
    summarize(diff = mean(postY[trtbin == 1]) - mean(postY[trtbin == 0]), nT = sum(trtbin),
              nC = sum(1 - trtbin), .groups = "drop")
  list(all15 = all15, cal = cal, inset = inset,
       att = weighted.mean(sets$diff, sets$nT),
       prec = coef(lm_robust(postY ~ trtbin, fixed_effects = ~set, data = dd))[["trtbin"]],
       all15_prec = coef(lm_robust(postY ~ trtbin, fixed_effects = ~ factor(all15), data = d))[["trtbin"]])
}
one <- function(seed) {
  d_all <- make(seed)                    # everyone, including ineligible people
  d <- d_all[d_all$eligible == 1, ]      # the program's population
  r <- design_est(d)
  r_all <- design_est(d_all)             # same design, ignoring eligibility
  c(n_eligible = nrow(d), n_treated = sum(d$trtbin),
    truth_att = mean(d$effect[d$trtbin == 1]),
    truth_att_matched = mean(d$effect[d$trtbin == 1 & r$inset]),
    truth_eligible_untreated = mean(d$effect[d$trtbin == 0]),
    truth_all_eligible = mean(d$effect),
    naive_vs_all_untreated = coef(lm(postY ~ trtbin, d_all))[["trtbin"]],
    naive_vs_eligible_untreated = coef(lm(postY ~ trtbin, d))[["trtbin"]],
    match_everyone_precision = r$all15_prec,
    calipers_treated_count_wt = r$att,
    calipers_precision_wt = r$prec,
    calipers_ignoring_eligibility = r_all$att,
    regression_eligible = coef(lm(postY ~ trtbin + preY + age, d))[["trtbin"]],
    p_match_everyone = omni(d, r$all15), p_calipers = omni(d, r$cal),
    units_dropped = sum(!r$inset), treated_dropped = sum(!r$inset & d$trtbin == 1),
    share_treated_above_max_control_preY = mean(d$preY[d$trtbin == 1] > max(d$preY[d$trtbin == 0])))
}

cat("\n== The guide's own data (seed 12345) ==\n")
print(round(one(12345), 3))
cat("\n== 30 other seeds: mean and sd ==\n")
res <- sapply(1:30, function(i) one(5000 + i))
print(round(data.frame(mean = rowMeans(res), sd = apply(res, 1, sd)), 3))
