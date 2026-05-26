/* ============================================================================
 * III-OBSERVABILITY — thresholds.c
 *
 * The 12 sufficiency-gate families.  Each family ships:
 *   1. A constructor that sets up the threshold parameters.
 *   2. An accumulator update routine appropriate for its observable.
 *   3. A saturation predicate that returns true once the gate's condition
 *      is met.
 *
 * Every family is hand-rolled from the relevant statistical literature and
 * is closure-pinned (Tier-3 amendment to modify).  Implementations are
 * conservative, constant-time where applicable, and use only standard math.
 *
 *   Hoeffding 1963        — half-width = sqrt(ln(2/(1-conf))/(2n))
 *   Wilson 1927           — binomial CI half-width
 *   Poisson               — sqrt(n)/λ ≤ ε
 *   Coupon collector      — n ≥ k ln(k / (1 - conf))
 *   CMSketch              — width × depth fill (Cormode-Muthukrishnan 2005)
 *   OrderStat             — quantile half-width
 *   Nyquist               — sample_rate ≥ 2 × signal_band
 *   ESS                   — (Σw)² / Σ(w²) ≥ target
 *   Heaps                 — V = K · N^β fit converged
 *   RuleOfThree           — n ≥ -ln(1-conf)/3
 *   Multinomial           — every category ≥ n_min/k
 *   Multinomial-Dirichlet — Dirichlet posterior credible interval ≤ ε
 * ============================================================================
 */
#include "iii/observability.h"
#include <math.h>
#include <string.h>
#include <stdlib.h>

/* Q14 helpers */
iii_q14_t iii_q14_mul(iii_q14_t a, iii_q14_t b) {
    return (iii_q14_t)(((uint64_t)a * b) >> 14);
}
iii_q14_t iii_q14_div(iii_q14_t a, iii_q14_t b) {
    if (b == 0) return 0;
    return (iii_q14_t)(((uint64_t)a << 14) / b);
}
double iii_q14_to_double(iii_q14_t x) { return (double)x / (double)III_Q14_ONE; }
iii_q14_t iii_q14_from_double(double x) {
    if (x < 0) return 0;
    if (x > 4.0) return III_Q14_ONE * 4u;
    return (iii_q14_t)(x * (double)III_Q14_ONE + 0.5);
}

const char *iii_threshold_family_name(iii_threshold_family_t f) {
    switch (f) {
        case III_TF_NONE:                  return "none";
        case III_TF_HOEFFDING:             return "hoeffding";
        case III_TF_MULTINOMIAL:           return "multinomial";
        case III_TF_WILSON:                return "wilson";
        case III_TF_POISSON:               return "poisson";
        case III_TF_COUPON:                return "coupon-collector";
        case III_TF_CMSKETCH:              return "cm-sketch";
        case III_TF_ORDER_STAT:            return "order-stat";
        case III_TF_NYQUIST:               return "nyquist";
        case III_TF_EFFECTIVE_SAMPLE_SIZE: return "effective-sample-size";
        case III_TF_HEAPS:                 return "heaps";
        case III_TF_RULE_OF_THREE:         return "rule-of-three";
        case III_TF_MULTINOMIAL_DIRICHLET: return "multinomial-dirichlet";
        default:                           return "unknown";
    }
}

/* ----------------------------------------------------------------------------
 * Constructors.  Default epsilon = 0.05 unless overridden by the family's
 * intrinsic tolerance.
 * ---------------------------------------------------------------------------- */

iii_threshold_t iii_th_hoeffding(double confidence, uint32_t n_min) {
    iii_threshold_t t = {0};
    t.family = III_TF_HOEFFDING;
    t.confidence = confidence;
    t.n_min      = n_min;
    t.epsilon    = 0.05;
    return t;
}

iii_threshold_t iii_th_multinomial(double confidence, uint32_t n_min, uint32_t k) {
    iii_threshold_t t = {0};
    t.family = III_TF_MULTINOMIAL;
    t.confidence = confidence;
    t.n_min      = n_min;
    t.k_categories = k;
    t.epsilon    = 0.05;
    return t;
}

iii_threshold_t iii_th_wilson(double confidence, uint32_t n_min) {
    iii_threshold_t t = {0};
    t.family = III_TF_WILSON;
    t.confidence = confidence;
    t.n_min      = n_min;
    t.epsilon    = 0.05;
    return t;
}

