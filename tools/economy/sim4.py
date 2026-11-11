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
    def roll(P, rnd, lucky, sz_odds):
        m = base_roll(P, rnd, lucky, sz_odds)
        if enabled:
            L = luck(rnd, lucky)
            m *= RMIN + (RMAX - RMIN) * rnd.random() ** (1 / L)
        return m
    roll.__wrapped__ = base_roll
    sim3.roll_mult = roll

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
