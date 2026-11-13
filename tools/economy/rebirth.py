"""Rebirth simulation (2026-11-13). Run: python rebirth.py   (about 3-4 minutes)
Prints the first climb to Stage 12, the time between rebirths with the Config.Rebirth numbers and the 24 h cash with 0..N rebirths.
Model: after a rebirth the player keeps cash, cards, pickaxes, treadmill and trail; Speed Points restart at 0; a stage needs the speed
recommended for it (gate); rebirth n is ready when Speed Points reach BaseRequirement * Growth^(n-1). Multipliers are 1 + Step * rebirths.
Keep the constants below equal to Config.Rebirth. Needs final_values.json (written by final.py)."""
import json, math, statistics, sys
import sim3, sim4

BASE_REQ, GROWTH, INCOME_STEP, GAIN_STEP, MAX = 8e10, 1.25, 0.5, 0.5, 10
# Upgrades (Config.Upgrades) are kept through rebirths. `python rebirth.py upgrades` runs with every one maxed (an upper bound):
# Income +25% and Speed gain +50% multiply the rebirth multipliers, Cage luck +0.5 is added to every roll.
UPGRADES = 'upgrades' in sys.argv
INCOME_UP, GAIN_UP, LUCK_UP = (1.25, 1.5, 0.5) if UPGRADES else (1, 1, 0)
SEEDS = range(1, 4)
REC = [16, 26, 42, 58, 76, 93, 109, 131, 149, 178, 200, 200]   # Config.StageInfo recommended speeds

fv = json.load(open('final_values.json'))
curve = fv['curve']
def speed(p):
    if p <= 0: return 16
    x = math.log10(1 + p)
    for (p0, s0), (p1, s1) in zip(curve, curve[1:]):
        if p <= p1:
            a, b = math.log10(1 + p0), math.log10(1 + p1)
            return s0 + (s1 - s0) * (x - a) / (b - a)
    return 200
sim3.speed = speed
sim4.install_reward_roll(LUCK_UP)
P = dict(sim4.P0); P['trails'] = [tuple(t) for t in fv['trails']]; P['gate'] = REC
V = sim4.vals(fv['pick_power'], fv['pick_cost'])

def requirement(k): return BASE_REQ * GROWTH ** (k - 1)            # points for rebirth number k
def run(seed, state, count, minutes, stop_pts=None, stop12=False):
    sim3.run(P, V['tier_income'], V['pick_power'], V['pick_cost'], V['tread_cost'], seed=seed, minutes=minutes,
             income_mult=(1 + INCOME_STEP * count) * INCOME_UP, state=state, gain_mult=(1 + GAIN_STEP * count) * GAIN_UP, stop_pts=stop_pts, stop12=stop12)
    return sim3.LAST['state']

def policy(seed, max_rebirths, hours=24):
    """Rebirth as soon as ready, at most max_rebirths times, within `hours`. Returns (minutes per segment, cash earned)."""
    state, t, earned, k, seg = None, 0, 0, 0, []
    while True:
        stop = requirement(k + 1) if k < max_rebirths else None
        s = run(seed, state, k, (hours * 3600 - t) / 60, stop_pts=stop)
        earned += s['earned']
        if stop and t + s['t'] < hours * 3600:
            seg.append(s['t'] / 60); t += s['t']; state = s; k += 1
        else:
            return seg, earned

if __name__ == '__main__':
    firsts = [run(sd, None, 0, 900, stop12=True)['t'] for sd in SEEDS]
    print(f"First climb to Stage 12 (no rebirth): {sim3.hm(statistics.mean(firsts))}")
    print("\nrebirth | multiplier | needs points | minutes since the previous one (mean of seeds)")
    runs = {n: [policy(sd, n) for sd in SEEDS] for n in (0, 1, 2, 3, 5, 8)}
    longest = runs[8]
    for k in range(1, 9):
        mins = statistics.mean(r[0][k - 1] for r in longest)
        print(f"  {k:>2}    | x{1 + INCOME_STEP * k:<5.2f}     | {requirement(k):.2e} | {mins:6.0f}")
    print("\nmarginal income gain per rebirth:", ", ".join(f"#{k} +{INCOME_STEP / (1 + INCOME_STEP * (k - 1)) * 100:.0f}%" for k in (1, 2, 5, 8, 10, 20)))
    print("\nrebirths allowed | cash earned in 24 h | vs none")
    base = statistics.mean(r[1] for r in runs[0])
    for n, rs in runs.items():
        cash = statistics.mean(r[1] for r in rs)
        print(f"  {n:>2}             | {cash:.3g}            | x{cash / base:.2f}")
