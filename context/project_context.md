# EA-PC Project Context: Causal Discovery and Covariate Selection for Nonlinear Data

## 1. Project Overview

This project studies **causal discovery and covariate selection** for estimating the causal effect of a treatment variable `X` on an outcome variable `Y` from observational data.

The setting is nonlinear synthetic data with observed covariates `O`. The main task is to decide whether `X` has a causal effect on `Y`, and, when possible, return a valid adjustment set and estimate the causal effect.

The project compares three approaches:

1. **EHS** from Entner et al.
2. **LSAS** from Li et al.
3. **EA-PC**, my proposed method: an Entner-aware PC-style algorithm.

The motivation is that EHS is globally exhaustive and becomes computationally expensive, especially when using nonlinear conditional independence tests. LSAS improves efficiency by restricting the search to local Markov blankets. EA-PC aims to improve efficiency further by collecting Entner-style evidence during a PC-style skeleton search and then switching to a local LSAS-style completion step.

---

## 2. Main Research Question

Given observational data containing:

- treatment variable `X`,
- outcome variable `Y`,
- observed pretreatment covariates `O`,

can we efficiently decide whether `X` has a causal effect on `Y`, and, if yes, identify a valid adjustment set for estimating that effect?

The possible algorithm outputs are:

| Decision | Meaning |
|---|---|
| `+` | A causal effect is inferred and an adjustment set was found. |
| `0` | No causal effect is inferred. |
| `?` | The algorithm cannot decide from the available conditional independence information. |

If the output is `+`, the algorithm also returns an adjustment set `Z` and estimates the causal effect using a g-formula estimator.

---

## 3. Assumptions

The current experiment is based on the following assumptions.

### 3.1 Pretreatment Assumption

All observed covariates in `O` are pretreatment variables with respect to `(X, Y)`.

This means:

- `X` is not a causal ancestor of any variable in `O`,
- `Y` is not a causal ancestor of any variable in `O`,
- covariates are measured before treatment and outcome.

This assumption is important because Entner-style adjustment rules may otherwise select descendants of the treatment, which can lead to invalid adjustment sets.

### 3.2 Outcome Is Not an Ancestor of Treatment

The outcome `Y` is assumed not to be a causal ancestor of the treatment `X`.

This allows the ordered pair `(X, Y)` to be interpreted as a treatment-outcome pair.

### 3.3 No Unobserved Confounders Adjacent to X and Y

The current EA-PC setup assumes no unobserved confounders adjacent to `X` and `Y`.

This assumption is used to justify recovering useful local neighborhood / Markov blanket information around `X` and `Y` from the PC-style skeleton search.

### 3.4 Causal Markov and Faithfulness Assumptions

The observational distribution is assumed to satisfy:

- the causal Markov condition,
- the causal faithfulness condition.

Therefore, conditional independence relationships in the data correspond to graphical separation relationships in the underlying causal graph.

---

## 4. Entner-Style Rules Used for Decisions

The decision rules are based on conditional independence and dependence patterns from Entner et al.

Let `S` or `w` be a witness variable, and let `Z` be a conditioning set.

### 4.1 R1: Nonzero Causal Effect with Adjustment Set

If there exists a witness variable `S` and a conditioning set `Z` such that:

```text
S not independent of Y | Z
S independent of Y | Z ∪ {X}
```

then infer that `X` has a causal effect on `Y`, and use `Z` as an adjustment set.

Output:

```text
+
```

with adjustment set `Z`.

### 4.2 R2a: Zero Effect by Conditional Independence of X and Y

If there exists a conditioning set `Z` such that:

```text
X independent of Y | Z
```

then infer that `X` has no causal effect on `Y`.

Output:

```text
0
```

### 4.3 R2b: Zero Effect by Witness Variable

If there exists a witness variable `S` and conditioning set `Z` such that:

```text
S not independent of X | Z
S independent of Y | Z
```

then infer that `X` has no causal effect on `Y`.

Output:

```text
0
```

### 4.4 Unknown Case

