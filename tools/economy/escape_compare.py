"""Before/after of the Stage 12 guard fix (chase 144 -> 122.4, detection radius 150 for every guard), same seeds, shares in percent."""
import math
import escape as E
N = 3000
def table(detect):
    return [[100 * E.share(s, v, p, N, detect=detect) for v in (E.REC[s], 200) for p in 'AB'] for s in range(12)]
E.CHASE[11] = 144
before = table(math.inf)
E.CHASE[11] = 122.4
after = table(150)
print("stage | recommended A / B | capped A / B   (before -> after, change in points)")
for s in range(12):
    cells = [f"{b:4.1f}->{a:4.1f} ({a-b:+.1f})" for b, a in zip(before[s], after[s])]
    print(f"{s+1:>5} | {cells[0]} / {cells[1]} | {cells[2]} / {cells[3]}")
print("max |change| Stages 1-11:", f"{max(abs(a-b) for s in range(11) for b, a in zip(before[s], after[s])):.1f}")
