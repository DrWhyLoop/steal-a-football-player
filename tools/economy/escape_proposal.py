"""Escape table with the proposed fix: Stage 12 chase speed x0.85 (144 -> 122.4) and a 150-stud detection radius for every guard."""
import math
import escape as E
N = 1500
print(f"{'stage':>5} | recommended speed A / B | capped (200) A / B   (A random cage, B nearest cage; C upper bound)")
for s in range(12):
    mult = 0.85 if s == 11 else 1.0
    row = [f"{E.share(s, v, p, N, mult=mult, detect=150):4.0%}" for v in (E.REC[s], 200) for p in 'AB']
    print(f"{s+1:>5} | {row[0]} / {row[1]} | {row[2]} / {row[3]}", flush=True)
