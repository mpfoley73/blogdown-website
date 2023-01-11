library(tidyverse)
library(broom)
library(nlme) 

# n = 200 subjects * 3 time observations = 600 rows
n <- 200
group_fct <- factor(c(0, 1), labels = c("control", "treatment"))
dat_0 <- expand.grid(id = 1:n, time = 0:2) %>%
  mutate(group = if_else(id <= n / 2, group_fct[1], group_fct[2])) %>%
  arrange(id, time)

# Quality of Life (QoL) dependent variable.
beta <- c(50, -3.5, -7.0, 0, 2.5, 5)
dat_1 <- dat_0 %>% mutate(E_y = beta[1] + 
                            beta[2] * (time == 1) + 
                            beta[3] * (time == 2) + 
                            beta[4] * (group == "treatment") * (time == 0) +
                            beta[5] * (group == "treatment") * (time == 1) +
                            beta[6] * (group == "treatment") * (time == 2))

# Append 100 copies of the base data set into a single data frame.
sims <- 100
dat_2 <- dat_1 %>% mutate(sim = 1)
for(i in 2:sims) {dat_2 <- bind_rows(dat_2, dat_1 %>% mutate(sim = i))}

# Add perturbations.
set.seed(123)
# b = between-person effect. One row per person
b <- expand.grid(sim = 1:sims, id = 1:n) %>% 
  bind_cols(b = rnorm(sims * n, 0, sqrt(60)))
# e = within-person effect. One row per person and time point
e <- expand.grid(sim = 1:sims, id = 1:n, time = 0:2) %>% 
  bind_cols(e = rnorm(sims * n * 3, 0, sqrt(40)))
dat_3 <- dat_2 %>%
  inner_join(b, by = c("sim", "id")) %>%
  inner_join(e, by = c("sim", "id", "time")) %>%
  mutate(y = E_y + b + e) %>%
  select(sim, id, time, group, E_y, y)

# Nest the data sets, one row per simulation.
dat_4 <- dat_3 %>% 
  nest(data = -sim) %>%
  mutate(
    # Calculate Mean y at each time.
    data = map(data, ~ {group_by(., time) %>% mutate(My = mean(y)) %>% ungroup()}),
    # Group by participant and sort (helpful for sim calcs).
    data = map(data, ~ {group_by(., id) %>% arrange(id, time)})
  )

# For each sim, make a MCAR data set.
make_mcar <- function(dat) {
  dat %>%
    bind_cols(p = runif(nrow(.))) %>%
    mutate(
      eq_same = if_else(p >= sqrt(.7)^time, TRUE, FALSE, missing = FALSE),
      eq_diff = if_else((p >= sqrt(.4)^time & group == "control" & lag(y) < lag(My)) |
                          (p >= sqrt(.4)^time & group == "treatment" & lag(y) > lag(My)), 
                        TRUE, FALSE, missing = FALSE),
      ne_same = if_else((p >= sqrt(.6)^time & group == "control") |
                          (p >= sqrt(.8)^time & group == "treatment"), 
                        TRUE, FALSE, missing = FALSE),
      ne_diff = if_else((p >= sqrt(.3)^time & group == "control" & lag(y) < lag(My)) |
                          (p >= sqrt(.6)^time & group == "treatment" & lag(y) > lag(My)), 
                        TRUE, FALSE, missing = FALSE)
    )
}
mcar <- dat_4 %>% mutate(data = map(data, make_mcar))

# For each sim, make a MAR data set.
My_g <- dat_3 %>% group_by(group, time) %>% summarize(.groups = "drop", M = mean(y))
SD <- sd(dat_3$y)
make_mar <- function(dat) {
  dat %>%
    inner_join(My_g, by = c("group", "time")) %>%
    mutate(
      y_l1 = lag(y),
      M_l1 = lag(M),
      base_eq = coalesce(pnorm(y_l1, M_l1, SD, lower.tail = FALSE), 0),
      base_ne = coalesce(pnorm(y_l1, M_l1, SD, lower.tail = TRUE), 0),
      p_eq_same = .325 * base_eq,
      p_eq_diff = if_else(group == "control", .325 * base_eq, .325 * base_ne),
      p_ne_same = if_else(group == "control", .450 * base_eq, .210 * base_eq),
      p_ne_diff = if_else(group == "control", .450 * base_eq, .210 * base_ne),
      eq_same = map_lgl(p_eq_same, ~rbinom(1, 1, .) == 1),
      eq_diff = map_lgl(p_eq_diff, ~rbinom(1, 1, .) == 1),
      ne_same = map_lgl(p_ne_same, ~rbinom(1, 1, .) == 1),
      ne_diff = map_lgl(p_ne_diff, ~rbinom(1, 1, .) == 1),
      eq_same = if_else(lag(eq_same) == TRUE, TRUE, eq_same, missing = FALSE),
      eq_diff = if_else(lag(eq_diff) == TRUE, TRUE, eq_diff, missing = FALSE),
      ne_same = if_else(lag(ne_same) == TRUE, TRUE, ne_same, missing = FALSE),
      ne_diff = if_else(lag(ne_diff) == TRUE, TRUE, ne_diff, missing = FALSE),
    )
}
mar <- dat_4 %>% mutate(data = map(data, make_mar))

