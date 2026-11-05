import math, random, sys, json
A = dict(swing=0.7,max_hits=15,base_to_stage1=150,egg_depth=1/3,
 onboarding_eggs=5,onboarding_hp=3,onboarding_dist=25,
 reveal=1.8,pickup=0.5,place=1.0,find=1.0,train_share=0.12,slots=30,
 hp_base=10,hp_growth=3.7,treadmill_buy_frac=0.25,upgrade_buy_frac=0.25,
 carry_walk=[16,15,14,13,12,11],
 up_first_seconds=60,up_income=1.25,up_cost=1.6,up_max=20,
 gold_p=0.05,gold_m=2,diamond_p=0.005,diamond_m=5,giant_p=0.02,giant_m=3,
 lucky_p=0.03,lucky_gold=0.20,lucky_diamond=0.03,lucky_giant=0.08,
 sizes=False,size_skip_hits=30,skip_seconds=5,golden_interval=300,golden_hp_mult=3,golden_max_hits=30,golden_stages=(4,11),golden_max_tier=4)
STAGE_LEN=[3100/7]*8+[3875/7]*2+[4650/7,6200/7]
STAGE_START=[sum(STAGE_LEN[:i]) for i in range(12)]
STAGE_TIER=[0,0,1,1,2,2,2,3,3,4,4,5]
TREAD_MULT=[1.5,2,4,6,9,12,15,20,25,35,50,75,100,250,500]
SIZES=[(30,0.5,1.0),(55,1.0,1.0),(12,2.5,1.5),(3,6.0,3.0)] # weight, HP x, variant odds x
def speed(p): return min(120,16+12*math.log10(1+p/100))
def run(P,tier_inc,pick_power,pick_cost,tread_cost,realistic,seed=1,minutes=720,celestial=0,income_mult=1):
    rnd=random.Random(seed)
    t=0;cash=0;pts=0;pick=0;tread=0;cards=[];broken=0;income=0
    trip_left=None;trip=None;reach={};rows=[];golden=None;next_golden=P['golden_interval']
    speed_at={}
    def recompute():
        return sum(b*P['up_income']**l for b,l in cards)
    while t<minutes*60:
        changed=False
        while pick+1<len(pick_power) and cash>=pick_cost[pick+1]: cash-=pick_cost[pick+1];pick+=1
        while tread+1<len(TREAD_MULT) and tread_cost[tread+1]<=cash*P['treadmill_buy_frac']: cash-=tread_cost[tread+1];tread+=1
        if realistic and cards:
            for _ in range(5):
                order=sorted(range(len(cards)),key=lambda i:(cards[i][1],-cards[i][0]))
                bought=False
                for i in order:
                    b,l=cards[i]
                    if l>=P['up_max']: continue
                    cost=math.ceil(P['up_first_seconds']*b*P['up_cost']**l)
                    if cost<=cash*P['upgrade_buy_frac']:
                        cash-=cost;cards[i][1]+=1;bought=True;changed=True;break
                    break  # cheapest ratio not affordable yet
                if not bought:break
        if t>=next_golden:
            golden=rnd.randint(*P['golden_stages']);next_golden+=P['golden_interval']
        if trip_left is None:
            v=speed(pts)
            stage=0
            for s in range(12):
                if P['hp_base']*P['hp_growth']**s/pick_power[pick]<=P['max_hits']: stage=s
            onboarding=broken<P['onboarding_eggs']
            is_golden=False;lucky=False
            if onboarding: stage=0;hp=P['onboarding_hp'];d=P['base_to_stage1']+P['onboarding_dist']
            else:
                if realistic and golden is not None and golden-1<=stage:
                    ghp=P['hp_base']*P['hp_growth']**(golden-1)*P['golden_hp_mult']
                    if ghp/pick_power[pick]<=P['golden_max_hits']: stage=golden-1;is_golden=True;golden=None
                hp=P['hp_base']*P['hp_growth']**stage*(P['golden_hp_mult'] if is_golden else 1)
                d=P['base_to_stage1']+STAGE_START[stage]+STAGE_LEN[stage]*P['egg_depth']
                lucky=realistic and stage<11 and not is_golden and rnd.random()<P['lucky_p']
            sz_hp=1;sz_odds=1;extra=0
            if P['sizes'] and not onboarding and not is_golden:
                for _ in range(8):
                    r=rnd.random()*100;acc=0
                    for w,h,o in SIZES:
                        acc+=w
                        if r<acc: sz_hp,sz_odds=h,o;break
                    if math.ceil(hp*sz_hp/pick_power[pick])<=P['size_skip_hits']: break
                    extra+=P['skip_seconds'];sz_hp,sz_odds=1,1
            hp*=sz_hp
            hits=max(1,math.ceil(hp/pick_power[pick]))
            tier=STAGE_TIER[stage]
            if is_golden: tier=min(P['golden_max_tier'],tier+1)
            carry=v*P['carry_walk'][tier]/16
            dur=(extra+d/v+P['find']+hits*P['swing']+P['reveal']+P['pickup']+d/carry+P['place'])/(1-P['train_share'])
            mult=1
            if realistic and not onboarding:
                g=(P['lucky_gold'] if lucky else P['gold_p'])*sz_odds;dm=(P['lucky_diamond'] if lucky else P['diamond_p'])*sz_odds;gi=(P['lucky_giant'] if lucky else P['giant_p'])*sz_odds
                r=rnd.random()
                if r<dm: mult*=P['diamond_m']
                elif rnd.random()<g: mult*=P['gold_m']
                if rnd.random()<gi: mult*=P['giant_m']
            trip_left=dur;trip=(stage,tier,mult)
            if stage+1 not in reach: reach[stage+1]=t;speed_at[stage+1]=v
        trip_left-=1
        if trip_left<=0:
            cards.append([tier_inc[trip[1]]*trip[2],0]);broken+=1
            if len(cards)>P['slots']:
                i=min(range(len(cards)),key=lambda k:cards[k][0]*P['up_income']**cards[k][1]);cards.pop(i)
            trip_left=None;changed=True
        if changed or t%30==0: income=recompute()
        cash+=income*income_mult
        pts+=P['train_share']*2*max(TREAD_MULT[tread],celestial)
        t+=1
        if t%60==0 and t//60<=30: rows.append((t//60,cash,income,len(cards),pick+1,tread+1,speed(pts),(trip[0]+1) if trip else 1,sum(l for _,l in cards)))
    return reach,speed_at,rows,pts
def fmt(x):
    for s,u in ((1e15,'Qa'),(1e12,'T'),(1e9,'B'),(1e6,'M'),(1e3,'K')):
        if abs(x)>=s: return f"{x/s:.2f}{u}"
    return f"{x:.1f}"
def hm(s): return f"{int(s//3600)}h{int(s%3600//60):02d}m"
def avg(P,ti,pw,pc,tc,realistic,seeds,celestial=0,income_mult=1):
    rs=[run(P,ti,pw,pc,tc,realistic,seed=s,celestial=celestial,income_mult=income_mult) for s in seeds]
    reach={st:sum(r[0].get(st,720*60) for r in rs)/len(rs) for st in range(1,13)}
    spd={st:sum(r[1].get(st,0) for r in rs)/len(rs) for st in range(1,13)}
    return reach,spd,rs[0][2]
