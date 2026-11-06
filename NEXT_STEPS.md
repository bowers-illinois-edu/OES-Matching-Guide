# Where we left off (2026-11-06)

Branch: `refresh-freeze-and-designmatch-fixes` (not pushed, no PR). Read this
first, then `OPEN_QUESTIONS.md` (decisions for Jake) and `CLAIMS_AUDIT.md`
(what has and has not been checked).

## Destination

Readers (government staff judging whether a program works) should leave
believing matched designs are a legitimate way to learn about an effect, knowing
how and why to do one, and willing to try it. The technical bedrock is set first
and reframed for audiences afterwards.

## Done and committed (each rendered, `_freeze/` refreshed)

- Data: person-level `effect`, nonlinear outcome, true averages among treated,
  eligible untreated and all eligible (`makedata` chunk, "What is true" section).
- Stage 1 rewritten around a variable that confounds; weights follow the
  question (treated, untreated, everyone, subgroups, precision = people who
  could plausibly have been in either group). Checked against truth.
- Audit, `checks/` scripts, open questions.

## In progress and NOT verified (committed as a WIP commit; `_freeze/` does NOT match it)

- **Eligibility in the data** (income test on `pay`, only eligible people can
  enroll; `dat` is restricted to eligible people, `dat_all` keeps everyone).
  Treated falls to 250 of 750 eligible.
- Wording changes to the precision-weight text ("either received the
  intervention or not"; eligibility example removed).
- `checks/guide_data_check.R` updated for eligibility.
- The WIP commit's `_freeze/` is from before eligibility, so it is stale and
  publishing this branch's `.qmd` would fail in CI. A render was started but its
  result was not read. **Before trusting or
  publishing: run `quarto render`, then read the data and Stage 1 sections.**
  Prose in those sections was written for the data before eligibility and has
  not been rechecked against the new numbers: the treated share by stratum,
  "estimates are higher than the target in every row", "treated people still
  have higher baseline outcomes within each stratum", and the true averages.
- The design section still has stale text (see `CLAIMS_AUDIT.md` rows 5-9, 11-12:
  the 33-year set, "19 p-values", "9 covariates", the unrendered inline
  expression, the 334 sets, the "persons 1 and 3 ... 627 and 383" paragraph).

## Next, in order

1. Render, verify, and commit the eligibility work (or fix what the numbers
   contradict).
2. Rework the design section: the match-everyone design fails (p about 0),
   overlap and who the estimate is about, calipers that balance (propensity
   distance, 5 years on `age`, .08 on `preY`: p about .77, 69 units dropped on
   the guide's seed), what happens when eligibility is ignored (about 0.92 vs
   1.14 averaged over 30 seeds), and balance beyond the omnibus p-value.
3. Estimation chapter: treated-count weights for the treated question,
   subgroup effects, randomization-based tests within sets.
4. Sensitivity chapter: add the unobserved confounder (`motiv`) then.
5. Questions for Jake are in `OPEN_QUESTIONS.md` (which questions the guide
   supports, weighting framing and the overlap-population citation, spillover,
   eligibility and cutoffs, scope).

## Practical notes

- Any edit to the `.qmd`, even a comment, invalidates `_freeze/`. The GitHub
  Action has no R, so re-render locally and commit `_freeze/` before pushing to
  `main`.
- R 4.6.1 with RStudio's bundled Quarto 1.10.x worked. CI pins Quarto 1.9.38.
- Run the checks from the repo root, e.g. `Rscript checks/guide_data_check.R`.
  They emit one harmless warning per run ("Error gathering complete data");
  see `CLAIMS_AUDIT.md`.
- Hand-typed numbers in prose go stale when the data change. Prefer inline R.