If neither R1 nor R2 applies, the algorithm cannot decide based only on the observed conditional independence information.

Output:

```text
?
```

### 4.5 Multiple Hits and Conflicts

With an independence oracle, contradictory R1 and R2 evidence should not occur under the stated assumptions. In finite samples, however, multiple R1 and R2 hits can occur because CI tests are noisy.

The algorithms handle this as follows:

- **EHS / Entner-style conservative rule:** if only R1 hits are found, output `+`; if only R2 hits are found, output `0`; if both R1 and R2 hits are found, output `?`.
- **LSAS / Li et al. Algorithm 1 rule:** R2 has priority. If any R2 hit is found, output `0`, even if R1 hits were also found. If R1 hits are found and no R2 hit is found, output `+`. If neither is found, output `?`.
- **EA-PC rule:** use the conservative Entner-style conflict rule. If both R1 and R2 evidence are collected, output `?`.

---

## 5. Algorithms Compared

## 5.1 EHS

EHS is the global exhaustive method from Entner et al.

It searches over:

```text
Z ⊆ O
w ∈ O \ Z
```

and applies R1, R2a, and R2b exhaustively.

### Decision Rule

EHS uses a conservative Entner-style finite-sample rule:

| Evidence found | Decision |
|---|---|
| One or more R1 hits, no R2 hits | `+` |
| One or more R2 hits, no R1 hits | `0` |
| Both R1 and R2 hits | `?` |
| No R1 or R2 hits | `?` |

When the decision is `+`, all unique R1 adjustment sets are collected and used for effect estimation.

### Advantages

- Conceptually close to the original Entner rules.
- Searches globally over all observed covariates.
- Useful as a small-scale baseline.

### Disadvantages

- Exponential in the number of observed covariates.
- Very expensive with nonlinear conditional independence tests such as KCI.
- May be infeasible for larger nonlinear experiments.

### Current Experimental Plan

Use EHS only for small sanity-check experiments. For larger nonlinear experiments, EHS may be omitted because it is not computationally feasible.

---

## 5.2 LSAS

LSAS is the local search adjustment set method from Li et al.

It has two main steps:

1. Learn the Markov blankets of `X` and `Y`:

```text
MB(X), MB(Y)
```

2. Search only locally over:

```text
S ∈ MB(X) \ {Y}
Z ⊆ MB(Y) \ {X}
```

and apply the same R1/R2 rules.

### Decision Rule

LSAS follows Li et al.'s Algorithm 1 priority:

| Evidence found | Decision |
|---|---|
| Any R2 hit | `0` |
| One or more R1 hits, no R2 hits | `+` |
| No R1 or R2 hits | `?` |

This means R2 has priority over R1 in the written LSAS algorithm. If an R1 hit is found, LSAS can estimate the effect using the corresponding `Z`; however, if an R2 hit is found during the search, the algorithm returns `0`.

### Main Disadvantage

LSAS uses total conditioning to find the Markov Blanket. This does not seem like the best idea especially when the number of covariates increases. I think that this is the main weakness of LSAS and we could be able to beat it with my proposed method, especially as the number of nodes increases.

---

## 5.3 EA-PC: Entner-Aware PC

EA-PC is my proposed method.

It combines PC-style skeleton discovery with Entner-style rule detection.

### Main Idea

During PC skeleton search, many conditional independence tests are already performed. EA-PC reuses these tests to collect evidence for R1, R2a, and R2b while the skeleton is being pruned.

### Algorithm Sketch

1. Start from a complete undirected graph over all observed variables.
2. Run PC-style skeleton pruning using conditional independence tests.
3. Use `alpha_pc` to decide whether to remove skeleton edges.
4. Store CI-test p-values in a cache.
5. During the PC search, check whether each CI test contributes to Entner-style evidence:

   - R2a: `X independent of Y | Z`
   - R1: `w not independent of Y | Z` and `w independent of Y | Z ∪ {X}`
   - R2b: `w not independent of X | Z` and `w independent of Y | Z`

