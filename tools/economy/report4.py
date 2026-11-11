import sim4, sim3, math, statistics, explore4 as E
def nice3(x):
    if x < 1000: return round(x, -1) if x >= 100 else round(x)
    e = 10 ** (math.floor(math.log10(x)) - 1); return round(x / e) * e
def hm(m): return f"{int(m//60)}h{int(m%60):02d}m"
def human(x):
    for s, d in (("B", 1e9), ("M", 1e6), ("K", 1e3)):
        if x >= d: return f"{x/d:g}{s}"
    return f"{x:g}"
def main():
    T0, ALPHA, PSCALE = 1000, 1.3, 1.0
    TR = [(0, 1)] + [(nice3(T0 * m ** ALPHA), m) for m in E.MULTS]
    PC = [0] + [nice3(c) for c in E.pcost(PSCALE)[1:]]
    print("PICKAXES (power, cost):", [(p, human(c)) for p, c in zip(E.POWER, PC)])
    print("TRAILS (mult, cost):", [(m, human(c)) for c, m in TR])
    sim4.install_income_roll(True)
    P = dict(sim4.P0); P['trails'] = TR
    v = sim4.vals(E.POWER, PC)
    reaches = []; pickt = [[] for _ in E.POWER]; trailt = [[] for _ in TR]; hits = {s: [] for s in range(1, 13)}; spd = {s: [] for s in range(1, 13)}
    for seed in range(1, 13):
        smp = []
        r = sim3.run(P, v['tier_income'], v['pick_power'], v['pick_cost'], v['tread_cost'], seed=seed, sample=smp)
        reaches.append(r)
        for k in range(len(E.POWER)):
            t = next((s[0] for s in smp if s[3] > k), None)
            if t is not None: pickt[k].append(t)
        for k in range(len(TR)):
            t = next((s[0] for s in smp if s[7] >= k), None)
            if t is not None: trailt[k].append(t)
        for stg in range(1, 13):
            a = r.get(stg)
            if a is None: continue
            s = max((x for x in smp if x[0] * 60 <= a), key=lambda x: x[0], default=smp[0])
            hp = 10 * 3.7 ** (stg - 1)
            hits[stg].append(math.ceil(hp / E.POWER[s[3] - 1])); spd[stg].append(s[6])
    st12 = [r[12] / 60 for r in reaches]
    print("Stage 12 arrival: mean", hm(statistics.mean(st12)), "min", hm(min(st12)), "max", hm(max(st12)))
    print("stage arrival (mean):", " ".join(f"S{s}:{hm(statistics.mean([r[s]/60 for r in reaches]))}" for s in range(1, 13)))
    print("pickaxe bought at (min, mean):", [(E.POWER[k], hm(statistics.mean(t))) for k, t in enumerate(pickt) if t])
    print("trail bought at (min, mean):", [(TR[k][1], hm(statistics.mean(t))) for k, t in enumerate(trailt) if t and k])
    print("hits to break a Normal cage at arrival (mean) / speed:", " ".join(f"S{s}:{statistics.mean(hits[s]):.0f}h/{statistics.mean(spd[s]):.0f}" for s in range(1, 13) if hits[s]))

if __name__ == '__main__':
    main()
