import bpy,pathlib,json,math
from mathutils import Vector
out=pathlib.Path(__file__).parent;ready=out/'READY_TO_IMPORT';ready.mkdir(exist_ok=True);review=out/'REVIEW';review.mkdir(exist_ok=True)
recipes=json.loads((out/'recipes.json').read_text());bpy.ops.wm.open_mainfile(filepath=str(out/'prepared_geometry.blend'))
scene=bpy.context.scene;scene.name='PlayerRoster_Batch_20261104';scene.render.engine='CYCLES';scene.cycles.samples=12
scene.render.resolution_x=600;scene.render.resolution_y=700;scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG';scene.view_settings.view_transform='Standard';scene.view_settings.look='None';scene.view_settings.exposure=-.5
scene.world.use_nodes=True;bg=next(n for n in scene.world.node_tree.nodes if n.type=='BACKGROUND');bg.inputs[0].default_value=(.8,.8,.8,1);bg.inputs[1].default_value=.6
bpy.ops.object.camera_add();camera=bpy.context.object;camera.data.type='ORTHO';scene.camera=camera
lights=[]
for _ in range(3):
    bpy.ops.object.light_add(type='AREA');lights.append(bpy.context.object)
for o in scene.objects:
    if o.type=='MESH':o.hide_render=True
report=[];export_objects=[]
for idx,rec in enumerate(recipes):
    m=bpy.data.objects[rec['id']];arm=bpy.data.objects[rec['id']+'_Rig'];m.hide_render=False;m.hide_set(False)
    mat=bpy.data.materials.new(rec['id']+'_ReferenceColor');mat.use_nodes=True
    bsdf=next(n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED');bsdf.inputs['Roughness'].default_value=.78
    image=bpy.data.images.load(str(out/(rec['id']+'_basecolor.png')));image.pack();tex=mat.node_tree.nodes.new('ShaderNodeTexImage');tex.image=image
    mat.node_tree.links.new(tex.outputs['Color'],bsdf.inputs['Base Color']);m.data.materials.clear();m.data.materials.append(mat)
    points=[m.matrix_world@v.co for v in m.data.vertices];lo=Vector(tuple(min(v[i] for v in points) for i in range(3)));hi=Vector(tuple(max(v[i] for v in points) for i in range(3)));center=(lo+hi)/2;height=hi.z-lo.z
    camera.location=center+Vector((0,-4*height,0));camera.rotation_euler=(center-camera.location).to_track_quat('-Z','Y').to_euler();camera.data.ortho_scale=max(height*1.18*600/700,(hi.x-lo.x)*1.10)
    for l,offset,power in zip(lights,[(-2,-3,4),(2,-2,2),(0,2,3)],[220,120,150]):
        l.location=center+Vector(offset)*height;l.data.energy=power*height*height;l.data.size=3*height;l.rotation_euler=(center-l.location).to_track_quat('-Z','Y').to_euler()
    scene.render.filepath=str(review/(rec['id']+'_front.png'));bpy.ops.render.render(write_still=True)
    def coordinates():
        ev=m.evaluated_get(bpy.context.evaluated_depsgraph_get());me=ev.to_mesh();pts=[v.co.copy() for v in me.vertices];ev.to_mesh_clear();return pts
    rest=coordinates()
    for name,angle in [('LeftArm',30),('LeftForeArm',35),('RightUpLeg',20),('RightLeg',25)]:
        bone=arm.pose.bones.get(name)
        if bone:bone.rotation_mode='XYZ';bone.rotation_euler[0]=math.radians(angle)
    bpy.context.view_layer.update();posed=coordinates();dist=[(p-q).length for p,q in zip(rest,posed)]
    pose={'moved_vertices':sum(d>1e-5 for d in dist),'max_displacement_source_units':max(dist),'finite':all(math.isfinite(c) for p in posed for c in p)}
    for bone in arm.pose.bones:bone.rotation_euler=(0,0,0)
    bpy.context.view_layer.update()
    # A root keeps each complete skeleton and uniform scale together.
    root=bpy.data.objects.new(rec['id']+'_PreviewRoot',None);scene.collection.objects.link(root)
    for o in [arm,m]:
        if o.parent is None:
            world=o.matrix_world.copy();o.parent=root;o.matrix_world=world
    factor=rec['height']/height;root.scale=(factor,)*3
    root.location=Vector((-center.x*factor,-center.y*factor,-lo.z*factor));bpy.context.view_layer.update()
    bpy.ops.object.select_all(action='DESELECT')
    for o in [root,arm,m]:o.hide_set(False);o.select_set(True)
    bpy.context.view_layer.objects.active=arm
    bpy.ops.export_scene.gltf(filepath=str(ready/(rec['id']+'.glb')),export_format='GLB',use_selection=True,export_animations=False)
    root.location.x+=(idx%7)*10;root.location.y+=(idx//7)*14
    export_objects.extend([root,arm,m]);m.hide_render=True
    report.append({'id':rec['id'],'height_studs':rec['height'],'pose_test':pose,'texture':rec['id']+'_basecolor.png','file':'READY_TO_IMPORT/'+rec['id']+'.glb'})
    print('EXPORTED',rec['id'],flush=True)
bpy.ops.object.select_all(action='DESELECT')
for o in export_objects:o.hide_render=False;o.hide_set(False);o.select_set(True)
bpy.ops.export_scene.gltf(filepath=str(ready/'Players_02_to_14.glb'),export_format='GLB',use_selection=True,export_animations=False)
bpy.ops.wm.save_as_mainfile(filepath=str(out/'textured_roster.blend'))
(out/'model_verification.json').write_text(json.dumps(report,indent=2))
print('ROSTER_READY',flush=True)
