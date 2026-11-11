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
CHASE = [12.8, 20.8, 33.6, 46.4, 60.8, 74.4, 87.2, 94.3, 112, 128.2, 144, 144]
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

def pursue(s, guard, px, pz, vp, mult=1.0, detect=math.inf, leash=math.inf):
    """True if the carrier crosses z=0 before being touched. The guard starts chasing when the carrier is within `detect`
    and gives up when farther than `leash`."""
    g = guard.copy(); speed = CHASE[s] * PICKUP_MULT * mult; r = HEIGHT[s] * 0.3 + 1.5
    t, chasing = 0.0, False
    while pz > 0 and t < 90:
        d = math.hypot(px - g.x, pz - g.z)
        if d <= r and chasing: return False
        if chasing and d > leash: chasing = False
        if not chasing and d <= detect and t >= REACTION: chasing = True
        if t < REACTION and detect == math.inf: chasing = False
        if chasing: k = min(1, speed * DT / max(d, 1e-6)); g.x += (px - g.x) * k; g.z += (pz - g.z) * k
        else: g.patrol_step(DT)
        pz -= vp * DT; t += DT
    return True

def trip(s, v, policy, rng, **opt):
    if s == 5: return True                                   # Stage 6: the Eye never attacks
    vp = v * PEN[s] / 16
    cages = [(rng.uniform(-HALF_W + CAGE_MARGIN, HALF_W - CAGE_MARGIN), rng.uniform(CAGE_MARGIN, L[s] - CAGE_MARGIN)) for _ in range(CAGES)]
    px, pz = rng.choice(cages) if policy == 'A' else min(cages, key=lambda c: c[1])
    guard = Guard(s, rng)
    if policy in ('A', 'B'): return pursue(s, guard, px, pz, vp, **opt)
    for _ in range(40):                                       # C: wait for a safe window
        if pursue(s, guard, px, pz, vp, **opt): return True
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
