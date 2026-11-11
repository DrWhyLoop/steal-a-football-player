import sim4, sim3, math, sys
MULTS = [2, 4, 8, 16, 40, 100, 250, 600, 4000, 10000, 25000]
G = 90.1e6 ** (1 / 19)
def nice(x):
    if x < 10: return max(1, round(x))
    e = 10 ** (math.floor(math.log10(x)) - 1); return round(x / e) * e
POWER = [1] + [nice(G ** k) for k in range(1, 20)]
def pcost(scale=1.0, e=1.18): return [0] + [round(361 * (POWER[k] / 4) ** e * scale) for k in range(1, 20)]
def trails(t0, alpha): return [(0, 1)] + [(t0 * m ** alpha, m) for m in MULTS]
def timeline(P, v, seed=1):
    smp = []
    reach = sim3.run(P, v['tier_income'], v['pick_power'], v['pick_cost'], v['tread_cost'], seed=seed, sample=smp)
    return reach, smp
if __name__ == '__main__':
    sim4.install_income_roll(True)
    seeds = range(1, 9)
    print("powers", POWER)
    for pscale in (1.0, 1.15, 1.3):
        for t0, alpha in ((1000, 1.0), (1000, 1.3), (3000, 1.15)):
            P = dict(sim4.P0); P['trails'] = trails(t0, alpha)
            r, st = sim4.stage12(P, sim4.vals(POWER, pcost(pscale)), seeds)
            print(f"pscale {pscale} t0 {t0} alpha {alpha}: ", sim4.fmt(r), flush=True)
