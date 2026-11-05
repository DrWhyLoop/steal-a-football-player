import bpy,json,pathlib
from mathutils import Vector
out=pathlib.Path(r'C:\Users\User\steal_a_football_goat\outputs\PlayerTexturePreview_20261104')
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=r'C:\Users\User\steal_a_football_goat\player_models\lionel_messi.glb')
m=next(o for o in bpy.context.scene.objects if o.type=='MESH'); a=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE')
print('MESH_INFO',json.dumps({'mesh':m.name,'dimensions':list(m.dimensions),'bounds':[list(min(v.co[i] for v in m.data.vertices) for i in range(3)),list(max(v.co[i] for v in m.data.vertices) for i in range(3))],'matrix':[list(r) for r in m.matrix_world],'uv':[(u.name,len(u.data)) for u in m.data.uv_layers],'bones':[(b.name,list(b.head_local),list(b.tail_local)) for b in a.data.bones]}))
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=8;scene.render.resolution_x=1100;scene.render.resolution_y=900;scene.render.resolution_percentage=100
scene.world.use_nodes=True; bg=next(n for n in scene.world.node_tree.nodes if n.type=='BACKGROUND');bg.inputs[0].default_value=(.8,.8,.8,1);bg.inputs[1].default_value=.6
points=[m.matrix_world@v.co for v in m.data.vertices];c=Vector(tuple((min(v[i] for v in points)+max(v[i] for v in points))/2 for i in range(3)))
bpy.ops.object.camera_add(location=c+Vector((0,-5,.0)));cam=bpy.context.object;cam.rotation_euler=(c-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=max(m.dimensions)*1.12;scene.camera=cam
for loc,power in [((-2,-3,4),250),((2,-2,2),180)]:
 bpy.ops.object.light_add(type='AREA',location=loc);l=bpy.context.object;l.data.energy=power;l.data.size=3;l.rotation_euler=(c-l.location).to_track_quat('-Z','Y').to_euler()
scene.render.image_settings.file_format='PNG';scene.render.filepath=str(out/'untextured_front.png');bpy.ops.render.render(write_still=True)
bpy.ops.wm.save_as_mainfile(filepath=str(out/'working.blend'))
