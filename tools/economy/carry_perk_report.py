"""Experiment 2 (Carry +1 pass) and the premium-perk comparison, on the CURRENT economy (approved_values.json, current speed curve)."""
import json, copy, sim3
v = json.load(open('approved_values.json'))
seeds = list(range(1, 13))
sim3.speed = sim3.speed_current
def t12(mut=None, **kw):
    P = copy.deepcopy(sim3.A)
    vv = copy.deepcopy(v)
    if mut: mut(P, vv)
    r, st = sim3.mean_run(P, vv, seeds, **kw)
    return r[12], r, st
base, r0, st0 = t12()
print(f"current economy, no passes: Stage 12 {sim3.hm(base)}")
def line(name, t): print(f"  {name:44} {sim3.hm(t)}  ({100*(1-t/base):4.1f}% faster)")
print("-- Carry +1 (two cards per trip)")
line("Carry +1 alone", t12(lambda P, vv: P.update(carry=2))[0])
line("2x Cash alone", t12(income_mult=2)[0])
line("Carry +1 + 2x Cash", t12(lambda P, vv: P.update(carry=2), income_mult=2)[0])
line("Celestial 1500x alone", t12(celestial=1500)[0])
line("Carry +1 + 2x Cash + Celestial", t12(lambda P, vv: P.update(carry=2), income_mult=2, celestial=1500)[0])
print("-- premium tool perks (owned from minute 0)")
line("power x1.2 (current Hammer)", t12(lambda P, vv: vv.update(pick_power=[p*1.2 for p in vv['pick_power']]))[0])
line("power x1.5 (current best premium)", t12(lambda P, vv: vv.update(pick_power=[p*1.5 for p in vv['pick_power']]))[0])
for m in (1.05, 1.10, 1.20):
    line(f"walk speed +{round((m-1)*100)}% only", t12(lambda P, vv, m=m: P.update(walk_mult=m))[0])
line("walk +10% AND power x1.2", t12(lambda P, vv: (P.update(walk_mult=1.1), vv.update(pick_power=[p*1.2 for p in vv['pick_power']])))[0])
