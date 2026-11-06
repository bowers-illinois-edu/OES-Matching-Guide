# Run from the repository root: Rscript checks/dgp_check.R
# What drives treatment and outcome in the simulated data, and how biased is the naive estimate?
suppressMessages({library(tidyverse); library(estimatr)})
ln <- readLines("making_and_evaluating_matched_designs.qmd")
s <- grep("^```\\{r makedata\\}", ln); e <- which(ln == "```" & seq_along(ln) > s)[1]
eval(parse(text = ln[(s + 4):(e - 1)]))   # skip the 3 chunk-option lines

cat("\n== true effect and scale ==\n")
cat("sd(preY):", sd(dat$preY), " planted effect .2*sd(preY):", .2 * sd(dat$preY), " noise sd: 1\n")
cat("treated share:", mean(dat$trtbin), "\n")

cat("\n== what drives treatment? (cor with trtbin) ==\n")
print(round(cor(dat[, c("age", "demog", "preY", "sso", "tenure", "pay", "perf")], dat$trtbin), 3))
cat("R2 of demog on age alone:", summary(lm(demog ~ age, dat))$r.squared, "\n")
cat("R2 of demog on sso+age+sex+race+edu:", summary(lm(demog ~ sso + age + sex + race + edu, dat))$r.squared, "\n")
cat("R2 of preY on demog:", summary(lm(preY ~ demog, dat))$r.squared, "\n")

cat("\n== what drives the outcome? ==\n")
print(round(coef(summary(lm(postY ~ trtbin + preY + age + demog, dat))), 4))

cat("\n== naive vs adjusted estimates (truth =", .2 * sd(dat$preY), ") ==\n")
cat("naive diff in means:", coef(lm(postY ~ trtbin, dat))[["trtbin"]], "\n")
cat("adjust preY:", coef(lm(postY ~ trtbin + preY, dat))[["trtbin"]], "\n")
cat("naive SE:", coef(summary(lm(postY ~ trtbin, dat)))["trtbin", "Std. Error"], "\n")

cat("\n== how much does confounding bias the naive estimate? repeat sims ==\n")
sim <- replicate(200, {
  d <- dat
  d$postY <- .2 * sd(d$preY) * d$trtbin + d$preY + rnorm(nrow(d))
  c(naive = coef(lm(postY ~ trtbin, d))[["trtbin"]], adj = coef(lm(postY ~ trtbin + preY, d))[["trtbin"]])
})
print(rowMeans(sim)); print(apply(sim, 1, sd))
