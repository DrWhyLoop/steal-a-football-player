"""Final retune report (2026-11-11): trail ladder, speed curve control points, arrival speeds vs recommended and guard chase speeds."""
import math, statistics
import sim4, sim3, explore4 as E
from explore5 import REC, MULTS, hm, human
from explore6 import evaluate, summarize
from report4 import nice3
ALPHA, BETA = 0.95, 0.6
CHASE = [None, None, None, None, None, None, None, 94.3, 112, 128.2, 144, 144]   # Config.GuardChaseSpeed at stages 8-12 (carrier chase x1.15)
CARRY = {9: 13 / 16, 10: 12 / 16, 11: 12 / 16, 12: 11 / 16}                        # WalkSpeed of the stage's card tier / 16
sim4.install_income_roll(True)
t0 = 2500 / 2 ** ALPHA
raw = [(t0 * m ** ALPHA * (BETA if k >= 8 else 1), m) for k, m in enumerate(MULTS)]
trails = [(0, 1)] + [(nice3(c), m) for c, m in raw]
xs, runs = evaluate(trails, range(1, 13))
s12, arr, at, cap_t, cap_stage, rows = summarize(trails, runs)
print("TRAILS (mult, price, bought at, speed at purchase -> +5 min):")
for r in rows: print(f"  x{r[0]:<6} ${human(r[1]):<6} {hm(r[2])}  {r[3]:.0f} -> {r[4]:.0f}")
print(f"Stage 12 reached: mean {hm(s12)} min {hm(min(r[0][12] for r in runs)/60)} max {hm(max(r[0][12] for r in runs)/60)}")
print("stage arrival:", " ".join(f"S{s}:{hm(at[s])}" for s in range(1, 13)))
print(f"200 cap first hit at {hm(cap_t)}; Stage 11 reached at {hm(at[11])}")
print("arrival speed vs recommended:", " ".join(f"S{s}:{arr[s]:.0f}/{REC[s-1]}" for s in range(1, 13)))
print("SPEED CURVE control points (Speed Points -> studs/s):", [(round(10 ** x - 1), REC[i]) for i, x in enumerate(xs)])
print("guard check (carrier at recommended speed x carry penalty vs guard chase x1.15):")
for s in (9, 10, 11, 12):
    c = CHASE[s - 1]; player = REC[s - 1] * CARRY[s]; guard = c * 1.15
    print(f"  S{s}: carrier {player:.0f} vs guard {guard:.0f} ({'guard catches' if guard > player else 'ESCAPES'}); player at arrival speed {arr[s]:.0f} -> carrier {arr[s]*CARRY[s]:.0f}")
