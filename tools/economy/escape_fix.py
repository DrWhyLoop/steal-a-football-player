import math, sys
from escape import share, REC, CHASE, PEN
N = 1200
print("stage 12 and 11: escape share A (random cage) / B (nearest cage) at recommended speed")
for s in (10, 11):
    for mult in (1.0, 0.9, 0.85, 0.8):
        for detect, leash in ((math.inf, math.inf), (150, math.inf), (100, math.inf), (math.inf, 300), (150, 250)):
            r = [f"{share(s, REC[s], p, N, mult=mult, detect=detect, leash=leash):4.0%}" for p in 'AB']
            print(f"S{s+1} chase x{mult} detect {detect} leash {leash}: A {r[0]} B {r[1]}", flush=True)
