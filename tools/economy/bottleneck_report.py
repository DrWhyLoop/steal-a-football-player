import sim2,json,copy,statistics
v=json.load(open('final_values.json'))
seeds=list(range(1,11))
def base_P():
    P=copy.deepcopy(sim2.A);P['sizes']=True;return P
def stage12(P=None,pw_mult=1.0,costs=None,walk_inf=False):
    P=P or base_P()
    pw=[p*pw_mult for p in v['pick_power']]
    pc=costs if costs is not None else v['pick_cost']
    orig=sim2.speed
    if walk_inf: sim2.speed=lambda p:1e6
    try:
        times=[]
        for sd in seeds:
            r,s,_,_=sim2.run(P,v['tier_income'],pw,pc,v['tread_cost'],True,seed=sd)
            times.append(r.get(12,720*60))
    finally: sim2.speed=orig
    return statistics.mean(times)
print("== 1. Stage 12 per premium multiplier (realistic, sizes, 10 seeds, owned from minute 0)")
base=stage12()
print(f"  no premium tool        {sim2.hm(base)}")
for m in (1.2,1.25,1.3,1.35,1.4,1.5):
    t=stage12(pw_mult=m); print(f"  x{m:<5}                 {sim2.hm(t)}   ({100*(1-t/base):4.1f}% faster)")
print("\n== 2. Bottleneck: time per stage (realistic, sizes, mean of 10 seeds)")
agg={};reach={}
for sd in seeds:
    r,s,_,_=sim2.run(base_P(),v['tier_income'],v['pick_power'],v['pick_cost'],v['tread_cost'],True,seed=sd)
    for st,d in sim2.LAST_STATS.items():
        a=agg.setdefault(st,{'trips':0,'walk':0,'mine':0,'other':0,'train':0,'hits':0})
        for k in a: a[k]+=d[k]/len(seeds)
    for st,t in r.items(): reach.setdefault(st,[]).append(t)
print(" stage | at (h:mm) | min at stage | trips | per-trip s | walk% | mine% | find/reveal/place% | treadmill% | avg hits | next pickaxe $")
tot={'walk':0,'mine':0,'other':0,'train':0}
for st in range(1,13):
    a=agg.get(st)
    if not a: continue
    dur=a['walk']+a['mine']+a['other']+a['train']
    for k in tot: tot[k]+=a[k]
    nxt=v['pick_cost'][st] if st<len(v['pick_cost']) else 0
    print(f"  {st:>3}  | {sim2.hm(statistics.mean(reach[st])):>7}  | {dur/60:8.1f}     | {a['trips']:5.1f} | {dur/a['trips']:6.1f}    | {100*a['walk']/dur:4.0f}  | {100*a['mine']/dur:4.0f}  | {100*a['other']/dur:5.0f}              | {100*a['train']/dur:4.0f}       | {a['hits']/a['trips']:6.1f}   | {nxt:,.0f}")
T=sum(tot.values())
print(f"  ALL   shares of all farming time: walk/carry {100*tot['walk']/T:.0f}%, mining {100*tot['mine']/T:.0f}%, find/reveal/pickup/place {100*tot['other']/T:.0f}%, treadmill time {100*tot['train']/T:.0f}%")
print("\n== 3. Counterfactuals for Stage 12 time (what removing each cost would buy)")
P=base_P();P['swing']=0.0001
print(f"  mining takes no time           {sim2.hm(stage12(P))}  ({100*(1-stage12(P)/base):.0f}% faster)")
P=base_P();P['find']=0;P['reveal']=0;P['pickup']=0;P['place']=0
print(f"  no find/reveal/pickup/place    {sim2.hm(stage12(P))}  ({100*(1-stage12(P)/base):.0f}% faster)")
t=stage12(walk_inf=True)
print(f"  walking takes no time          {sim2.hm(t)}  ({100*(1-t/base):.0f}% faster)")
t=stage12(costs=[0]*len(v['pick_cost']))
print(f"  every pickaxe free (no cash gate) {sim2.hm(t)}  ({100*(1-t/base):.0f}% faster)")
P=base_P();P['train_share']=0.0
print(f"  no treadmill time at all       {sim2.hm(stage12(P))}  ({100*(1-stage12(P)/base):.0f}% faster)")
v2=copy.deepcopy(v)
ti=[x*2 for x in v['tier_income']]
tt=[]
for sd in seeds:
    r,s,_,_=sim2.run(base_P(),ti,v['pick_power'],v['pick_cost'],v['tread_cost'],True,seed=sd); tt.append(r.get(12,720*60))
t=statistics.mean(tt)
print(f"  all card incomes doubled       {sim2.hm(t)}  ({100*(1-t/base):.0f}% faster)")
