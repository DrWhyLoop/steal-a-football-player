import bpy, math, json, pathlib, hashlib
from mathutils import Vector
out=pathlib.Path(r'C:\Users\User\steal_a_football_goat\outputs\GLB_Test_20261103')
source=pathlib.Path(r'C:\Users\User\Downloads\base.glb')
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=str(source))
mesh=next(o for o in bpy.context.scene.objects if o.type=='MESH')
arm=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE')
mesh.name='Footballer_Test'; arm.name='Footballer_TestRig'
report={'original_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'original_triangles':sum(len(p.vertices)-2 for p in mesh.data.polygons),'bones':len(arm.data.bones)}
original=mesh.copy(); original.data=mesh.data.copy(); original.name='Original_HighDetail'; bpy.context.collection.objects.link(original); original.hide_render=True; original.hide_set(True)
bpy.context.view_layer.objects.active=mesh; mesh.select_set(True); arm.select_set(False)
mod=mesh.modifiers.new('Roblox_Reduction','DECIMATE'); mod.ratio=19500/report['original_triangles']; bpy.ops.object.modifier_apply(modifier=mod.name)
changed=0
for v in mesh.data.vertices:
 groups=sorted([(g.group,g.weight) for g in v.groups if g.weight>0],key=lambda a:a[1],reverse=True)
 total=sum(w for _,w in groups[:4])
 if len(groups)>4: changed+=1
 for g,_ in groups: mesh.vertex_groups[g].remove([v.index])
 for g,w in groups[:4]: mesh.vertex_groups[g].add([v.index],w/total,'REPLACE')
report.update({'optimized_triangles':sum(len(p.vertices)-2 for p in mesh.data.polygons),'optimized_vertices':len(mesh.data.vertices),'vertices_trimmed_to_four_weights':changed,'maximum_influences':max(len([g for g in v.groups if g.weight>1e-6]) for v in mesh.data.vertices)})
for o in bpy.context.selected_objects:o.select_set(False)
mesh.select_set(True);arm.select_set(True);bpy.context.view_layer.objects.active=arm
bpy.ops.export_scene.gltf(filepath=str(out/'footballer_optimized.glb'),export_format='GLB',use_selection=True,export_animations=False)
# Also provide FBX as an alternative import path.
bpy.ops.export_scene.fbx(filepath=str(out/'footballer_optimized.fbx'),use_selection=True,object_types={'ARMATURE','MESH'},add_leaf_bones=False,bake_anim=False)
scene=bpy.context.scene
scene.render.engine='CYCLES';scene.cycles.samples=16;scene.render.resolution_x=900;scene.render.resolution_y=1000;scene.render.resolution_percentage=100
scene.world.color=(0.2,0.2,0.2)
world=scene.world;world.use_nodes=True;world.node_tree.nodes.get('Background').inputs[0].default_value=(0.8,0.8,0.8,1);world.node_tree.nodes.get('Background').inputs[1].default_value=0.45
mat=mesh.data.materials[0];node=next(n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED');node.inputs['Base Color'].default_value=(0.4,0.43,0.47,1);node.inputs['Roughness'].default_value=.65
bpy.ops.object.camera_add(location=(0,-4,1.05));cam=bpy.context.object;cam.rotation_euler=(Vector((0,0,.87))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=2.12;scene.camera=cam
for loc,power,size in [((-2,-3,4),350,3),((2,-2,2),220,2),((0,2,3),250,2)]:
 bpy.ops.object.light_add(type='AREA',location=loc);light=bpy.context.object;light.data.energy=power;light.data.shape='DISK';light.data.size=size;light.rotation_euler=(Vector((0,0,1))-light.location).to_track_quat('-Z','Y').to_euler()
scene.render.image_settings.file_format='PNG';scene.render.filepath=str(out/'rest.png');bpy.ops.render.render(write_still=True)
def coords():
 deps=bpy.context.evaluated_depsgraph_get();ev=mesh.evaluated_get(deps);m=ev.to_mesh();pts=[v.co.copy() for v in m.vertices];ev.to_mesh_clear();return pts
rest=coords()
for name,axis,angle in [('LeftArm','Z',-25),('LeftForeArm','Z',55),('RightUpLeg','X',-15),('RightLeg','X',40)]:
 bone=arm.pose.bones.get(name)
 if bone:bone.rotation_mode='XYZ';bone.rotation_euler['XYZ'.index(axis)]=math.radians(angle)
bpy.context.view_layer.update();posed=coords();dist=[(a-b).length for a,b in zip(rest,posed)]
report['pose_test']={'moved_vertices':sum(d>1e-5 for d in dist),'maximum_displacement_m':max(dist),'all_positions_finite':all(math.isfinite(c) for p in posed for c in p)}
scene.render.filepath=str(out/'posed.png');bpy.ops.render.render(write_still=True)
for bone in arm.pose.bones:bone.rotation_euler=(0,0,0)
bpy.context.view_layer.update();bpy.ops.wm.save_as_mainfile(filepath=str(out/'inspection.blend'))
(out/'verification.json').write_text(json.dumps(report,indent=2))
print('AUDIT_RESULT '+json.dumps(report))
