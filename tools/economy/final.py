"""Final numbers for the build (2026-11-11): trail ladder, SpeedCurve control points, sign points per stage, pickaxe bought-at times."""
import json, math, statistics
import sim4, sim3, explore4 as E
from explore5 import REC, MULTS, hm, human
from explore6 import evaluate, summarize
from report4 import nice3
ALPHA, BETA = 0.95, 0.6
sim4.install_income_roll(True)
t0 = 2500 / 2 ** ALPHA
trails = [(0, 1)] + [(nice3(t0 * m ** ALPHA * (BETA if k >= 8 else 1)), m) for k, m in enumerate(MULTS)]
xs, runs = evaluate(trails, range(1, 13))
s12, arr, at, cap_t, cap_stage, rows = summarize(trails, runs)
PC = [0] + [nice3(c) for c in E.pcost(1.0)[1:]]
pickt = [[] for _ in E.POWER]
for r in runs:
    for k in range(len(E.POWER)):
        t = next((s[0] for s in r[3] if s[3] > k), None)
        if t is not None: pickt[k].append(t)
pts12 = statistics.mean(r[1][12] for r in runs if 12 in r[1])
print(f"Stage 12 {hm(s12)} cap {hm(cap_t)} S11 {hm(at[11])}")
print("PICKAXES (power, price, bought at mean [min-max reached by]):")
for k, p in enumerate(E.POWER):
    t = pickt[k]
    print(f"  {k+1:>2} power {p:>9} ${human(PC[k]):>5}  " + (f"{hm(statistics.mean(t))}  ({len(t)}/12 seeds within 12 h)" if t else "never"))
curve = [(round(10 ** x - 1), REC[i]) for i, x in enumerate(xs)]
print("SPEED CURVE:", curve, "| Stage 12 arrival points", round(pts12))
print("SIGN POINTS per stage (recommended = curve points at that stage's speed; Stage 12 = mean arrival points):", [c[0] for c in curve] + [round(pts12)])
json.dump({"curve": curve, "pts12": round(pts12), "trails": [(c, m) for c, m in trails], "pick_power": E.POWER, "pick_cost": PC}, open("final_values.json", "w"))
