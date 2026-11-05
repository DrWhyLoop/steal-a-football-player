"""Front-reference projection with explicitly estimated side/back colors.

Works on a derived UV texture; never edits the supplied GLB or JPEG.
"""
import pathlib,json,numpy as np
from PIL import Image
from scipy.ndimage import distance_transform_edt, map_coordinates
out=pathlib.Path(__file__).parent
root=out.parent.parent
d=np.load(out/'geometry.npz'); vertices=d['vertices']; triangles=d['triangles']; uvs=d['uvs']; normals=d['normals']
size=2048
positions=np.zeros((size,size,3),dtype=np.float32)
normal_y=np.zeros((size,size),dtype=np.float32)
coverage=np.zeros((size,size),dtype=np.uint8)
for tri,uv,n in zip(triangles,uvs,normals):
    q=uv*np.array([size-1,-(size-1)])+np.array([0,size-1])
    lo=np.maximum(np.floor(q.min(axis=0)).astype(int),0)
    hi=np.minimum(np.ceil(q.max(axis=0)).astype(int),size-1)
    if np.any(hi<lo):continue
    x,y=np.meshgrid(np.arange(lo[0],hi[0]+1),np.arange(lo[1],hi[1]+1))
    den=(q[1,1]-q[2,1])*(q[0,0]-q[2,0])+(q[2,0]-q[1,0])*(q[0,1]-q[2,1])
    if abs(den)<1e-8:continue
    a=((q[1,1]-q[2,1])*(x-q[2,0])+(q[2,0]-q[1,0])*(y-q[2,1]))/den
    b=((q[2,1]-q[0,1])*(x-q[2,0])+(q[0,0]-q[2,0])*(y-q[2,1]))/den
    c=1-a-b; inside=(a>=-1e-6)&(b>=-1e-6)&(c>=-1e-6)
    xx=x[inside]; yy=y[inside]
    positions[yy,xx]=(a[inside,None]*vertices[tri[0]]+b[inside,None]*vertices[tri[1]]+c[inside,None]*vertices[tri[2]])
    normal_y[yy,xx]=a[inside]*n[0,1]+b[inside]*n[1,1]+c[inside]*n[2,1];coverage[yy,xx]+=1
mask=coverage>0
p=positions[mask];x,y,z=p.T
ref=np.asarray(Image.open(root/'player_images/Lionel Messi.jpeg').convert('RGB'),dtype=np.float32)/255
# Match the generated mesh's one-metre normalized bounds to the supplied T-pose.
u=704+x*735;v=753-z*720
sample=np.stack([map_coordinates(ref[:,:,i],[v,u],order=1,mode='nearest') for i in range(3)],axis=1)
fallback=np.tile([.70,.46,.35],(len(p),1))
shirt=(z>=.474)&(z<.824)&(abs(x)<.210)
blue=(np.floor((x+.020)/.040).astype(int)%2)==0
fallback[shirt]=np.where(blue[shirt,None],np.array([.32,.64,.77]),np.array([.87,.89,.88]))
shorts=(z>=.302)&(z<.474);fallback[shorts]=[.075,.079,.078]
socks=(z>=.071)&(z<.249);fallback[socks]=[.82,.85,.86]
boots=z<.071;fallback[boots]=[.10,.23,.36]
# Hair wraps over the crown and rear of the head; rear-face detail is not invented.
hair=(z>.957)|((z>.900)&(y>.018))|((z>.927)&(abs(x)>.045))
fallback[hair]=[.105,.073,.052]
# Use reference detail predominantly on forward-facing surfaces, fade at the sides.
w=np.clip((-normal_y[mask]-.02)/.60,0,1)
w=w*w*(3-2*w)
colors=fallback*(1-w[:,None])+sample*w[:,None]
# Projection can reach white background where generated geometry protrudes beyond
# the source silhouette. Reject those samples in regions known to be dark/skin.
bright=sample.min(axis=1)>.78
dark_bad=(shorts&(sample.mean(axis=1)>.36))|(hair&bright)|(boots&bright)
skin=(~(shirt|shorts|socks|boots|hair))
colors[dark_bad]=fallback[dark_bad]
colors[skin&bright]=fallback[skin&bright]
texture=np.zeros((size,size,3),dtype=np.float32);texture[mask]=colors
# Pad islands to prevent black seams under mipmaps.
distance,indices=distance_transform_edt(~mask,return_indices=True)
pad=(~mask)&(distance<=12)
texture[pad]=texture[indices[0][pad],indices[1][pad]]
texture[distance>12]=[.15,.15,.15]
Image.fromarray(np.uint8(np.clip(texture,0,1)*255)).save(out/'player_01_basecolor.png')
report={'texture_size':[size,size],'occupied_texels':int(mask.sum()),'overlapping_texels':int((coverage>1).sum()),'reference':'player_images/Lionel Messi.jpeg','projection':{'center_x':704,'ground_y':753,'pixels_per_x':735,'pixels_per_z':720},'back_and_sides':'Estimated matching colors; no back reference supplied'}
(out/'texture_report.json').write_text(json.dumps(report,indent=2))
print(json.dumps(report))
