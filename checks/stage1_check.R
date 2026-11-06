# Run from the repository root: Rscript checks/stage1_check.R
# Two strata (baseline outcome above / below the median) on the guide's data:
# what do the three ways of combining the strata give, relative to the truth?
suppressMessages({library(tidyverse); library(estimatr)})
ln <- readLines("making_and_evaluating_matched_designs.qmd")
s <- grep("^```\\{r makedata\\}", ln); e <- which(ln == "```" & seq_along(ln) > s)[1]
eval(parse(text = ln[(s + 4):(e - 1)]))

report <- function(dat, cut_name) {
  cat("\n==", cut_name, "==\n")
  sets <- dat %>% group_by(stratum) %>% summarize(
    n = n(), nT = sum(trtbin), nC = sum(1 - trtbin),
    est = mean(postY[trtbin == 1]) - mean(postY[trtbin == 0]),
    true_effect_among_treated = mean(effect[trtbin == 1]), .groups = "drop")
  sets <- sets %>% mutate(w_size = n / sum(n), w_treated = nT / sum(nT),
                          w_prec0 = n * (nT / n) * (nC / n), w_prec = w_prec0 / sum(w_prec0))
  print(as.data.frame(sets), digits = 3)
  cat("truth (average effect among all treated):", mean(dat$effect[dat$trtbin == 1]), "\n")
  cat("naive:", coef(lm(postY ~ trtbin, dat))[["trtbin"]], "\n")
  cat("weighted by stratum size:", sum(sets$est * sets$w_size), "\n")
  cat("weighted by number treated:", sum(sets$est * sets$w_treated), "\n")
  cat("precision (fixed-effects) weights:", sum(sets$est * sets$w_prec),
      " | lm_robust fixed effects:", coef(lm_robust(postY ~ trtbin, fixed_effects = ~stratum, data = dat))[["trtbin"]], "\n")
}
d1 <- dat %>% mutate(stratum = ifelse(preY > median(preY), "high preY", "low preY"))
report(d1, "split at median preY")
d2 <- dat %>% mutate(stratum = ifelse(age > median(age), "older", "younger"))
report(d2, "split at median age")
d3 <- dat %>% mutate(stratum = ifelse(sex == "M", "M", "F"))
report(d3, "split by sex")
