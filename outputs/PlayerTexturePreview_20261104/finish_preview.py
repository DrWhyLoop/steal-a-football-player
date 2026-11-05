import bpy,pathlib,json,math,hashlib
from mathutils import Vector
out=pathlib.Path(__file__).parent
bpy.ops.wm.open_mainfile(filepath=str(out/'working.blend'))
m=next(o for o in bpy.context.scene.objects if o.type=='MESH');a=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE')
m.name='Player_01';a.name='Player_01_Rig'
mat=bpy.data.materials.new('Player_01_ReferenceColor');mat.use_nodes=True
bsdf=next(n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
bsdf.inputs['Roughness'].default_value=.78
image=bpy.data.images.load(str(out/'player_01_basecolor.png'));image.pack()
tex=mat.node_tree.nodes.new('ShaderNodeTexImage');tex.image=image;mat.node_tree.links.new(tex.outputs['Color'],bsdf.inputs['Base Color'])
m.data.materials.clear();m.data.materials.append(mat)
trimmed=0
for v in m.data.vertices:
    groups=sorted([(g.group,g.weight) for g in v.groups if g.weight>0],key=lambda q:q[1],reverse=True)
    total=sum(w for _,w in groups[:4])
    if len(groups)>4:trimmed+=1
    for g,_ in groups:m.vertex_groups[g].remove([v.index])
    for g,w in groups[:4]:m.vertex_groups[g].add([v.index],w/total,'REPLACE')
scene=bpy.context.scene
scene.render.resolution_x=1100;scene.render.resolution_y=1000;scene.cycles.samples=24
scene.view_settings.view_transform='Standard';scene.view_settings.look='None';scene.view_settings.exposure=-.5
cam=scene.camera;cam.location=(0,-4,.50);cam.rotation_euler=(Vector((0,0,.50))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=1.20
scene.render.filepath=str(out/'textured_front.png');bpy.ops.render.render(write_still=True)
cam.location=(1.7,-3,.65);cam.rotation_euler=(Vector((0,0,.50))-cam.location).to_track_quat('-Z','Y').to_euler();scene.render.filepath=str(out/'textured_threequarter.png');bpy.ops.render.render(write_still=True)
cam.location=(0,4,.50);cam.rotation_euler=(Vector((0,0,.50))-cam.location).to_track_quat('-Z','Y').to_euler();scene.render.filepath=str(out/'textured_back.png');bpy.ops.render.render(write_still=True)
def coords():
    ev=m.evaluated_get(bpy.context.evaluated_depsgraph_get());me=ev.to_mesh();pts=[v.co.copy() for v in me.vertices];ev.to_mesh_clear();return pts
rest=coords()
for name,angle in [('LeftArm',-30),('LeftForeArm',45),('RightUpLeg',-15),('RightLeg',30)]:
    bone=a.pose.bones.get(name)
    if bone:bone.rotation_mode='XYZ';bone.rotation_euler[2 if 'Arm' in name else 0]=math.radians(angle)
bpy.context.view_layer.update();posed=coords();dist=[(p-q).length for p,q in zip(rest,posed)]
report={'triangles':sum(len(p.vertices)-2 for p in m.data.polygons),'bones':len(a.data.bones),'vertices':len(m.data.vertices),'trimmed_weight_vertices':trimmed,'max_influences':max(len([g for g in v.groups if g.weight>1e-6]) for v in m.data.vertices),'pose_test':{'moved_vertices':sum(d>1e-5 for d in dist),'maximum_displacement':max(dist),'finite':all(math.isfinite(c) for p in posed for c in p)}}
cam.location=(0,-4,.50);cam.rotation_euler=(Vector((0,0,.50))-cam.location).to_track_quat('-Z','Y').to_euler();scene.render.filepath=str(out/'textured_pose.png');bpy.ops.render.render(write_still=True)
for bone in a.pose.bones:bone.rotation_euler=(0,0,0)
bpy.context.view_layer.update();bpy.ops.object.select_all(action='DESELECT');m.select_set(True);a.select_set(True);bpy.context.view_layer.objects.active=a
bpy.ops.export_scene.gltf(filepath=str(out/'player_01_textured.glb'),export_format='GLB',use_selection=True,export_animations=False)
bpy.ops.export_scene.fbx(filepath=str(out/'player_01_textured.fbx'),use_selection=True,object_types={'ARMATURE','MESH'},add_leaf_bones=False,bake_anim=False,path_mode='COPY',embed_textures=True)
bpy.ops.wm.save_as_mainfile(filepath=str(out/'player_01_textured.blend'))
(out/'model_verification.json').write_text(json.dumps(report,indent=2))
print('VERIFICATION',json.dumps(report))
