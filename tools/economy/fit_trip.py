"""Experiment 1: tune the speed curve, training gain and prices so a round trip stays 60-90 s at every stage and Stage 12 stays at
about 3.5 h. Speed curve: v(P) = min(VMAX, 16 * (1 + P/P0)^alpha). Writes fit_trip.json."""
import json, math, random, sys, time, copy
import sim3

VMAX = float(sys.argv[1]) if len(sys.argv) > 1 else 240.0
ITER = int(sys.argv[2]) if len(sys.argv) > 2 else 700
OUT = sys.argv[3] if len(sys.argv) > 3 else 'fit_trip.json'
POW = json.load(open('approved_values.json'))['pick_power']
TARGET_MIN = {2: 4, 3: 10, 4: 18, 5: 28, 6: 41, 7: 57, 8: 76, 9: 98, 10: 125, 11: 160, 12: 210}
LOW, HIGH = 60.0, 90.0

def build(p):
    alpha, lp0, gain, c0, g, b, rho, t1, tr = p
    P = copy.deepcopy(sim3.A); P['gain'] = gain
    sim3.speed = lambda pts: min(VMAX, 16*(1 + pts/(10**lp0))**alpha)
    v = {'pick_power': POW,
         'tier_income': [c0*g**k for k in range(6)],
         'pick_cost': [0] + [b*rho**n for n in range(14)],
         'tread_cost': [0] + [t1*tr**n for n in range(14)]}
    return P, v

def loss(p, seeds=(1, 2)):
    P, v = build(p)
    reach, stats = sim3.mean_run(P, v, seeds)
    e = 0.0
    for st, m in TARGET_MIN.items():
        e += math.log(max(reach[st]/60, 0.5)/m)**2
    for st in range(3, 13):  # stages 1-2 are short by nature: only the upper bound applies there
        if st not in stats: e += 4; continue
        trip = stats[st]['dur']/stats[st]['trips']
        if trip > HIGH: e += 2*math.log(trip/HIGH)**2
        elif trip < LOW: e += 2*math.log(LOW/trip)**2
    for st in (1, 2):
        if st in stats:
            trip = stats[st]['dur']/stats[st]['trips']
            if trip > HIGH: e += 2*math.log(trip/HIGH)**2
    return e

if __name__ == '__main__':
    random.seed(11)
    best = [0.30, 2.0, 2.0, 1.0, 9.0, 270.0, 3.75, 120.0, 1.96]
    if len(sys.argv) > 4: best = json.load(open(sys.argv[4]))['params']  # start from an earlier fit
    be = loss(best); print('start', round(be, 3), flush=True)
    t0 = time.time()
    for i in range(ITER):
        sc = 0.18 if i < ITER*0.5 else 0.08
        c = [best[0]*math.exp(random.gauss(0, sc*.5)), best[1]+random.gauss(0, sc*1.5), best[2]*math.exp(random.gauss(0, sc)),
             best[3]*math.exp(random.gauss(0, sc)), best[4]*math.exp(random.gauss(0, sc*.5)), best[5]*math.exp(random.gauss(0, sc)),
             best[6]*math.exp(random.gauss(0, sc*.3)), best[7]*math.exp(random.gauss(0, sc)), best[8]*math.exp(random.gauss(0, sc*.4))]
        c[0] = min(max(c[0], .08), 1.0)
        e = loss(c)
        if e < be: best, be = c, e
        if i % 50 == 0: print(i, round(be, 3), int(time.time()-t0), flush=True)
    json.dump({'vmax': VMAX, 'params': best, 'loss': be}, open(OUT, 'w'))
    print('done', be, best, flush=True)
