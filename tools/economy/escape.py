"""Escape check (2026-11-11): share of carry trips where a player gets out of the stage (crosses its entrance edge towards the base)
with the card, before the stage guard touches them. Mirrors GuardService: the guard patrols random waypoints at chase*0.7, and as soon as a
carrier of a card from its stage is inside the zone it chases in a straight line at chase*1.15 (no range limit, no leash), touching at
hitHeight*0.3+1.5 studs. A touch drops the card and ends the trip. The Stage 6 Eye never attacks.
Policies: A = random cage, pick up at once; B = the cage nearest the exit (the 'well-played' trip), pick up at once;
C = nearest cage and wait (up to 20 s, perfect foresight) for a moment when the guard cannot catch you (upper bound of skill)."""
import math, random, sys
REC = [16, 26, 42, 58, 76, 93, 109, 131, 149, 178, 200, 200]
L = [3100 / 7] * 8 + [3875 / 7] * 2 + [4650 / 7, 6200 / 7]
PEN = [16, 16, 15, 15, 14, 14, 14, 13, 13, 12, 12, 11]
CHASE = [12.8, 20.8, 33.6, 46.4, 60.8, 74.4, 87.2, 94.3, 112, 128.2, 144, 122.4]   # = Config.GuardChaseSpeed (Stage 12 x0.85)
HEIGHT = [12, 12, 12, 12, 12, 12, 12.5, 13, 14, 14.5, 15.5, 20]
PICKUP_MULT, PATROL, HALF_W, CAGE_MARGIN, CAGES = 1.15, 0.7, 96, 12, 9
REACTION, DT = 0.25, 0.05

class Guard:
    def __init__(self, s, rng):
        self.s, self.rng = s, rng
        m = 4 + 0.25 * HEIGHT[s] * 1.65
        self.x0, self.x1, self.z0, self.z1 = -HALF_W + m, HALF_W - m, m, L[s] - m
        self.patrol = CHASE[s] * PATROL
        a, b = self.pt(), self.pt()
        u = rng.random(); self.x, self.z = a[0] + u * (b[0] - a[0]), a[1] + u * (b[1] - a[1]); self.way = b
    def pt(self): return (self.rng.uniform(self.x0, self.x1), self.rng.uniform(self.z0, self.z1))
    def patrol_step(self, dt):
        dx, dz = self.way[0] - self.x, self.way[1] - self.z; d = math.hypot(dx, dz)
        if d <= 2: self.way = self.pt(); return
        k = min(1, self.patrol * dt / d); self.x += dx * k; self.z += dz * k
    def copy(self):
        g = Guard.__new__(Guard); g.__dict__ = dict(self.__dict__); return g

def pursue(s, guard, px, pz, vp, mult=1.0, detect=150, leash=math.inf, twist=None):
    """True if the carrier crosses z=0 before being touched. The guard starts chasing when the carrier is within `detect`
    and gives up when farther than `leash`."""
    g = guard.copy(); speed = CHASE[s] * PICKUP_MULT * mult; r = HEIGHT[s] * 0.3 + 1.5
    t, chasing, stun = 0.0, False, 0.0
    while pz > 0 and t < 90:
        d = math.hypot(px - g.x, pz - g.z)
        if d <= r and chasing: return False
        if chasing and d > leash: chasing = False
        if not chasing and d <= detect and t >= REACTION: chasing = True
        if t < REACTION and detect == math.inf: chasing = False
        if chasing: k = min(1, speed * DT / max(d, 1e-6)); g.x += (px - g.x) * k; g.z += (pz - g.z) * k
        else: g.patrol_step(DT)
        if stun > 0: stun -= DT
        else:
            step = vp * DT * (twist.factor(t, pz) if twist else 1)
            hit = twist.event(t, pz, pz - step) if twist else None
            if hit == 'drop': return False                    # a lightning strike knocks the card loose
            stun = hit or 0.0
            pz -= step
        t += DT
    return True

