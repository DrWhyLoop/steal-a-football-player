"""Plan step 1 (2026-11-11): retune the speed curve and trail prices so the 200 cap is reached around Stage 11 and every trail
still raises speed when bought. Fits speed(P)=min(200,16*(1+P/ps)^e) so that the speed on arrival at each stage matches Config.StageInfo."""
import math, statistics, sys
import sim4, sim3, explore4 as E
REC = [16, 26, 42, 58, 76, 93, 109, 131, 149, 178, 200, 200]
MULTS = E.MULTS

def make_speed(ps, e): return lambda p: min(200, 16 * (1 + p / ps) ** e)

def run_seeds(P, v, seeds):
    out = []
    for sd in seeds:
        smp = []
        r = sim3.run(P, v['tier_income'], v['pick_power'], v['pick_cost'], v['tread_cost'], seed=sd, sample=smp)
        out.append((r, dict(sim3.LAST['pts_at']), list(sim3.LAST['events']), smp, dict(sim3.LAST['speed'])))
    return out

def fit(runs):
    logp = {}
    for s in range(2, 12):
        vals = [max(1e-9, r[1][s]) for r in runs if s in r[1]]
        logp[s] = statistics.mean(math.log(x) for x in vals)
    best = None
    for lps in [x / 4 for x in range(0, 40)]:            # ps = 10^(lps/ ... ) 1 .. 1e10
        ps = 10 ** (lps / 4)
        for e in [x / 200 for x in range(8, 100)]:
            loss = 0
            for s in range(2, 12):
                f = min(200, 16 * (1 + math.exp(logp[s]) / ps) ** e)
                loss += (math.log(f) - math.log(REC[s - 1])) ** 2
            if best is None or loss < best[0]: best = (loss, ps, e)
    return best

def evaluate(trails, seeds, iters=4, verbose=True):
    P = dict(sim4.P0); P['trails'] = trails; P['sample_every'] = 60
    v = sim4.vals(E.POWER, E.pcost(1.0))
    ps, e = 60.0, 0.257
    for it in range(iters):
        sim3.speed = make_speed(ps, e)
        runs = run_seeds(P, v, seeds)
        loss, ps, e = fit(runs)
    sim3.speed = make_speed(ps, e)
    runs = run_seeds(P, v, seeds)
    return ps, e, loss, runs, P

def summarize(trails, ps, e, runs):
    f = make_speed(ps, e)
    s12 = statistics.mean(r[0][12] for r in runs) / 60
    # cap: first stage whose arrival speed >= 199
    arr = {s: statistics.mean(r[4][s] for r in runs if s in r[4]) for s in range(1, 13)}
    cap_t = statistics.mean(next((x[0] for x in r[3] if x[6] >= 199.5), 720) for r in runs)
    cap_stage = max(s for s in range(1, 13) if statistics.mean(r[0][s] for r in runs) / 60 <= cap_t)
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
        rows.append((trails[k][1], trails[k][0], statistics.mean(tb) if tb else None, statistics.mean(before) if before else None, statistics.mean(after) if after else None))
    return s12, arr, cap_t, cap_stage, rows

def hm(m): return f"{int(m//60)}h{int(m%60):02d}m"
def human(x):
    for s, d in (("B", 1e9), ("M", 1e6), ("K", 1e3)):
        if x >= d: return f"{x/d:g}{s}"
    return f"{x:g}"

if __name__ == '__main__':
    sim4.install_income_roll(True)
    seeds = range(1, 7)
    for alpha in (0.9, 1.0, 1.1, 1.2):
        t0 = 2500 / 2 ** alpha
        trails = [(0, 1)] + [(t0 * m ** alpha, m) for m in MULTS]
        ps, e, loss, runs, P = evaluate(trails, seeds)
        s12, arr, cap_t, cap_stage, rows = summarize(trails, ps, e, runs)
        print(f"alpha {alpha}: ps {ps:.3g} e {e:.3f} loss {loss:.3f} S12 {hm(s12)} cap at {hm(cap_t)} (stage {cap_stage}) T11 bought {hm(rows[-1][2]) if rows[-1][2] else '-'}")
        print("   arrival speeds", " ".join(f"{arr[s]:.0f}" for s in range(1, 13)), flush=True)
