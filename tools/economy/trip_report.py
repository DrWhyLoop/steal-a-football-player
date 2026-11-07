"""Report for experiments 1 and 2 on a fitted economy: python trip_report.py fit_trip_240.json"""
import json, sys, copy, statistics
FIT = sys.argv[1]
sys.argv = sys.argv[:1]  # fit_trip reads its own arguments at import
import sim3, fit_trip

fit = json.load(open(FIT))
fit_trip.VMAX = fit['vmax']
p = fit['params']
P, v = fit_trip.build(p)
alpha, lp0 = p[0], p[1]
seeds = list(range(1, 13))
print(f"VMAX {fit['vmax']:.0f}  speed(P) = min({fit['vmax']:.0f}, 16*(1+P/{10**lp0:,.0f})^{alpha:.3f})   training gain {p[2]:.2f} points/s per treadmill multiplier")
print("tier incomes $/s:", [round(x, 1) for x in v['tier_income']])
print("pickaxe prices (P2..P15):", [f"{x:,.0f}" for x in v['pick_cost'][1:]])
print("treadmill prices (tier 2..15):", [f"{x:,.0f}" for x in v['tread_cost'][1:]])
reach, stats = sim3.mean_run(P, v, seeds)
print("\nstage | arrives | speed on arrival | trips | trip s (mean) | walk% | mine% | other% | treadmill% | recommended speed (75 s trip)")
for st in range(1, 13):
    if st not in stats: continue
    a = stats[st]
    tot = a['walk'] + a['mine'] + a['other'] + a['train']
    d = P['base_to_stage1'] + sim3.STAGE_START[st-1] + sim3.STAGE_LEN[st-1]*P['egg_depth']
    cf = P['carry_walk'][sim3.STAGE_TIER[st-1]]/16
    need = d*(1 + 1/cf)/(75*(1 - P['train_share']) - 8)
    print(f"  {st:>2}  | {sim3.hm(reach[st]):>6}  | {a['v']/a['trips']:8.1f}         | {a['trips']:5.1f} | {a['dur']/a['trips']:6.1f}        | {100*a['walk']/tot:4.0f}  | {100*a['mine']/tot:4.0f}  | {100*a['other']/tot:4.0f}   | {100*a['train']/tot:4.0f}       | {max(16, need):6.1f}")
base = reach[12]
print(f"\nStage 12 arrival: {sim3.hm(base)}")
print("\n-- Carry +1 and passes on this economy (12 seeds)")
def t12(mut=None, **kw):
    PP = copy.deepcopy(P); vv = copy.deepcopy(v)
    if mut: mut(PP, vv)
    return sim3.mean_run(PP, vv, seeds, **kw)[0][12]
def line(name, t): print(f"  {name:36} {sim3.hm(t)}  ({100*(1-t/base):5.1f}% faster)")
line("Carry +1 alone", t12(lambda PP, vv: PP.update(carry=2)))
line("2x Cash alone", t12(income_mult=2))
line("Carry +1 + 2x Cash", t12(lambda PP, vv: PP.update(carry=2), income_mult=2))
line("Celestial 1500x alone", t12(celestial=1500))
line("Carry +1 + 2x Cash + Celestial", t12(lambda PP, vv: PP.update(carry=2), income_mult=2, celestial=1500))
print("\n-- premium perks on this economy (40 seeds, standard error about 2 min)")
seeds40 = list(range(100, 140))
def t12b(mut):
    res = []
    for sd in seeds40:
        PP = copy.deepcopy(P); vv = copy.deepcopy(v); mut(PP, vv)
        res.append(sim3.run(PP, vv['tier_income'], vv['pick_power'], vv['pick_cost'], vv['tread_cost'], seed=sd).get(12, 720*60))
    return statistics.mean(res)
b40 = t12b(lambda PP, vv: None)
print(f"  baseline {sim3.hm(b40)}")
for name, mut in (("walk +5%", lambda PP, vv: PP.update(walk_mult=1.05)), ("walk +10%", lambda PP, vv: PP.update(walk_mult=1.10)),
                  ("power x1.2", lambda PP, vv: vv.update(pick_power=[x*1.2 for x in vv['pick_power']])),
                  ("power x1.5", lambda PP, vv: vv.update(pick_power=[x*1.5 for x in vv['pick_power']]))):
    t = t12b(mut); print(f"  {name:12} {sim3.hm(t)}  ({100*(1-t/b40):5.1f}% faster)")
