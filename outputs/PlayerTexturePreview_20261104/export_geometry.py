import bpy, numpy as np, pathlib
out=pathlib.Path(r'C:\Users\User\steal_a_football_goat\outputs\PlayerTexturePreview_20261104')
bpy.ops.wm.open_mainfile(filepath=str(out/'working.blend'))
m=next(o for o in bpy.context.scene.objects if o.type=='MESH')
m.data.calc_loop_triangles()
np.savez(out/'geometry.npz',
    vertices=np.array([v.co[:] for v in m.data.vertices]),
    triangles=np.array([t.vertices[:] for t in m.data.loop_triangles]),
    uvs=np.array([[m.data.uv_layers.active.data[i].uv[:] for i in t.loops] for t in m.data.loop_triangles]),
    normals=np.array([[m.data.vertices[i].normal[:] for i in t.vertices] for t in m.data.loop_triangles]))
print('Geometry exported',len(m.data.loop_triangles))
