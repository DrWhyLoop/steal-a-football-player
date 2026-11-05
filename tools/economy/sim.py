import math, sys, json
# ---------------- assumptions (all printed) ----------------
A = dict(
 swing=0.7,            # s per hit (Config.SwingCooldown)
 max_hits=15,          # player farms the highest stage whose eggs die in <= this many hits
 base_to_stage1=150,   # studs from the plot to the Stage 1 entrance
 egg_depth=1/3,        # average egg distance into its stage, as a fraction of stage length
 onboarding_eggs=5, onboarding_hp=3, onboarding_dist=40,  # first N breaks: 3 hits, egg 40 studs into Stage 1
 reveal=1.8, pickup=0.5, place=1.0, find=1.0,   # s: egg swell, grab, place on display, aim at next egg
 train_share=0.12,     # fraction of play time spent standing on the treadmill
 slots=30,             # displays; once full the weakest card is replaced
 hp_base=10, hp_growth=3.7,
 treadmill_buy_frac=0.25, # buy next treadmill when its price <= this fraction of cash
 carry_walk=[16,15,14,13,12,11],  # Config.Tiers WalkSpeed per tier (carry speed = speed*walk/16)
)
STAGE_LEN=[3100/7]*8+[3875/7]*2+[4650/7,6200/7]
STAGE_START=[sum(STAGE_LEN[:i]) for i in range(12)]
STAGE_TIER=[0,0,1,1,2,2,2,3,3,4,4,5]
TREAD_MULT=[1.5,2,4,6,9,12,15,20,25,35,50,75,100,250,500]
TREAD_COST=[0,100,750,5e3,3e4,1.8e5,1.1e6,6.5e6,4e7,2.5e8,1.5e9,9e9,5.5e10,3.3e11,1.5e12]
def speed(p): return min(120,16+12*math.log10(1+p/100))
def run(P, tier_inc, pick_power, pick_cost, minutes=600, verbose=False):
    t=0;cash=0;pts=0;pick=0;tread=0;cards=[];eggs_broken=0
    trip_left=None;trip=None;reach={};rows=[]
    next_min=0
    while t<minutes*60:
        income=sum(cards)
        # buy
        while pick+1<len(pick_power) and cash>=pick_cost[pick+1]: cash-=pick_cost[pick+1];pick+=1
        while tread+1<len(TREAD_MULT) and TREAD_COST[tread+1]<=cash*P['treadmill_buy_frac']: cash-=TREAD_COST[tread+1];tread+=1
        if trip_left is None:
            v=speed(pts)
            stage=0
            for s in range(12):
                hp=P['hp_base']*P['hp_growth']**s
                if hp/pick_power[pick]<=P['max_hits']: stage=s
            onboarding=eggs_broken<P['onboarding_eggs']
            if onboarding: stage=0;hp=P['onboarding_hp'];d=P['base_to_stage1']+P['onboarding_dist']
            else:
                hp=P['hp_base']*P['hp_growth']**stage
                d=P['base_to_stage1']+STAGE_START[stage]+STAGE_LEN[stage]*P['egg_depth']
            hits=max(1,math.ceil(hp/pick_power[pick]))
            tier=STAGE_TIER[stage]
            carry=v*P['carry_walk'][tier]/16
            dur=(d/v+P['find']+hits*P['swing']+P['reveal']+P['pickup']+d/carry+P['place'])/(1-P['train_share'])
            trip_left=dur;trip=(stage,tier)
            reach.setdefault(stage+1,t)
        trip_left-=1
        if trip_left<=0:
            cards.append(tier_inc[trip[1]]);eggs_broken+=1
            if len(cards)>P['slots']: cards.remove(min(cards))
            trip_left=None
        cash+=income
        pts+=P['train_share']*2*TREAD_MULT[tread]
        t+=1
        if verbose and t//60>=next_min and next_min<=30:
            rows.append((next_min,cash,income,len(cards),pick+1,tread+1,speed(pts),(trip[0]+1) if trip else 1,eggs_broken));next_min+=1
    return reach,rows,pts
def fmt(x):
    for s,u in ((1e12,'T'),(1e9,'B'),(1e6,'M'),(1e3,'K')):
        if abs(x)>=s: return f"{x/s:.2f}{u}"
    return f"{x:.1f}"
if __name__=="__main__":
    cfg=json.load(open(sys.argv[1]))
    pw=cfg['pick_power'];pc=cfg['pick_cost'];ti=cfg['tier_income']
    A.update(cfg.get('assume',{}))
    print("ASSUMPTIONS");[print(f"  {k} = {v}") for k,v in A.items()]
    print(f"  stage starts (studs): {[round(x) for x in STAGE_START]}")
    print(f"  tier income $/s: {ti}\n  pickaxe power: {[round(x,1) for x in pw]}\n  pickaxe price: {[fmt(x) for x in pc]}")
    print("  baseline: single card per trip, no steals, no variants/Lucky/Golden, no card upgrades, no daily/index rewards")
    reach,rows,pts=run(A,ti,pw,pc,verbose=True)
    print("\nMINUTE | cash | income/s | cards | pickaxe | treadmill | speed | stage | eggs")
    for r in rows: print(f"{r[0]:>3}  {fmt(r[1]):>8} {fmt(r[2]):>8} {r[3]:>3}  P{r[4]:<2} T{r[5]:<2} {r[6]:5.1f} S{r[7]:<2} {r[8]}")
    print("\nMILESTONE: first farming trip at stage")
    for s in sorted(reach): print(f"  Stage {s:>2}: {int(reach[s]//3600)}h{int(reach[s]%3600//60):02d}m{int(reach[s]%60):02d}s")
