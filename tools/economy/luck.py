import math, sys
S=[(.8,8),(.9,17),(1,60),(1.12,8),(1.28,4),(1.5,1.6),(1.8,.8),(2.2,.4),(2.7,.15),(3.3,.05)]
V=[(1,89),(1.5,6),(2,2),(2.4,.9),(2.8,.65),(3.2,.5),(3.8,.35),(4.5,.25),(5.5,.2),(7,.15)]
EXP=.2
def w(lst,L):
    ws=[x[1]*L**(i*EXP) for i,x in enumerate(lst)]; t=sum(ws); return [a/t for a in ws]
def mult(raw): return min(20,raw if raw<=6 else 6+math.sqrt(raw-6))
# tier income range (Common,Epic,GOAT) mean of Min+(Max-Min)*u, u=r^(1/L): E[u]=L/(L+1)
RANGES={'Common':(.79,1.19),'Epic':(.68,1.28),'GOAT':(.46,1.46)}
def stats(L,tier='Epic'):
    ps,pv=w(S,L),w(V,L)
    mn,mx=RANGES[tier]
    # integrate income roll with quadrature over u
    N=400; us=[((k+.5)/N)**0 for k in range(N)]  # placeholder
    # u=r^(1/L); sample r uniform quadrature
    rs=[(k+.5)/N for k in range(N)]
    ev=0; evraw=0
    for si,(sinc,_) in enumerate(S):
        for vi,(vinc,_) in enumerate(V):
            p=ps[si]*pv[vi]
            m=sum(mult(sinc*vinc*(mn+(mx-mn)*r**(1/L))) for r in rs)/N
            ev+=p*m
    pvar=1-pv[0]; pbig=sum(ps[5:]); 
    return ev,pvar,pbig,pv[7:] and sum(pv[7:]), ps[9]
print("L     E[mult]  vs L1.25  P(non-Normal var)  P(size>=Huge)  P(Lightning+)  P(Monumental)")
base=stats(1.25)[0]
for L in [1,1.25,1.5,2,3,4,6,8,10,15]:
    e,pv,pb,pl,pm=stats(L)
    print(f"{L:<5} {e:6.3f}   x{e/base:5.2f}      {pv*100:5.1f}%            {pb*100:5.2f}%        {pl*100:5.2f}%        {pm*100:.3f}%")
# roster tier-internal pick: GOAT weights 50/30/20 ; Common 60/40
for name,ws in [('GOAT 3-way',[50,30,20]),('Epic 3-way',[50,30,20]),('Common 2',[60,40])]:
    print(name,[round(x*100,1) for x in w([(0,a) for a in ws],1.25)],'->',[round(x*100,1) for x in w([(0,a) for a in ws],10)])

if "stage12" in sys.argv:
    # Stage 12 arrival with the shipped reward roll: old roll, new roll, new roll with every upgrade maxed. Needs final_values.json.
    import json, statistics, sim3, sim4
    fv = json.load(open('final_values.json'))
    curve, REC = fv['curve'], [16, 26, 42, 58, 76, 93, 109, 131, 149, 178, 200, 200]
    def speed(p):
        x = math.log10(1 + max(p, 0))
        if p <= 0: return 16
        for (p0, s0), (p1, s1) in zip(curve, curve[1:]):
            if p <= p1: return s0 + (s1 - s0) * (x - math.log10(1 + p0)) / (math.log10(1 + p1) - math.log10(1 + p0))
        return 200
    sim3.speed = speed
    P = dict(sim4.P0); P['trails'] = [tuple(t) for t in fv['trails']]; P['gate'] = REC
    V = sim4.vals(fv['pick_power'], fv['pick_cost'])
    def stage12(label, **kw):
        times = [sim3.run(P, V['tier_income'], V['pick_power'], V['pick_cost'], V['tread_cost'], seed=sd, minutes=900, stop12=True, **kw)[12] / 3600 for sd in range(1, 13)]
        print(f"{label:<44} Stage 12 mean {statistics.mean(times):.2f} h  (min {min(times):.2f}, max {max(times):.2f})")
    sim4.install_income_roll(True); stage12("old roll (before this change)")
    sim4.install_reward_roll(0); stage12("new roll, no upgrades")
    sim4.install_reward_roll(.5); stage12("new roll, luck +0.5")
    stage12("new roll, luck +0.5, income x1.25, gain x1.5", income_mult=1.25, gain_mult=1.5)
