import bpy,numpy as np,pathlib,json,hashlib
root=pathlib.Path(r'C:\Users\User\steal_a_football_goat');out=root/'outputs/PlayerRoster_20261104'
recipes=json.loads((out/'recipes.json').read_text());reports=[]
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
for recipe in recipes:
    path=root/'player_models'/recipe['model']
    source=path
    if recipe['id']=='Player_02':path=root/'outputs/GLB_Test_20261103/footballer_optimized.glb'
    before=set(bpy.data.objects);bpy.ops.import_scene.gltf(filepath=str(path));added=set(bpy.data.objects)-before
    mesh=max((o for o in added if o.type=='MESH'),key=lambda o:len(o.data.polygons));arm=next(o for o in added if o.type=='ARMATURE')
    assert sum(len(p.vertices)-2 for p in mesh.data.polygons)>=15000,(recipe['id'],'Unexpected mesh')
    for o in added:
        if o.type=='MESH' and o!=mesh and not any(mod.type=='ARMATURE' for mod in o.modifiers):
            o.hide_render=True;o.hide_set(True)
    mesh.name=recipe['id'];mesh.data.name=recipe['id'];arm.name=recipe['id']+'_Rig';arm.data.name=recipe['id']+'_Skeleton'
    bpy.context.view_layer.objects.active=mesh
    trimmed=0
    for v in mesh.data.vertices:
        groups=sorted([(g.group,g.weight) for g in v.groups if g.weight>0],key=lambda q:q[1],reverse=True)
        total=sum(w for _,w in groups[:4])
        if len(groups)>4:trimmed+=1
        for g,_ in groups:mesh.vertex_groups[g].remove([v.index])
        for g,w in groups[:4]:mesh.vertex_groups[g].add([v.index],w/total,'REPLACE')
    mesh.data.calc_loop_triangles()
    verts=np.array([v.co[:] for v in mesh.data.vertices])
    np.savez(out/(recipe['id']+'_geometry.npz'),vertices=verts,
      triangles=np.array([t.vertices[:] for t in mesh.data.loop_triangles]),
      uvs=np.array([[mesh.data.uv_layers.active.data[i].uv[:] for i in t.loops] for t in mesh.data.loop_triangles]),
      normals=np.array([[mesh.data.vertices[i].normal[:] for i in t.vertices] for t in mesh.data.loop_triangles]))
    reports.append({'id':recipe['id'],'source':recipe['model'],'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'reference_sha256':hashlib.sha256((root/'player_images'/recipe['reference']).read_bytes()).hexdigest(),'triangles':len(mesh.data.loop_triangles),'bones':len(arm.data.bones),'vertices':len(mesh.data.vertices),'trimmed_weight_vertices':trimmed,'max_influences':max(len([g for g in v.groups if g.weight>1e-6]) for v in mesh.data.vertices),'bounds':[verts.min(axis=0).tolist(),verts.max(axis=0).tolist()]})
    print('PREPARED',recipe['id'],flush=True)
bpy.ops.wm.save_as_mainfile(filepath=str(out/'prepared_geometry.blend'))
(out/'geometry_verification.json').write_text(json.dumps(reports,indent=2))
