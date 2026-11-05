import pathlib,json,struct,hashlib
out=pathlib.Path(__file__).parent;root=out.parent.parent
reports=json.loads((out/'geometry_verification.json').read_text());poses=json.loads((out/'model_verification.json').read_text());recipes=json.loads((out/'recipes.json').read_text())
bundle=out/'READY_TO_IMPORT/Players_02_to_14.glb';raw=bundle.read_bytes();n,_=struct.unpack_from('<II',raw,12);d=json.loads(raw[20:20+n]);a=d['accessors']
triangles=sum(a[p['indices']]['count']//3 for m in d['meshes'] for p in m['primitives'])
assert len(d['meshes'])==13 and len(d['skins'])==13 and len(d['images'])==13
assert triangles==sum(r['triangles'] for r in reports)
assert all(len(s['joints'])==52 for s in d['skins'])
assert all(r['max_influences']<=4 for r in reports)
assert all(r['pose_test']['finite'] and r['pose_test']['moved_vertices']>0 for r in poses)
assert not d.get('animations')
unchanged={}
for r,rec in zip(reports,recipes):
    unchanged[r['id']]=hashlib.sha256((root/'player_models'/rec['model']).read_bytes()).hexdigest()==r['source_sha256'] and hashlib.sha256((root/'player_images'/rec['reference']).read_bytes()).hexdigest()==r['reference_sha256']
assert all(unchanged.values())
result={'bundle':str(bundle),'bytes':len(raw),'meshes':len(d['meshes']),'skins':len(d['skins']),'embedded_textures':len(d['images']),'triangles':triangles,'bone_counts':[len(s['joints']) for s in d['skins']],'all_pose_tests_passed':True,'all_sources_and_references_unchanged':all(unchanged.values()),'studio_import':'Pending user import; no computer-use automation requested','studio_playtest':'Pending import','gameplay_scripts_changed':[]}
(out/'verification.json').write_text(json.dumps(result,indent=2))
print(json.dumps(result))
