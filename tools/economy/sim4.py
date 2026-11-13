"""Economy simulation v4 (cage-break plan, 2026-11-11): sim3 plus a luck-driven income roll, 11 trails and a 20-pickaxe ladder.
Run: python sim4.py  (prints the baseline check, the luck effect and the tuned ladders)."""
import math, random, sys
import sim3

TIER_INC = [1, 9.3, 82, 730, 6500, 57700]
OLD_POWER = [1, 4, 14, 51, 187, 693, 2565, 9493, 35124, 129959, 480848, 1779000, 6583000, 24357000, 90121000]
OLD_PCOST = [0, 361, 1690, 7880, 36800, 172000, 803000, 3750000, 17500000, 81800000, 382000000, 1780000000, 8330000000, 38900000000, 182000000000]
TREAD_COST = [0, 24, 56, 133, 313, 737, 1740, 4090, 9630, 22700, 53400, 126000, 296000, 697000, 1640000]
OLD_TRAILS = [(0, 1), (250, 1.05), (5000, 1.10), (100000, 1.15)]

sim3.speed = lambda p: min(200, 16 * (1 + p / 60) ** 0.257)
P0 = dict(sim3.A); P0['gain'] = 5.0

# --- luck and the income roll -------------------------------------------------------------------------------------------
# Each break rolls a luck value L (the counter on screen). Normal cage: 1 + 0.5 r^2 (1.0-1.5). Lucky cage: 3 + r (3.0-4.0).
# The income roll is u = random()^(1/L) in [0,1] (L=1 uniform, higher L pushes toward 1); income factor = Min + (Max-Min) u.
def luck(rnd, lucky): return (3 + rnd.random()) if lucky else 1 + 0.5 * rnd.random() ** 2
def mean_u(trials=200000, seed=3):
    rnd = random.Random(seed); return sum(rnd.random() ** (1 / luck(rnd, False)) for _ in range(trials)) / trials
SPREAD = 0.8
MEAN_U = mean_u()
RMIN = 1 - SPREAD * MEAN_U            # so a normal-luck roll averages exactly 1.0 x base income
RMAX = RMIN + SPREAD

def install_income_roll(enabled=True):
    base_roll = sim3.roll_mult.__wrapped__ if hasattr(sim3.roll_mult, '__wrapped__') else sim3.roll_mult
    def roll(P, rnd, lucky, sz_odds, tier=0):
        m = base_roll(P, rnd, lucky, sz_odds, tier)
        if enabled:
            L = luck(rnd, lucky)
            m *= RMIN + (RMAX - RMIN) * rnd.random() ** (1 / L)
        return m
    roll.__wrapped__ = base_roll
    sim3.roll_mult = roll

# --- the shipped reward roll (Config.Luck + Shared/RewardMath, 2026-11-13) ---------------------------------------------------
# L is rolled as above (rounded to Step) plus the Cage luck upgrade, clamped at LuckyMax. L weights the size and variant tables
# (weight * L^(index*LuckExponent)) and the per-tier income roll; the card's multiplier is RewardMath.Multiplier (soft cap above 6x).
SIZES = [(.8, 8), (.9, 17), (1, 60), (1.12, 8), (1.28, 4), (1.5, 1.6), (1.8, .8), (2.2, .4), (2.7, .15), (3.3, .05)]
VARIANTS = [(1, 89), (1.5, 6), (2, 2), (2.4, .9), (2.8, .65), (3.2, .5), (3.8, .35), (4.5, .25), (5.5, .2), (7, .15)]
INCOME_RANGE = [(.79, 1.19), (.73, 1.23), (.68, 1.28), (.62, 1.32), (.57, 1.37), (.46, 1.46)]   # Common..GOAT
LUCK_EXPONENT, SOFT_START, ABS_MAX, LUCKY_MAX = .2, 6, 20, 4

def pick(rnd, table, L):
    weights = [w * L ** (i * LUCK_EXPONENT) for i, (_, w) in enumerate(table)]
    r = rnd.random() * sum(weights)
    for (value, _), w in zip(table, weights):
        r -= w
        if r <= 0: return value
    return table[-1][0]

def reward_multiplier(rnd, tier, lucky, luck_bonus=0.0):
    L = (3 + rnd.random()) if lucky else 1 + 0.5 * rnd.random() ** 2
    L = min(LUCKY_MAX, round(L, 1) + luck_bonus)
    lo, hi = INCOME_RANGE[tier]
    raw = pick(rnd, SIZES, L) * pick(rnd, VARIANTS, L) * (lo + (hi - lo) * rnd.random() ** (1 / L))
    return min(ABS_MAX, raw if raw <= SOFT_START else SOFT_START + math.sqrt(raw - SOFT_START))

def install_reward_roll(luck_bonus=0.0):
    sim3.roll_mult = lambda P, rnd, lucky, sz_odds, tier=0: reward_multiplier(rnd, tier, lucky, luck_bonus)

def vals(power, pcost, tcost=TREAD_COST):
    return dict(tier_income=TIER_INC, pick_power=power, pick_cost=pcost, tread_cost=tcost)

def stage12(P, v, seeds, **kw):
    reach, stats = sim3.mean_run(P, v, seeds, **kw)
    return reach, stats

def fmt(reach): return " ".join(f"S{s}:{sim3.hm(reach[s])}" for s in (1, 3, 5, 8, 10, 12))

if __name__ == '__main__':
    seeds = range(1, 13)
    install_income_roll(False)
    P = dict(P0); P['trails'] = OLD_TRAILS
    r0, _ = stage12(P, vals(OLD_POWER, OLD_PCOST), seeds)
    print("baseline (current Config)         ", fmt(r0))
    install_income_roll(True)
    r1, _ = stage12(P, vals(OLD_POWER, OLD_PCOST), seeds)
    print(f"income roll+luck (Min {RMIN:.3f} Max {RMAX:.3f}, mean u {MEAN_U:.3f})", fmt(r1))