# For each sim, make a MNAR data set.
make_mnar <- function(dat) {
  dat %>%
    inner_join(My_g, by = c("group", "time")) %>%
    mutate(
      base_eq = coalesce(pnorm(y, M, SD, lower.tail = FALSE), 0),
      base_ne = coalesce(pnorm(y, M, SD, lower.tail = TRUE), 0),
      p_eq_same = .325 * base_eq,
      p_eq_diff = if_else(group == "control", .325 * base_eq, .325 * base_ne),
      p_ne_same = if_else(group == "control", .450 * base_eq, .210 * base_eq),
      p_ne_diff = if_else(group == "control", .450 * base_eq, .210 * base_ne),
      eq_same = map_lgl(p_eq_same, ~rbinom(1, 1, .) == 1),
      eq_diff = map_lgl(p_eq_diff, ~rbinom(1, 1, .) == 1),
      ne_same = map_lgl(p_ne_same, ~rbinom(1, 1, .) == 1),
      ne_diff = map_lgl(p_ne_diff, ~rbinom(1, 1, .) == 1),
      eq_same = if_else(lag(eq_same) == TRUE, TRUE, eq_same, missing = FALSE),
      eq_diff = if_else(lag(eq_diff) == TRUE, TRUE, eq_diff, missing = FALSE),
      ne_same = if_else(lag(ne_same) == TRUE, TRUE, ne_same, missing = FALSE),
      ne_diff = if_else(lag(ne_diff) == TRUE, TRUE, ne_diff, missing = FALSE),
    )
}
mnar <- dat_4 %>% mutate(data = map(data, make_mnar))

# Add the missingness by setting the response var to NULL
make_miss <- function(dat, analysis) {
  dat %>%
    mutate(
      y_comp_case = if_else(!!ensym(analysis), NA_real_, y),
      y_comp_case = if_else(time == 2 & is.na(lag(y_comp_case)), NA_real_, y_comp_case),
      y_mean = mean(y_comp_case, na.rm = TRUE),
      y_mean_imp = coalesce(y_comp_case, y_mean),
      y_locf = coalesce(y_comp_case, lag(y_comp_case)),
      y_locf = coalesce(y_locf, lag(y_locf))
      # d_y = y - case_when(
      #   time == 2 ~ lag(y, 2), time == 1 ~ lag(y, 1), TRUE ~ y),
      # d_y_comp_case = y_comp_case - case_when(
      #   time == 2 ~ lag(y_comp_case, 2), time == 1 ~ lag(y_comp_case, 1), TRUE ~ y_comp_case),
      # d_y_mean_imp = y_mean_imp - case_when(
      #   time == 2 ~ lag(y_mean_imp, 2), time == 1 ~ lag(y_mean_imp, 1), TRUE ~ y_mean_imp),
      # d_y_locf = y_locf - case_when(
      #   time == 2 ~ lag(y_locf, 2), time == 1 ~ lag(y_locf, 1), TRUE ~ y_locf)
    ) %>%
    ungroup() %>%
    select(-y_mean) %>%
    rename(dropout = !!ensym(analysis))
}

mcar_eq_same <- mcar %>% mutate(data = map(data, ~make_miss(., "eq_same")))
mcar_eq_diff <- mcar %>% mutate(data = map(data, ~make_miss(., "eq_diff")))
mcar_ne_same <- mcar %>% mutate(data = map(data, ~make_miss(., "ne_same")))
mcar_ne_diff <- mcar %>% mutate(data = map(data, ~make_miss(., "ne_diff")))

mar_eq_same <- mar %>% mutate(data = map(data, ~make_miss(., "eq_same")))
mar_eq_diff <- mar %>% mutate(data = map(data, ~make_miss(., "eq_diff")))
mar_ne_same <- mar %>% mutate(data = map(data, ~make_miss(., "ne_same")))
mar_ne_diff <- mar %>% mutate(data = map(data, ~make_miss(., "ne_diff")))

