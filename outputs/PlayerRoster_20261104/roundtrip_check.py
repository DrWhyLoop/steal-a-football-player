import bpy,pathlib,json
out=pathlib.Path(__file__).parent;recipes={r['id']:r for r in json.loads((out/'recipes.json').read_text())}
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=str(out/'READY_TO_IMPORT/Players_02_to_14.glb'))
meshes=[m for m in bpy.context.scene.objects if m.type=='MESH' and any(mod.type=='ARMATURE' for mod in m.modifiers)]
assert len(meshes)==13,len(meshes)
report=[]
for m in meshes:
    key=m.data.name;assert key in recipes,key
    arm=next(mod.object for mod in m.modifiers if mod.type=='ARMATURE');height=m.dimensions.z
    maps=[n for mat in m.data.materials for n in mat.node_tree.nodes if n.type=='TEX_IMAGE' and n.image]
    assert abs(height-recipes[key]['height'])<.002,(key,height)
    assert len(arm.data.bones)==52 and len(maps)==1
    report.append({'id':key,'height':height,'bones':len(arm.data.bones),'textures':len(maps),'triangles':sum(len(p.vertices)-2 for p in m.data.polygons)})
(out/'roundtrip_verification.json').write_text(json.dumps(sorted(report,key=lambda r:r['id']),indent=2))
print('ROUNDTRIP_OK',len(report))
