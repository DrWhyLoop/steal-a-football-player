import json,pathlib
root=pathlib.Path(r'C:\Users\User\steal_a_football_goat');out=root/'outputs/MonsterAxe_20261104'
def cf(vals):return 'CFrame.new('+','.join(str(v) for v in vals)+')'
lines=['-- Supplied saved keyframes, rounded to 1e-5; no external animation permissions required.','return {']
for path in sorted(out.glob('*R6.json'))+sorted(out.glob('*Run.json')):
    if path.stem=='RunR6':pass
    data=json.loads(path.read_text());lines.append('[%s]={Duration=%s,Tracks={'%(json.dumps(path.stem),data['Duration']))
    for name,frames in sorted(data['Tracks'].items()):
        frames.sort(key=lambda f:f['Time']);lines.append('[%s]={%s},'%(json.dumps(name),','.join('{%s,%s}'%(f['Time'],cf(f['Frame'])) for f in frames)))
    bases=data['Bases'] if isinstance(data['Bases'],dict) else {}
    lines.append('},Bases={'+','.join('[%s]=%s'%(json.dumps(k),cf(v)) for k,v in sorted(bases.items()))+'}},')
lines.append('}')
(root/'src/Shared/AnimationClips.luau').write_text('\n'.join(lines)+'\n',encoding='utf-8')
print('AnimationClips generated')