mnar_eq_same <- mnar %>% mutate(data = map(data, ~make_miss(., "eq_same")))
mnar_eq_diff <- mnar %>% mutate(data = map(data, ~make_miss(., "eq_diff")))
mnar_ne_same <- mnar %>% mutate(data = map(data, ~make_miss(., "ne_same")))
mnar_ne_diff <- mnar %>% mutate(data = map(data, ~make_miss(., "ne_diff")))

# Fit the models
base_fmla <- formula(. ~ group * time)

fit_model <- function(dat, fmla) {
  dat %>%
    mutate(
      mdl = map(data, ~ lm(fmla, na.action = na.exclude, data = .)),
      aug = map2(mdl, data, ~augment(.x, newdata = .y))
    ) %>%
    unnest(aug) %>%
    select(-c(mdl, data))
}

fit_mixed <- function(dat, fmla) {
  dat %>%
    mutate(
      mdl = map(data, ~ gls(fmla, na.action = na.exclude, data = .,
                            correlation = corSymm(form=~1|id),
                            weights = varIdent(form = ~1|time),
                            method = "REML")),
      aug = map2(mdl, data, ~bind_cols(.y, .fitted = predict(.x)))
    ) %>%
    unnest(aug) %>%
    select(-c(mdl, data))
}

dat_5 <- tribble(
  ~missingness, ~analysis, ~rate, ~direction, ~bias,
  "mcar", "Complete case", "Equal", "Same", fit_model(mcar_eq_same, update(base_fmla, y_comp_case ~ .)),
  "mcar", "Complete case", "Equal", "Diff", fit_model(mcar_eq_diff, update(base_fmla, y_comp_case ~ .)),
  "mcar", "Complete case", "Unequal", "Same", fit_model(mcar_ne_same, update(base_fmla, y_comp_case ~ .)),
  "mcar", "Complete case", "Unequal", "Diff", fit_model(mcar_ne_diff, update(base_fmla, y_comp_case ~ .)),
  "mcar", "Mean imputation", "Equal", "Same", fit_model(mcar_eq_same, update(base_fmla, y_mean_imp ~ .)),
  "mcar", "Mean imputation", "Equal", "Diff", fit_model(mcar_eq_diff, update(base_fmla, y_mean_imp ~ .)),
  "mcar", "Mean imputation", "Unequal", "Same", fit_model(mcar_ne_same, update(base_fmla, y_mean_imp ~ .)),
  "mcar", "Mean imputation", "Unequal", "Diff", fit_model(mcar_ne_diff, update(base_fmla, y_mean_imp ~ .)),
  "mcar", "LOCF", "Equal", "Same", fit_model(mcar_eq_same, update(base_fmla, y_locf ~ .)),
  "mcar", "LOCF", "Equal", "Diff", fit_model(mcar_eq_diff, update(base_fmla, y_locf ~ .)),
  "mcar", "LOCF", "Unequal", "Same", fit_model(mcar_ne_same, update(base_fmla, y_locf ~ .)),
  "mcar", "LOCF", "Unequal", "Diff", fit_model(mcar_ne_diff, update(base_fmla, y_locf ~ .)),
  "mcar", "Mixed", "Equal", "Same", fit_mixed(mcar_eq_same, update(base_fmla, y ~ .)),
  "mcar", "Mixed", "Equal", "Diff", fit_mixed(mcar_eq_diff, update(base_fmla, y ~ .)),
  "mcar", "Mixed", "Unequal", "Same", fit_mixed(mcar_ne_same, update(base_fmla, y ~ .)),
  "mcar", "Mixed", "Unequal", "Diff", fit_mixed(mcar_ne_diff, update(base_fmla, y ~ .)),
  "mar", "Complete case", "Equal", "Same", fit_model(mar_eq_same, update(base_fmla, y_comp_case ~ .)),
  "mar", "Complete case", "Equal", "Diff", fit_model(mar_eq_diff, update(base_fmla, y_comp_case ~ .)),
  "mar", "Complete case", "Unequal", "Same", fit_model(mar_ne_same, update(base_fmla, y_comp_case ~ .)),
  "mar", "Complete case", "Unequal", "Diff", fit_model(mar_ne_diff, update(base_fmla, y_comp_case ~ .)),
  "mar", "Mean imputation", "Equal", "Same", fit_model(mar_eq_same, update(base_fmla, y_mean_imp ~ .)),
  "mar", "Mean imputation", "Equal", "Diff", fit_model(mar_eq_diff, update(base_fmla, y_mean_imp ~ .)),
  "mar", "Mean imputation", "Unequal", "Same", fit_model(mar_ne_same, update(base_fmla, y_mean_imp ~ .)),
  "mar", "Mean imputation", "Unequal", "Diff", fit_model(mar_ne_diff, update(base_fmla, y_mean_imp ~ .)),
  "mar", "LOCF", "Equal", "Same", fit_model(mar_eq_same, update(base_fmla, y_locf ~ .)),
  "mar", "LOCF", "Equal", "Diff", fit_model(mar_eq_diff, update(base_fmla, y_locf ~ .)),
  "mar", "LOCF", "Unequal", "Same", fit_model(mar_ne_same, update(base_fmla, y_locf ~ .)),
  "mar", "LOCF", "Unequal", "Diff", fit_model(mar_ne_diff, update(base_fmla, y_locf ~ .)),
  "mar", "Mixed", "Equal", "Same", fit_mixed(mar_eq_same, update(base_fmla, y ~ .)),
  "mar", "Mixed", "Equal", "Diff", fit_mixed(mar_eq_diff, update(base_fmla, y ~ .)),
  "mar", "Mixed", "Unequal", "Same", fit_mixed(mar_ne_same, update(base_fmla, y ~ .)),
  "mar", "Mixed", "Unequal", "Diff", fit_mixed(mar_ne_diff, update(base_fmla, y ~ .)),
  "mnar", "Complete case", "Equal", "Same", fit_model(mnar_eq_same, update(base_fmla, y_comp_case ~ .)),
  "mnar", "Complete case", "Equal", "Diff", fit_model(mnar_eq_diff, update(base_fmla, y_comp_case ~ .)),
  "mnar", "Complete case", "Unequal", "Same", fit_model(mnar_ne_same, update(base_fmla, y_comp_case ~ .)),
  "mnar", "Complete case", "Unequal", "Diff", fit_model(mnar_ne_diff, update(base_fmla, y_comp_case ~ .)),
  "mnar", "Mean imputation", "Equal", "Same", fit_model(mnar_eq_same, update(base_fmla, y_mean_imp ~ .)),
  "mnar", "Mean imputation", "Equal", "Diff", fit_model(mnar_eq_diff, update(base_fmla, y_mean_imp ~ .)),
  "mnar", "Mean imputation", "Unequal", "Same", fit_model(mnar_ne_same, update(base_fmla, y_mean_imp ~ .)),
  "mnar", "Mean imputation", "Unequal", "Diff", fit_model(mnar_ne_diff, update(base_fmla, y_mean_imp ~ .)),
  "mnar", "LOCF", "Equal", "Same", fit_model(mnar_eq_same, update(base_fmla, y_locf ~ .)),
  "mnar", "LOCF", "Equal", "Diff", fit_model(mnar_eq_diff, update(base_fmla, y_locf ~ .)),
  "mnar", "LOCF", "Unequal", "Same", fit_model(mnar_ne_same, update(base_fmla, y_locf ~ .)),
  "mnar", "LOCF", "Unequal", "Diff", fit_model(mnar_ne_diff, update(base_fmla, y_locf ~ .)),
  "mnar", "Mixed", "Equal", "Same", fit_mixed(mnar_eq_same, update(base_fmla, y ~ .)),
  "mnar", "Mixed", "Equal", "Diff", fit_mixed(mnar_eq_diff, update(base_fmla, y ~ .)),
  "mnar", "Mixed", "Unequal", "Same", fit_mixed(mnar_ne_same, update(base_fmla, y ~ .)),
  "mnar", "Mixed", "Unequal", "Diff", fit_mixed(mnar_ne_diff, update(base_fmla, y ~ .))
) %>%
  unnest(bias)

