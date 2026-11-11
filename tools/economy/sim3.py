"""Economy simulation v3: sim2 plus a configurable speed curve, a training-gain multiplier, a walk-speed multiplier
(premium perk test) and a carry-N pass (two cards per trip). Same assumptions as sim2 (see CLAUDE.md): one player, no steals,
15-hit farming rule, 12% of time on the treadmill, treadmill bought at <=25% of cash, card upgrades bought at <=25% of cash,
Lucky eggs, Golden eggs, variants and egg sizes at their real odds."""
import math, random

A = dict(swing=0.7, max_hits=15, base_to_stage1=150, egg_depth=1/3,
         onboarding_eggs=5, onboarding_hp=3, onboarding_dist=25,
         reveal=1.8, pickup=0.5, place=1.0, find=1.0, train_share=0.12, slots=30,
         hp_base=10, hp_growth=3.7, treadmill_buy_frac=0.25, upgrade_buy_frac=0.25,
         carry_walk=[16, 15, 14, 13, 12, 11],
         up_first_seconds=60, up_income=1.25, up_cost=1.6, up_max=20,
         gold_p=0.05, gold_m=2, diamond_p=0.005, diamond_m=5, giant_p=0.02, giant_m=3,
         lucky_p=0.03, lucky_gold=0.20, lucky_diamond=0.03, lucky_giant=0.08,
         sizes=True, size_skip_hits=30, skip_seconds=5, golden_interval=300, golden_hp_mult=3, golden_max_hits=30,
         golden_stages=(4, 11), golden_max_tier=4,
         gain=2.0,        # training points per second per treadmill multiplier while on the belt
         walk_mult=1.0,   # walk-speed multiplier (premium perk test)
         carry=1,         # cards carried per trip (Carry +1 pass = 2)
         detour=30.0)     # extra studs walked (both ways) to reach the second egg
STAGE_LEN = [3100/7]*8 + [3875/7]*2 + [4650/7, 6200/7]
STAGE_START = [sum(STAGE_LEN[:i]) for i in range(12)]
STAGE_TIER = [0, 0, 1, 1, 2, 2, 2, 3, 3, 4, 4, 5]
TREAD_MULT = [1.5, 2, 4, 6, 9, 12, 15, 20, 25, 35, 50, 75, 100, 250, 500]
SIZES = [(30, 0.5, 1.0), (55, 1.0, 1.0), (12, 2.5, 1.5), (3, 6.0, 3.0)]  # weight, HP x, variant odds x

def speed_current(p): return min(120, 16 + 12*math.log10(1 + p/100))
speed = speed_current            # replace with a curve to test another design
LAST = {}

def roll_mult(P, rnd, lucky, sz_odds):
    g = (P['lucky_gold'] if lucky else P['gold_p'])*sz_odds
    dm = (P['lucky_diamond'] if lucky else P['diamond_p'])*sz_odds
    gi = (P['lucky_giant'] if lucky else P['giant_p'])*sz_odds
    mult = 1
    r = rnd.random()
    if r < dm: mult *= P['diamond_m']
    elif rnd.random() < g: mult *= P['gold_m']
    if rnd.random() < gi: mult *= P['giant_m']
    return mult

