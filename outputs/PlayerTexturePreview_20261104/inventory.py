import struct,json,pathlib,hashlib
root=pathlib.Path(r'C:\Users\User\steal_a_football_goat')
out=root/'outputs/PlayerTexturePreview_20261104'
report=[]
for p in sorted((root/'player_models').glob('*.glb')):
 b=p.read_bytes(); n,_=struct.unpack_from('<II',b,12);d=json.loads(b[20:20+n]);a=d.get('accessors',[])
 report.append({'file':p.name,'bytes':len(b),'sha256':hashlib.sha256(b).hexdigest(),'triangles':sum(a[q['indices']]['count']//3 if 'indices' in q else a[q['attributes']['POSITION']]['count']//3 for m in d.get('meshes',[]) for q in m['primitives']),'skins':len(d.get('skins',[])),'images':len(d.get('images',[]))})
(out/'source_inventory.json').write_text(json.dumps(report,indent=2))