example_dispersion <- bind_rows(
  MCAR = mcar_eq_diff %>% unnest(data) %>% filter(id %in% c(1, 101)),
  MAR = mar_eq_diff %>% unnest(data) %>% filter(id %in% c(1, 101)),
  MNAR = mnar_eq_diff %>% unnest(data) %>% filter(id %in% c(1, 101)),
  .id = "Pattern"
)

sim_summary <- dat_5 %>% 
  filter(time == 2) %>%
  group_by(missingness, analysis, rate, direction) %>%
  summarize(.groups = "drop", M_bias = (mean(.fitted) - mean(y)) / mean(y) * 100) %>%
  pivot_wider(names_from = c(rate, direction), values_from = M_bias) %>%
  mutate(
    missingness = factor(missingness, levels = c("mcar", "mar", "mnar"), labels = c("MCAR", "MAR", "MNAR")),
    analysis = factor(analysis, levels = c("Complete case", "Mean imputation", "LOCF", "Mixed"))
  ) %>%
  arrange(missingness, analysis) %>%
  select(analysis, Equal_Same, Unequal_Same, Equal_Diff, Unequal_Diff)

save(
  dat_1, dat_3, example_dispersion, sim_summary,
  file = file.path("./content/post/2022-12-09-differential-dropout-bias", "analysis.RData")
)