def run(P, tier_inc, pick_power, pick_cost, tread_cost, seed=1, minutes=720, celestial=0, income_mult=1, sample=None):
    global LAST
    rnd = random.Random(seed)
    stats, reach, speed_at, pts_at, events = {}, {}, {}, {}, []
    t = 0; cash = 0; pts = 0; pick = 0; tread = 0; cards = []; broken = 0; income = 0
    trail = 0; trails = P.get("trails", [(0, 1)])
    trip_left = None; trip = None; golden = None; next_golden = P['golden_interval']
    while t < minutes*60:
        changed = False
        while pick+1 < len(pick_power) and cash >= pick_cost[pick+1]: cash -= pick_cost[pick+1]; pick += 1
        while tread+1 < len(TREAD_MULT) and tread_cost[tread+1] <= cash*P['treadmill_buy_frac']: cash -= tread_cost[tread+1]; tread += 1
        while trail+1 < len(trails) and trails[trail+1][0] <= cash*P["treadmill_buy_frac"]:
            trail += 1; cash -= trails[trail][0]; events.append((t, trail, pts))
        if cards:
            for _ in range(5):
                order = sorted(range(len(cards)), key=lambda i: (cards[i][1], -cards[i][0]))
                bought = False
                for i in order:
                    b, l = cards[i]
                    if l >= P['up_max']: continue
                    cost = math.ceil(P['up_first_seconds']*b*P['up_cost']**l)
                    if cost <= cash*P['upgrade_buy_frac']:
                        cash -= cost; cards[i][1] += 1; bought = True; changed = True
                    break
                if not bought: break
        if t >= next_golden:
            golden = rnd.randint(*P['golden_stages']); next_golden += P['golden_interval']
        if trip_left is None:
            v = speed(pts)*P['walk_mult']
            stage = 0
            for s in range(12):
                if P['hp_base']*P['hp_growth']**s/pick_power[pick] <= P['max_hits']: stage = s
            onboarding = broken < P['onboarding_eggs']
            is_golden = False; lucky = False
            if onboarding:
                stage = 0; hp = P['onboarding_hp']; d = P['base_to_stage1'] + P['onboarding_dist']
            else:
                if golden is not None and golden-1 <= stage:
                    ghp = P['hp_base']*P['hp_growth']**(golden-1)*P['golden_hp_mult']
                    if ghp/pick_power[pick] <= P['golden_max_hits']: stage = golden-1; is_golden = True; golden = None
                hp = P['hp_base']*P['hp_growth']**stage*(P['golden_hp_mult'] if is_golden else 1)
                d = P['base_to_stage1'] + STAGE_START[stage] + STAGE_LEN[stage]*P['egg_depth']
                lucky = stage < 11 and not is_golden and rnd.random() < P['lucky_p']
            tier = STAGE_TIER[stage]
            if is_golden: tier = min(P['golden_max_tier'], tier+1)
            mults, hits_total, extra = [], 0, 0.0
            for _ in range(1 if onboarding else P['carry']):
                sz_hp = 1; sz_odds = 1
                if P['sizes'] and not onboarding and not is_golden:
                    for _k in range(8):
                        r = rnd.random()*100; acc = 0
                        for w, h, o in SIZES:
                            acc += w
                            if r < acc: sz_hp, sz_odds = h, o; break
                        if math.ceil(hp*sz_hp/pick_power[pick]) <= P['size_skip_hits']: break
                        extra += P['skip_seconds']; sz_hp, sz_odds = 1, 1
                hits_total += max(1, math.ceil(hp*sz_hp/pick_power[pick]))
                mults.append(1 if onboarding else roll_mult(P, rnd, lucky, sz_odds))
            n = len(mults)
            carry_v = v*P['carry_walk'][tier]/16          # the heavier (here: the same tier) card sets the penalty
            walk = d/v + d/carry_v + (n-1)*P['detour']/v   # the detour to the second egg is walked at full speed
            other = extra + n*(P['find'] + P['reveal'] + P['pickup']) + n*P['place']
            mine = hits_total*P['swing']
            sc = 1/(1 - P['train_share'])
            dur = (walk + mine + other)*sc
            st = stats.setdefault(stage+1, {'trips': 0, 'walk': 0.0, 'mine': 0.0, 'other': 0.0, 'train': 0.0, 'dur': 0.0, 'v': 0.0})
            if is_golden: st = {'trips': 0, 'walk': 0.0, 'mine': 0.0, 'other': 0.0, 'train': 0.0, 'dur': 0.0, 'v': 0.0}  # Golden-egg detours are not counted in a stage's normal trips
            st['trips'] += 1; st['walk'] += walk*sc; st['mine'] += mine*sc; st['other'] += other*sc
            st['train'] += dur*P['train_share']; st['dur'] += dur; st['v'] += v
            trip_left = dur; trip = (stage, tier, mults)
            if stage+1 not in reach: reach[stage+1] = t; speed_at[stage+1] = v; pts_at[stage+1] = pts
        trip_left -= 1
        if trip_left <= 0:
            for m in trip[2]:
                cards.append([tier_inc[trip[1]]*m, 0]); broken += 1
                if len(cards) > P['slots']:
                    i = min(range(len(cards)), key=lambda k: cards[k][0]*P['up_income']**cards[k][1]); cards.pop(i)
            trip_left = None; changed = True
        if changed or t % 30 == 0: income = sum(b*P['up_income']**l for b, l in cards)
        cash += income*income_mult
        pts += P['train_share']*P['gain']*max(TREAD_MULT[tread], celestial)*trails[trail][1]
        t += 1
        if sample is not None and t % P.get('sample_every', 300) == 0: sample.append((t//60, pts, tread+1, pick+1, cash, income, speed(pts)*P["walk_mult"], trail))
    LAST = {'stats': stats, 'pts': pts, 'speed': speed_at, 'pts_at': pts_at, 'events': events}
    return reach

def hm(s): return f"{int(s//3600)}h{int(s%3600//60):02d}m"

def mean_run(P, v, seeds, **kw):
    """Mean stage arrival times and mean per-stage trip statistics over `seeds`."""
    reach_all, stats_all = [], []
    for sd in seeds:
        reach_all.append(run(P, v['tier_income'], v['pick_power'], v['pick_cost'], v['tread_cost'], seed=sd, **kw))
        stats_all.append(LAST['stats'])
    reach = {st: sum(r.get(st, 720*60) for r in reach_all)/len(seeds) for st in range(1, 13)}
    stats = {}
    for st in range(1, 13):
        parts = [s[st] for s in stats_all if st in s]
        if parts:
            stats[st] = {k: sum(p[k] for p in parts)/len(parts) for k in parts[0]}
    return reach, stats