iii_threshold_t iii_th_poisson(double confidence, uint32_t n_min) {
    iii_threshold_t t = {0};
    t.family = III_TF_POISSON;
    t.confidence = confidence;
    t.n_min      = n_min;
    t.epsilon    = 0.05;
    return t;
}

iii_threshold_t iii_th_coupon_collector(uint32_t k, double confidence) {
    iii_threshold_t t = {0};
    t.family = III_TF_COUPON;
    t.coupon_k   = k;
    t.confidence = confidence;
    return t;
}

iii_threshold_t iii_th_cmsketch(uint32_t width, uint32_t depth, double confidence) {
    iii_threshold_t t = {0};
    t.family = III_TF_CMSKETCH;
    t.cm_width  = width;
    t.cm_depth  = depth;
    t.confidence = confidence;
    t.epsilon    = 0.01;
    return t;
}

iii_threshold_t iii_th_order_stat(double quantile, double confidence, uint32_t n_min) {
    iii_threshold_t t = {0};
    t.family = III_TF_ORDER_STAT;
    t.quantile  = quantile;
    t.confidence = confidence;
    t.n_min      = n_min;
    t.epsilon    = 0.05;
    return t;
}

iii_threshold_t iii_th_nyquist(double sample_rate, double signal_band) {
    iii_threshold_t t = {0};
    t.family = III_TF_NYQUIST;
    t.sample_rate = sample_rate;
    t.signal_band = signal_band;
    return t;
}

iii_threshold_t iii_th_effective_sample_size(uint32_t target) {
    iii_threshold_t t = {0};
    t.family = III_TF_EFFECTIVE_SAMPLE_SIZE;
    t.ess_target = target;
    return t;
}

iii_threshold_t iii_th_heaps(double alpha, double beta, uint32_t n_min) {
    iii_threshold_t t = {0};
    t.family = III_TF_HEAPS;
    t.heaps_alpha = alpha;
    t.heaps_beta  = beta;
    t.n_min       = n_min;
    return t;
}

iii_threshold_t iii_th_rule_of_three(double confidence) {
    iii_threshold_t t = {0};
    t.family = III_TF_RULE_OF_THREE;
    t.confidence = confidence;
    return t;
}

iii_threshold_t iii_th_multinomial_dirichlet(double prior, double confidence) {
    iii_threshold_t t = {0};
    t.family = III_TF_MULTINOMIAL_DIRICHLET;
    t.dirichlet_prior = prior;
    t.confidence = confidence;
    t.epsilon    = 0.05;
    return t;
}

/* ----------------------------------------------------------------------------
 * Accumulator
 * ---------------------------------------------------------------------------- */

void iii_accumulator_init(iii_accumulator_t *a, iii_threshold_family_t f) {
    if (!a) return;
    memset(a, 0, sizeof(*a));
    a->family = f;
}

void iii_accumulator_update_scalar(iii_accumulator_t *a, double sample) {
    if (!a) return;
    a->n++;
    a->sum    += sample;
    a->sum_sq += sample * sample;
    /* Order-stat — keep up to 256 samples (uniform reservoir overrides
     * could be added; for now we keep the first N). */
    if (a->family == III_TF_ORDER_STAT && a->sample_count < 256) {
        a->samples[a->sample_count++] = sample;
    }
}

void iii_accumulator_update_int(iii_accumulator_t *a, uint64_t value) {
    iii_accumulator_update_scalar(a, (double)value);
}

void iii_accumulator_update_category(iii_accumulator_t *a, uint32_t cat) {
    if (!a || cat >= 16) return;
    a->n++;
    a->counts[cat]++;
}

void iii_accumulator_update_weight(iii_accumulator_t *a, double weight) {
    if (!a) return;
    a->n++;
    a->ess_sum_w   += weight;
    a->ess_sum_wsq += weight * weight;
}

void iii_accumulator_update_event(iii_accumulator_t *a) {
    if (!a) return;
    a->n++;
}

/* ----------------------------------------------------------------------------
 * Saturation predicates per family
 * ---------------------------------------------------------------------------- */

static bool sat_hoeffding(const iii_threshold_t *t, const iii_accumulator_t *a) {
    if (a->n < t->n_min) return false;
    double half_width = sqrt(log(2.0 / (1.0 - t->confidence)) / (2.0 * (double)a->n));
    return half_width <= t->epsilon;
}

