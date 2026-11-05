import sim2,json
POW=[1,3.7,13.7,50.7,187,693,2565,9493,35124,129959,480848,1779000,6583000,24357000,90121000]
TI=[1,8,75,700,6800,65000]
PC=[0,270,1200,5100,22000,100000,440000,1900000,8500000,37000000,160000000,720000000,3200000000,14000000000,61000000000]
TC=[0,0,120,230,450,890,1700,3400,6700,13000,26000,51000,99000,195000,380000,750000]
TC=[0]+[0]+TC[2:]  # TC[1] unused index shift
TC=[0,120,230,450,890,1700,3400,6700,13000,26000,51000,99000,195000,380000,750000]
seeds=[1,2,3,4,5,6,7,8]
json.dump(dict(pick_power=POW,pick_cost=PC,tier_income=TI,tread_cost=TC),open('final_values.json','w'))
for real in (False,True):
    r,s,rows=sim2.avg(sim2.A,TI,POW,PC,TC,real,seeds)
    print("\n== "+("REALISTIC (upgrades<=25% cash, Lucky/Golden/variants at real odds)" if real else "BASELINE")+f"  (mean of {len(seeds)} seeds)")
    print("Stage | first farming trip | speed then (studs/s)")
    for st in range(1,13): print(f"  {st:>2}   {sim2.hm(r[st]):>7}   {s[st]:5.1f}")
    if real:
        print("first 30 min (seed 1): min cash income/s cards pick tread speed stage upgrade-levels")
        for x in rows[:30:3]: print(f"  {x[0]:>2} {sim2.fmt(x[1]):>8} {sim2.fmt(x[2]):>8} {x[3]:>2} P{x[4]} T{x[5]} {x[6]:.1f} S{x[7]} L{x[8]}")
