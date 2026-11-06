# Run from the repository root: Rscript checks/design_check.R
# Which candidate designs balance the simulated data, and at what cost in dropped units?
suppressMessages({library(tidyverse); library(optmatch); library(RItools); library(conflicted)})
conflicts_prefer(dplyr::select); conflicts_prefer(dplyr::filter); conflicts_prefer(optmatch::strata)
ln <- readLines("making_and_evaluating_matched_designs.qmd")
s <- grep("^```\\{r makedata\\}", ln); e <- which(ln == "```" & seq_along(ln) > s)[1]
eval(parse(text = ln[(s + 4):(e - 1)]))
covs <- c("sso", "age", "sex", "race", "edu", "grade", "tenure", "preY")
cov_fmla <- reformulate(covs, response = "trtbin")
psmod <- arm::bayesglm(cov_fmla, data = dat, family = binomial())
ps_dist <- match_on(psmod, data = dat)
mh_dist <- match_on(cov_fmla, data = dat, method = "rank_mahalanobis")
mh_ap <- match_on(trtbin ~ age + preY, data = dat, method = "rank_mahalanobis")
abs_preY <- match_on(trtbin ~ preY, data = dat, method = "euclidean")
abs_age <- match_on(trtbin ~ age, data = dat, method = "euclidean")

rep1 <- function(nm, fm) {
  dat$st <- fm
  b <- balanceTest(update(cov_fmla, . ~ . + strata(st)), data = dat)
  r <- data.frame(b$results[, , "st"])
  cat(sprintf("%-34s sets=%4d unmatched=%3d omnibus p=%.3g | std.diff preY=%.3f age=%.3f\n", nm,
              nlevels(droplevels(fm)), sum(is.na(fm)), b$overall["st", 3],
              r["preY", "std.diff"], r["age", "std.diff"]))
}
rep1("MH all covs, 1:5 (guide fm1)", fullmatch(mh_dist, min.controls = 1, max.controls = 5, data = dat))
rep1("PS model, 1:5", fullmatch(ps_dist, min.controls = 1, max.controls = 5, data = dat))
rep1("MH on age+preY only, 1:5", fullmatch(mh_ap, min.controls = 1, max.controls = 5, data = dat))
safe <- function(nm, expr) tryCatch(rep1(nm, expr), error = function(e) cat(sprintf("%-34s FAILED: %s\n", nm, conditionMessage(e))))
safe("PS + cal age 3 + preY .05 (full)", fullmatch(ps_dist + caliper(abs_age, 3) + caliper(abs_preY, .05), data = dat))
safe("PS + cal age 5 + preY .08 (full)", fullmatch(ps_dist + caliper(abs_age, 5) + caliper(abs_preY, .08), data = dat))
safe("MH + cal age 5 + preY .08 (full)", fullmatch(mh_dist + caliper(abs_age, 5) + caliper(abs_preY, .08), data = dat))
safe("preY caliper .08 only (guide fm2)", fullmatch(abs_preY + caliper(abs_preY, .08), data = dat))
safe("PS unrestricted full match", fullmatch(ps_dist, data = dat))
cat("\n== overlap on preY ==\n")
print(tapply(dat$preY, dat$trtbin, quantile, c(.05, .25, .5, .75, .95, 1)))
cat("share of treated with preY above the 95th pct of controls:", mean(dat$preY[dat$trtbin == 1] > quantile(dat$preY[dat$trtbin == 0], .95)), "\n")
cat("share of treated with preY above the max of controls:", mean(dat$preY[dat$trtbin == 1] > max(dat$preY[dat$trtbin == 0])), "\n")