static bool sat_multinomial(const iii_threshold_t *t, const iii_accumulator_t *a) {
    if (t->k_categories == 0 || t->k_categories > 16) return false;
    uint64_t per_cat = (uint64_t)t->n_min / t->k_categories;
    for (unsigned i = 0; i < t->k_categories; ++i) {
        if (a->counts[i] < per_cat) return false;
    }
    return true;
}

static bool sat_wilson(const iii_threshold_t *t, const iii_accumulator_t *a) {
    if (a->n < t->n_min || a->n == 0) return false;
    double p = a->sum / (double)a->n;          /* sum encodes # successes */
    double n = (double)a->n;
    /* z for confidence 0.95 ≈ 1.96.  Generic: z = sqrt(2 ln(1/(1-c))) is
     * an approximation; for our gate purposes use 1.96 if conf ≥ 0.95
     * else compute via inverse normal approximation. */
    double z = 1.96;
    if (t->confidence < 0.95) z = sqrt(2.0 * log(1.0 / (1.0 - t->confidence)));
    if (t->confidence > 0.99) z = 2.576;
    double denom = 1.0 + (z*z) / n;
    double centre = (p + (z*z)/(2.0*n)) / denom;
    double half = (z * sqrt(p*(1-p)/n + (z*z)/(4.0*n*n))) / denom;
    (void)centre;
    return (2.0 * half) <= t->epsilon;
}

static bool sat_poisson(const iii_threshold_t *t, const iii_accumulator_t *a) {
    if (a->n < t->n_min) return false;
    /* lambda estimate = mean of observations; we use sum/n as λ. */
    double lambda = (a->n > 0) ? (a->sum / (double)a->n) : 0.0;
    if (lambda <= 0.0) lambda = 1.0;
    double rel_err = sqrt((double)a->n) / lambda;
    return rel_err <= t->epsilon;
}

static bool sat_coupon(const iii_threshold_t *t, const iii_accumulator_t *a) {
    if (t->coupon_k == 0) return false;
    /* Saturation: n ≥ k · log(k / (1 - conf)).  Approximation from Feller. */
    double k       = (double)t->coupon_k;
    double bound   = k * log(k / fmax(1e-9, 1.0 - t->confidence));
    return (double)a->n >= bound;
}

static bool sat_cmsketch(const iii_threshold_t *t, const iii_accumulator_t *a) {
    /* Saturation when ε-approximation guarantee holds: width ≥ e/ε and
     * depth ≥ ln(1/δ).  We treat the gate as saturated once enough samples
     * have flowed through to populate the sketch. */
    if (t->cm_width == 0 || t->cm_depth == 0) return false;
    double need = (double)t->cm_width * (double)t->cm_depth;
    return (double)a->n >= need;
}

static int double_cmp(const void *a, const void *b) {
    double x = *(const double *)a, y = *(const double *)b;
    if (x < y) return -1;
    if (x > y) return 1;
    return 0;
}

static bool sat_order_stat(const iii_threshold_t *t, const iii_accumulator_t *a) {
    if (a->sample_count < t->n_min) return false;
    /* Sort a copy and compute the half-width around the q-th order stat. */
    uint32_t n = a->sample_count;
    if (n < 4) return false;
    double cp[256];
    memcpy(cp, a->samples, n * sizeof(double));
    qsort(cp, n, sizeof(double), double_cmp);
    uint32_t idx_lo = (uint32_t)(t->quantile * n - sqrt((double)n) * 1.96 / 2.0);
    uint32_t idx_hi = (uint32_t)(t->quantile * n + sqrt((double)n) * 1.96 / 2.0);
    if (idx_lo >= n) idx_lo = 0;
    if (idx_hi >= n) idx_hi = n - 1;
    double range = cp[idx_hi] - cp[idx_lo];
    double full  = cp[n-1] - cp[0] + 1e-9;
    return (range / full) <= t->epsilon;
}

static bool sat_nyquist(const iii_threshold_t *t, const iii_accumulator_t *a) {
    (void)a;
    return t->sample_rate >= 2.0 * t->signal_band;
}

static bool sat_ess(const iii_threshold_t *t, const iii_accumulator_t *a) {
    if (a->ess_sum_wsq <= 0.0) return false;
    double ess = (a->ess_sum_w * a->ess_sum_w) / a->ess_sum_wsq;
    return ess >= (double)t->ess_target;
}

