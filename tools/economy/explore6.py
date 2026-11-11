"""Retune (2026-11-11): the speed curve is a table of control points (Speed Points -> studs/s), interpolated linearly in log10(1+points).
The control points are the mean Speed Points at which a player arrives at each stage in the sim, paired with that stage's recommended
speed, so the 200 cap lands at Stage 11 and speed tracks Config.StageInfo. Trail prices set when each trail is bought."""
import math, statistics, sys
import sim4, sim3, explore4 as E
from explore5 import REC, MULTS, hm, human

def make_curve(xs):                       # xs[i] = log10(1+points) at which the speed is REC[i]; REC[0] at 0
    pts = list(zip(xs, REC[:11]))
    def f(p):
        x = math.log10(1 + p)
        if x <= pts[0][0]: return pts[0][1]
        for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
            if x <= x1: return y0 + (y1 - y0) * (x - x0) / (x1 - x0)
        return 200
    return f

def run_seeds(P, v, seeds):
    out = []
    for sd in seeds:
        smp = []
        r = sim3.run(P, v['tier_income'], v['pick_power'], v['pick_cost'], v['tread_cost'], seed=sd, sample=smp)
        out.append((r, dict(sim3.LAST['pts_at']), list(sim3.LAST['events']), smp, dict(sim3.LAST['speed'])))
    return out

def fit_curve(runs, prev):
    xs = [0.0]
    for s in range(2, 12):
        vals = [math.log10(1 + r[1][s]) for r in runs if s in r[1]]
        xs.append(max(xs[-1] + 0.05, statistics.mean(vals)))
    return xs

def evaluate(trails, seeds, iters=5):
    P = dict(sim4.P0); P['trails'] = trails; P['sample_every'] = 60
    v = sim4.vals(E.POWER, E.pcost(1.0))
    sim3.speed = lambda p: min(200, 16 * (1 + p / 60) ** 0.257)
    xs = None
    for it in range(iters):
        runs = run_seeds(P, v, seeds)
        xs = fit_curve(runs, xs)
        sim3.speed = make_curve(xs)
    runs = run_seeds(P, v, seeds)
    return xs, runs

def summarize(trails, runs):
    s12 = statistics.mean(r[0][12] for r in runs) / 60
    arr = {s: statistics.mean(r[4][s] for r in runs if s in r[4]) for s in range(1, 13)}
    at = {s: statistics.mean(r[0][s] for r in runs) / 60 for s in range(1, 13)}
    cap_t = statistics.mean(next((x[0] for x in r[3] if x[6] >= 199.5), 720) for r in runs)
    cap_stage = max(s for s in range(1, 13) if at[s] <= cap_t)
    rows = []
    for k in range(1, len(trails)):
        tb, before, after = [], [], []
        for r in runs:
            ev = next((x for x in r[2] if x[1] == k), None)
            if not ev: continue
            smp = r[3]
            i = next((i for i, x in enumerate(smp) if x[0] * 60 >= ev[0]), None)
            if i is None or i + 5 >= len(smp): continue
            tb.append(ev[0] / 60); before.append(smp[i][6]); after.append(smp[i + 5][6])
        rows.append((trails[k][1], trails[k][0], statistics.mean(tb), statistics.mean(before), statistics.mean(after)))
    return s12, arr, at, cap_t, cap_stage, rows

if __name__ == '__main__':
    sim4.install_income_roll(True)
    seeds = range(1, 7)
    for alpha in (1.0, 1.1, 1.2, 1.3):
        t0 = 2500 / 2 ** alpha
        trails = [(0, 1)] + [(t0 * m ** alpha, m) for m in MULTS]
        xs, runs = evaluate(trails, seeds)
        s12, arr, at, cap_t, cap_stage, rows = summarize(trails, runs)
        print(f"alpha {alpha}: S12 {hm(s12)} cap {hm(cap_t)} (stage {cap_stage}) T11 bought {hm(rows[-1][2])}")
        print("   arrival speeds", " ".join(f"{arr[s]:.0f}" for s in range(1, 13)), "| REC", " ".join(map(str, REC)))
        print("   T speed before->+5min:", " ".join(f"x{r[0]}:{r[3]:.0f}->{r[4]:.0f}" for r in rows), flush=True)
