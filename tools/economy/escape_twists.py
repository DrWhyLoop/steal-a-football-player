"""Escape check with the stage twists (docs/Plans.md part 2). Every stage must keep a well-played escape (policy B) of at least 97% and a random-cage
escape (policy A) of at least 60% at the recommended speed. Prints baseline vs twists; a twist that breaks a limit is reduced (scale 1 -> 0.25) until it passes."""
import escape as E
N = 4000
A_MIN, B_MIN = 0.60, 0.97
def row(s, scale):
    return [E.share(s, E.REC[s], p, N, twists=scale) for p in 'AB']
print(f"{'stage':>5} {'twist':>10} | baseline A / B | with twist A / B | verdict")
for s in range(12):
    base = row(s, None)
    kind = E.TWISTS.get(s, {}).get('kind', '-')
    if s not in E.TWISTS:
        print(f"{s+1:>5} {kind:>10} | {base[0]:5.1%} / {base[1]:5.1%} |                  | unchanged"); continue
    scale, now = 1.0, row(s, 1.0)
    first = now
    while (now[0] < A_MIN or now[1] < B_MIN) and scale > 0.25:
        scale -= 0.25; now = row(s, scale)
    verdict = "ok at full strength" if scale == 1.0 else f"REDUCE to {scale:.2f} of the proposal -> {now[0]:.1%} / {now[1]:.1%}"
    print(f"{s+1:>5} {kind:>10} | {base[0]:5.1%} / {base[1]:5.1%} | {first[0]:5.1%} / {first[1]:5.1%}  | {verdict}", flush=True)
