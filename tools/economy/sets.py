"""Collection-set bonuses (plan, 2026-11-13): owning every roster footballer of a tier gives a permanent income bonus. Prints when each set
completes and what it does to the Stage 12 arrival time. Needs final_values.json. Run: python sets.py"""
import json, math, statistics, sys, sim3, sim4
fv = json.load(open('final_values.json')); curve = fv['curve']; REC = [16, 26, 42, 58, 76, 93, 109, 131, 149, 178, 200, 200]
def speed(p):
    if p <= 0: return 16
    x = math.log10(1 + p)
    for (p0, s0), (p1, s1) in zip(curve, curve[1:]):
        if p <= p1: return s0 + (s1 - s0) * (x - math.log10(1 + p0)) / (math.log10(1 + p1) - math.log10(1 + p0))
    return 200
sim3.speed = speed; sim4.install_reward_roll(0)
P = dict(sim4.P0); P['trails'] = [tuple(t) for t in fv['trails']]; P['gate'] = REC
V = sim4.vals(fv['pick_power'], fv['pick_cost'])
ROSTER = {0: [60, 40], 1: [60, 40], 2: [50, 30, 20], 3: [60, 40], 4: [60, 40], 5: [50, 30, 20]}   # Common..GOAT, Config.PlayerRoster weights
TIERS = ["Common", "Rare", "Epic", "Legendary", "Mythic", "GOAT"]
def scenario(bonuses, minutes=1440):
    P['sets'] = {t: (ROSTER[t], b) for t, b in enumerate(bonuses)} if any(bonuses) else None
    arr, times, mult = [], {t: [] for t in range(6)}, []
    for sd in range(1, 9):
        r = sim3.run(P, V['tier_income'], V['pick_power'], V['pick_cost'], V['tread_cost'], seed=sd, minutes=minutes)
        arr.append(r.get(12, minutes * 60) / 3600)
        for t, v in sim3.LAST['set_times'].items(): times[t].append(v / 3600)
        mult.append(1 + sum(bonuses[t] for t in sim3.LAST['set_times']))
    return statistics.mean(arr), times, statistics.mean(mult)
if __name__ == '__main__':
    base = scenario([0] * 6)[0]
    print(f"no sets: Stage 12 at {base:.2f} h")
    for label, b in [("A  1/1.5/2/3/4/5 %", [.01, .015, .02, .03, .04, .05]), ("B  2% each", [.02] * 6)]:
        arr, times, mult = scenario(b)
        print(f"\n{label}: total +{sum(b)*100:.1f}%  Stage 12 at {arr:.2f} h (x{arr/base:.3f})  mean multiplier after 24 h x{mult:.3f}")
        for t in range(6):
            ts = times[t]
            print(f"   {TIERS[t]:<10} +{b[t]*100:.1f}%  completes in {len(ts)}/8 seeds" + (f", mean {statistics.mean(ts):.1f} h" if ts else ""))