# --- stage twists (docs/Plans.md part 2): what the sim assumes for each hazard. Policy A (random cage, unaware) / B (nearest cage, well played) --------------
# gust: every `period` s a gust slows the carrier by `slow` for `dur` s | cart: `tracks` minecart lanes across the stage, crossing one costs `stun` s with
# probability hit[policy] (B times the bell) | container: path `detour` longer | lava/ice: `area` of the floor slows by `slow`; B walks around lava (avoid)
# | lightning: one strike per `period` s on a carrier, dodged with probability dodge[policy], an undodged strike drops the card.
TWISTS = {
    2: dict(kind='gust', period=15.0, dur=1.5, slow=0.5),
    3: dict(kind='cart', tracks=3, hit={'A': 0.06, 'B': 0.012}, stun=1.0),
    6: dict(kind='container', detour=0.04),   # 0.08 broke the 60% random-cage floor (56.7%)
    7: dict(kind='lava', area=0.12, avoid={'A': 1.0, 'B': 0.33}, slow=0.35),
    8: dict(kind='ice', area=0.15, slow=0.15),
    10: dict(kind='lightning', period=8.0, dodge={'A': 0.5, 'B': 0.95}),
}

class Twist:
    """Per-trip hazard state. `scale` multiplies the strength (slow, hit chance, detour, strike rate): 1 = the proposal, 0.5 = half as harsh."""
    def __init__(self, s, policy, rng, scale):
        self.d, self.p, self.rng, self.k = TWISTS[s], 'A' if policy == 'A' else 'B', rng, scale
        self.phase, self.bins = rng.uniform(0, self.d.get('period', 1)), {}
        self.tracks = [L[s] * (i + 1) / (self.d.get('tracks', 0) + 1) for i in range(self.d.get('tracks', 0))]
    def factor(self, t, pz):
        d, kind = self.d, self.d['kind']
        if kind == 'gust': return 1 - d['slow'] * self.k if (t + self.phase) % d['period'] < d['dur'] else 1
        if kind == 'container': return 1 / (1 + d['detour'] * self.k)
        if kind in ('lava', 'ice'):
            b = int(pz // 12); u = self.bins.setdefault(b, self.rng.random())
            return 1 - d['slow'] * self.k if u < d['area'] * d.get('avoid', {}).get(self.p, 1.0) else 1
        return 1
    def event(self, t, pz0, pz1):
        d = self.d
        if d['kind'] == 'cart':
            for z in self.tracks:
                if pz0 > z >= pz1 and self.rng.random() < d['hit'][self.p] * self.k: return d['stun']
        if d['kind'] == 'lightning' and self.rng.random() < DT / d['period'] * self.k and self.rng.random() > d['dodge'][self.p]: return 'drop'

def trip(s, v, policy, rng, twists=None, **opt):
    if s == 5: return True                                   # Stage 6: the Eye never attacks
    vp = v * PEN[s] / 16
    cages = [(rng.uniform(-HALF_W + CAGE_MARGIN, HALF_W - CAGE_MARGIN), rng.uniform(CAGE_MARGIN, L[s] - CAGE_MARGIN)) for _ in range(CAGES)]
    px, pz = rng.choice(cages) if policy == 'A' else min(cages, key=lambda c: c[1])
    guard = Guard(s, rng)
    make = lambda: Twist(s, policy, rng, twists) if twists is not None and s in TWISTS else None
    if policy in ('A', 'B'): return pursue(s, guard, px, pz, vp, twist=make(), **opt)
    for _ in range(40):                                       # C: wait for a safe window
        if pursue(s, guard, px, pz, vp, twist=make(), **opt): return True
        for _ in range(int(0.5 / DT)): guard.patrol_step(DT)
    return False

def share(s, v, policy, n, seed=1, **opt):
    rng = random.Random(seed * 1000 + s)
    return sum(trip(s, v, policy, rng, **opt) for _ in range(n)) / n

if __name__ == '__main__':
    N = int(sys.argv[1]) if len(sys.argv) > 1 else 1500
    print(f"{'stage':>5} {'guard':>6} {'carrier@rec':>11} | recommended speed A / B / C | capped (200) A / B / C")
    for s in range(12):
        g = CHASE[s] * PICKUP_MULT
        row = [f"{share(s, v, p, N if p != 'C' else N // 3):4.0%}" for v in (REC[s], 200) for p in 'ABC']
        print(f"{s+1:>5} {g:>6.0f} {REC[s] * PEN[s] / 16:>11.0f} | {' '.join(row[:3])} | {' '.join(row[3:])}", flush=True)
