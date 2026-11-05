"""Texture supplied rigs from front references, with estimated rear colors."""
import pathlib,json,numpy as np
from PIL import Image
from scipy.ndimage import distance_transform_edt,map_coordinates
out=pathlib.Path(__file__).parent;root=out.parent.parent
recipes=json.loads((out/'recipes.json').read_text());reports=[];size=2048
for rec in recipes:
    d=np.load(out/(rec['id']+'_geometry.npz'));vertices=d['vertices'];triangles=d['triangles'];uvs=d['uvs'];normals=d['normals']
    lo3=vertices.min(0);hi3=vertices.max(0);height=hi3[2]-lo3[2]
    positions=np.zeros((size,size,3),dtype=np.float32);normal_y=np.zeros((size,size),dtype=np.float32);coverage=np.zeros((size,size),dtype=np.uint8)
    for tri,uv,n in zip(triangles,uvs,normals):
        q=uv*np.array([size-1,-(size-1)])+np.array([0,size-1]);lo=np.maximum(np.floor(q.min(0)).astype(int),0);hi=np.minimum(np.ceil(q.max(0)).astype(int),size-1)
        if np.any(hi<lo):continue
        xx,yy=np.meshgrid(np.arange(lo[0],hi[0]+1),np.arange(lo[1],hi[1]+1))
        den=(q[1,1]-q[2,1])*(q[0,0]-q[2,0])+(q[2,0]-q[1,0])*(q[0,1]-q[2,1])
        if abs(den)<1e-8:continue
        a=((q[1,1]-q[2,1])*(xx-q[2,0])+(q[2,0]-q[1,0])*(yy-q[2,1]))/den
        b=((q[2,1]-q[0,1])*(xx-q[2,0])+(q[0,0]-q[2,0])*(yy-q[2,1]))/den;c=1-a-b
        inside=(a>=-1e-6)&(b>=-1e-6)&(c>=-1e-6);x=xx[inside];y=yy[inside]
        positions[y,x]=a[inside,None]*vertices[tri[0]]+b[inside,None]*vertices[tri[1]]+c[inside,None]*vertices[tri[2]]
        normal_y[y,x]=a[inside]*n[0,1]+b[inside]*n[1,1]+c[inside]*n[2,1];coverage[y,x]+=1
    mask=coverage>0;p=positions[mask];x=(p[:,0]-(lo3[0]+hi3[0])/2)/height;y=(p[:,1]-(lo3[1]+hi3[1])/2)/height;z=(p[:,2]-lo3[2])/height
    ref=np.asarray(Image.open(root/'player_images'/rec['reference']).convert('RGB'),dtype=np.float32)/255
    ih,iw=ref.shape[:2];lum=ref.mean(2);sat=ref.max(2)-ref.min(2);fg=(sat>.13)|(lum<.42);fg[:int(ih*.025)]=False;fg[int(ih*.99):]=False
    fy,fx=np.where(fg);left,right,top,bottom=int(fx.min()),int(fx.max()),int(fy.min()),int(fy.max())
    u=left+(p[:,0]-lo3[0])/(hi3[0]-lo3[0])*(right-left);v=bottom-z*(bottom-top)
    sample=np.stack([map_coordinates(ref[:,:,i],[v,u],order=1,mode='nearest') for i in range(3)],axis=1)
    skin_color=np.array(rec['skin'])/255;hair_color=np.array(rec['hair'])/255
    fallback=np.tile(skin_color,(len(p),1))
    # Read the waist transition from the reference instead of assuming identical kits.
    cx=int((left+right)/2);ph=bottom-top
    waist_rows=np.arange(int(bottom-.58*ph),int(bottom-.43*ph))
    waist_rgb=np.median(ref[waist_rows,cx-10:cx+11],axis=1)
    pants_color=np.array(rec['shorts'])/255;shirt_color=np.array(rec['shirt'])/255
    pants_rows=np.linalg.norm(waist_rgb-pants_color,axis=1)<np.linalg.norm(waist_rgb-shirt_color,axis=1)
    waist=(bottom-waist_rows[pants_rows].min())/ph if pants_rows.any() else .49
    short_hem={'Player_03':.357,'Player_09':.357,'Player_06':.35}.get(rec['id'],.327)
    shirt=(z>=waist)&(z<.824)&(abs(x)<.210);fallback[shirt]=shirt_color
    if rec.get('stripes'):
        blue=(np.floor((x+.020)/.040).astype(int)%2)==0
        fallback[shirt]=np.where(blue[shirt,None],np.array(rec['shirt'])/255,np.array([.87,.89,.88]))
    shorts=(z>=short_hem)&(z<waist);fallback[shorts]=pants_color
    socks=(z>=.071)&(z<rec.get('sock_top',.249));fallback[socks]=np.array(rec['socks'])/255
    boots=z<.071;fallback[boots]=np.array(rec['boots'])/255
    hair=(z>.957)|((z>rec['hair_back'])&(y>.018))|((z>.927)&(abs(x)>.045))
    if rec.get('bald'):hair=((z>.946)&(y>.024)&(abs(x)>.027))
    fallback[hair]=hair_color
    w=np.clip((-normal_y[mask]-.02)/.60,0,1);w=w*w*(3-2*w)
    colors=fallback*(1-w[:,None])+sample*w[:,None]
    bright=sample.min(1)>.78
    dark_bad=(hair&bright)|(boots&bright)
    if np.mean(rec['shorts'])<85:dark_bad|=shorts&(sample.mean(1)>.50)
    if np.mean(rec['socks'])<85:dark_bad|=socks&(sample.mean(1)>.65)
    skin=~(shirt|shorts|socks|boots|hair);colors[dark_bad]=fallback[dark_bad];colors[skin&bright]=fallback[skin&bright]
    texture=np.zeros((size,size,3),dtype=np.float32);texture[mask]=colors
    distance,indices=distance_transform_edt(~mask,return_indices=True);pad=(~mask)&(distance<=12)
    texture[pad]=texture[indices[0][pad],indices[1][pad]];texture[distance>12]=[.15,.15,.15]
    Image.fromarray(np.uint8(np.clip(texture,0,1)*255)).save(out/(rec['id']+'_basecolor.png'))
    reports.append({'id':rec['id'],'reference':rec['reference'],'image_bounds':[left,top,right,bottom],'texture_size':size,'occupied_texels':int(mask.sum()),'overlap_texels':int((coverage>1).sum()),'back':'Estimated matching colors'})
    print('TEXTURED',rec['id'],flush=True)
(out/'texture_verification.json').write_text(json.dumps(reports,indent=2))