static bool sat_heaps(const iii_threshold_t *t, const iii_accumulator_t *a) {
    if (a->n < t->n_min) return false;
    /* Predicted V from Heaps' Law: V_pred = K · N^β. */
    double V_pred = t->heaps_alpha * pow((double)a->n, t->heaps_beta);
    double V_obs  = (double)a->heaps_distinct;
    if (V_pred <= 0.0) return false;
    /* Gate: |V_obs - V_pred|/V_pred ≤ 5%. */
    double rel = fabs(V_obs - V_pred) / V_pred;
    return rel <= 0.05;
}

static bool sat_rule_of_three(const iii_threshold_t *t, const iii_accumulator_t *a) {
    /* n ≥ -ln(1-conf)/3 — for zero-event observation. */
    double bound = -log(fmax(1e-9, 1.0 - t->confidence)) / 3.0;
    return (double)a->n >= bound;
}

static bool sat_multinomial_dirichlet(const iii_threshold_t *t, const iii_accumulator_t *a) {
    /* Dirichlet posterior credible interval ≤ ε: with prior α₀ per category
     * and observed counts c_i, the posterior variance for p_i is
     *   p_i (1 - p_i) / (n + αΣ)
     * where αΣ = k · prior. */
    uint32_t k = 8;  /* default categories used when not specified */
    if (t->k_categories) k = t->k_categories;
    double alpha_sum = (double)k * t->dirichlet_prior;
    double total = (double)a->n + alpha_sum;
    if (total <= 0) return false;
    /* Worst-case variance occurs at p = 0.5: var_max = 0.25/total. */
    double half_width = sqrt(0.25 / total);
    return half_width <= t->epsilon;
}

bool iii_threshold_is_saturated(const iii_threshold_t   *t,
                                const iii_accumulator_t *a)
{
    if (!t || !a) return false;
    switch (t->family) {
        case III_TF_HOEFFDING:             return sat_hoeffding(t, a);
        case III_TF_MULTINOMIAL:           return sat_multinomial(t, a);
        case III_TF_WILSON:                return sat_wilson(t, a);
        case III_TF_POISSON:               return sat_poisson(t, a);
        case III_TF_COUPON:                return sat_coupon(t, a);
        case III_TF_CMSKETCH:              return sat_cmsketch(t, a);
        case III_TF_ORDER_STAT:            return sat_order_stat(t, a);
        case III_TF_NYQUIST:               return sat_nyquist(t, a);
        case III_TF_EFFECTIVE_SAMPLE_SIZE: return sat_ess(t, a);
        case III_TF_HEAPS:                 return sat_heaps(t, a);
        case III_TF_RULE_OF_THREE:         return sat_rule_of_three(t, a);
        case III_TF_MULTINOMIAL_DIRICHLET: return sat_multinomial_dirichlet(t, a);
        default:                           return false;
    }
}

/* ----------------------------------------------------------------------------
 * Composition
 * ---------------------------------------------------------------------------- */

struct iii_threshold_composed {
    iii_threshold_t            a;
    iii_threshold_t            b;
    iii_threshold_combinator_t op;
    bool                       a_was_sat;     /* for UNTIL */
};

iii_threshold_composed_t *iii_th_compose(const iii_threshold_t *a,
                                         const iii_threshold_t *b,
                                         iii_threshold_combinator_t op)
{
    if (!a || !b) return NULL;
    iii_threshold_composed_t *c = (iii_threshold_composed_t *)calloc(1, sizeof(*c));
    if (!c) return NULL;
    c->a  = *a;
    c->b  = *b;
    c->op = op;
    return c;
}

bool iii_th_composed_is_saturated(const iii_threshold_composed_t *c,
                                  const iii_accumulator_t        *acc_a,
                                  const iii_accumulator_t        *acc_b)
{
    if (!c) return false;
    bool sa = iii_threshold_is_saturated(&c->a, acc_a);
    bool sb = iii_threshold_is_saturated(&c->b, acc_b);
    switch (c->op) {
        case III_TC_AND:   return sa && sb;
        case III_TC_OR:    return sa || sb;
        case III_TC_UNTIL: return sa && !sb;  /* "a saturated until b fires" */
        default:           return false;
    }
}

void iii_th_composed_destroy(iii_threshold_composed_t *c) {
    if (c) free(c);
}
