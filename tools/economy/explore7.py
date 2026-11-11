import sys, statistics
import sim4, sim3, explore4 as E
from explore5 import REC, MULTS, hm
from explore6 import evaluate, summarize
sim4.install_income_roll(True)
seeds = range(1, 7)
for alpha in (0.85, 0.95, 1.0):
    for beta in (1.0, 0.6, 0.35):
        t0 = 2500 / 2 ** alpha
        trails = [(0, 1)] + [(t0 * m ** alpha * (beta if k >= 8 else 1), m) for k, m in enumerate(MULTS)]
        xs, runs = evaluate(trails, seeds)
        s12, arr, at, cap_t, cap_stage, rows = summarize(trails, runs)
        gains = [r[4] - r[3] for r in rows]
        print(f"alpha {alpha} beta {beta}: S12 {hm(s12)} S10 {hm(at[10])} S11 {hm(at[11])} cap {hm(cap_t)} T9 {hm(rows[8][2])} T10 {hm(rows[9][2])} T11 {hm(rows[10][2])} min gain {min(gains):.1f}  gains " + " ".join(f"{g:.0f}" for g in gains), flush=True)