6. Stop the PC search once the conditioning level is larger than the neighborhoods of `X` and `Y`.
7. At that point, use the discovered local neighborhoods / Markov blankets of `X` and `Y`.
8. Run the remaining LSAS-style local CI tests over:

```text
S ∈ MB_hat(X) \ {Y}
Z ⊆ MB_hat(Y) \ {X}
```

9. Return one of `+`, `0`, or `?`.
10. If `+`, estimate the causal effect using the selected adjustment set.

### Decision Rule

EA-PC collects Entner-style evidence during the PC skeleton search and during the local LSAS-style completion step. It then uses a conservative conflict rule:

| Evidence found | Decision |
|---|---|
| One or more R1 hits, no R2 hits | `+` |
| One or more R2 hits, no R1 hits | `0` |
| Both R1 and R2 hits | `?` |
| No R1 or R2 hits | `?` |

When the decision is `+`, EA-PC estimates the effect using the unique adjustment sets found by R1.

### Motivation

EA-PC should become more advantageous as the number of observed nodes increases, because it avoids the fully global exhaustive search of EHS and tries to exploit local information collected during PC search.
In addition to that the number of covariates that are put into the adjustment set is capped which is better than the total conditioning approach used by LSAS.
---

## 6. Conditional Independence Testing

The experiments are focused on both linear and nonlinear data.

Important implementation points:

- All algorithms should use the same CI test.
- PC edge removal and Entner-rule decisions may use different thresholds.
- For large sample sizes, purely p-value-based decisions may become too sensitive to tiny dependencies.

Potential threshold structure:

```python
alpha_pc = 0.01 or 0.05
alpha_entner_ind = 0.10
alpha_entner_dep = 0.01
```

---

## 7. Effect Estimation

If an algorithm returns `+`, it also returns an adjustment set `Z`.

The causal effect is then estimated using a g-formula estimator, currently based on a predictive model such as a random forest.

The stored `VASs` field contains the adjustment sets actually found by R1 hits of the algorithm. The experiments do not enumerate all valid adjustment sets from the true DAG, because this is not feasible once the number of covariates grows.

The estimand is a contrast:

```text
E[Y | do(X = x1)] - E[Y | do(X = x0)]
```

where `x0` and `x1` are usually chosen as fixed quantiles of the treatment distribution, for example the 25th and 75th percentiles.

Important: the same `x0` and `x1` should be used for:

- the true interventional causal effect,
- LSAS estimated effect,
- EA-PC estimated effect,
- EHS estimated effect,
- oracle-adjustment g-formula baseline.

---

## 8. True Causal Effect in Synthetic Experiments

The true causal effect should be estimated by intervention using the known synthetic SCM:

```text
CE_true = E[Y | do(X = x1)] - E[Y | do(X = x0)]
```

This should remain the ground truth.

I do not want to replace this with a g-formula estimate.

However, I may add an oracle-adjustment g-formula baseline for debugging:

```text
CE_oracle_gformula = g-formula estimate using a known valid adjustment set
```

This helps distinguish between two possible problems:

1. the causal discovery algorithm selected a bad adjustment set;
2. the g-formula estimator itself is biased or unstable.

Diagnostic logic:

```text
If oracle-gformula RE gets worse with n:
    the problem may be the estimator, true-effect contrast, or data generation.

If oracle-gformula RE improves with n:
    the estimator is probably okay, and the problem is likely adjustment-set selection or decision logic.
```

---

## 9. Evaluation Metrics

The main metrics are:

### 9.1 Decision Metrics

- decision accuracy for `+`, `0`, and `?`,
- decisive rate: proportion of runs where output is not `?`,
- positive decision rate,
- zero-effect decision rate,
- unknown decision rate.

### 9.2 Effect Estimation Metrics

Relative error:

```text
RE = |(CE_hat - CE_true) / CE_true|
```

This should be computed only when:

- the algorithm returns `+` or '0',
- a valid effect estimate is produced.

Use caution because mean RE can be affected by which runs are decisive at each sample size.
