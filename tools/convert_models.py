#!/usr/bin/env python3
"""Original Jill body/W10/W12 banks, joint-14 replacement and RE1 RotMatrix.
Geometry is baked from original skeletal frames; no added gun or guessed pose.
"""
from pathlib import Path
import struct,json,math
import numpy as np
from PIL import Image
ROOT=Path(__file__).resolve().parents[1];REF=ROOT/'assets/reference/USA';OUT=ROOT/'mod/models/jill'
u16=lambda b,o:struct.unpack_from('<H',b,o)[0];u32=lambda b,o:struct.unpack_from('<I',b,o)[0]
emd=(REF/'Enemy/CHAR11.EMD').read_bytes();w12=(REF/'Players/W12.EMW').read_bytes();w10=(REF/'Players/W10.EMW').read_bytes();w13=(REF/'Players/W13.EMW').read_bytes()
_,emr,edd,tmd,tim=struct.unpack_from('<5I',emd,len(emd)-20)
clen=u32(emd,tim+8);cx,cy,cw,ch=struct.unpack_from('<4H',emd,tim+12);pal=np.frombuffer(emd,dtype='<u2',count=cw*ch,offset=tim+20).reshape(ch,cw)
p=tim+8+clen;ix,iy,iw,ih=struct.unpack_from('<4H',emd,p+4);raw=np.frombuffer(emd,dtype=np.uint8,count=iw*2*ih,offset=p+12).reshape(ih,iw*2)
atlas=Image.new('RGBA',(raw.shape[1],ih*ch))
for row in range(ch):
 v=pal[row][raw];rgba=np.stack(((v&31)*255//31,((v>>5)&31)*255//31,((v>>10)&31)*255//31,np.where(raw==0,0,255)),axis=-1).astype('uint8');atlas.paste(Image.fromarray(rgba),(0,row*ih))
atlas.save(OUT/'skin.png')
from re1_model_math import rotation,matrix_product,apply_lv,apply_vertices
a,fb,joints,stride=struct.unpack_from('<4H',emd,emr);assert joints==15
parents=[-1]*joints
for j in range(joints):
 count,off=struct.unpack_from('<2H',emd,emr+a+j*4)
 for child in emd[emr+a+off:emr+a+off+count]:parents[child]=j
translations=np.array([struct.unpack_from('<3h',emd,emr+8+j*6) for j in range(joints)],dtype=np.int64)
poses=[];manifest=[];frame_roots=[];frame_angles=[]
for bank,b,hdr,base,number in [('W12',w12,0,u32(w12,len(w12)-8),15),('W10',w10,0,u32(w10,len(w10)-8),5),('BODY',emd,emr,edd,15),('W13',w13,0,u32(w13,len(w13)-8),15)]:
 _,framebase,jn,st=struct.unpack_from('<4H',b,hdr);assert jn==joints
 for motion in range(number):
  count,off=struct.unpack_from('<2H',b,base+motion*4);off&=~3
  seq=[struct.unpack_from('<2H',b,base+off+i*4) for i in range(count)]
  manifest.append(dict(bank=bank,id=motion,first=len(poses),count=count,timings=[t&255 for _,t in seq]))
  for f,timing in seq:
   p=hdr+framebase+f*st;root=np.array(struct.unpack_from('<3h',b,p),dtype=np.int64)
   frame_roots.append(list(map(int,root)));frame_angles.append(list(struct.unpack_from('<%dh'%(joints*3),b,p+12)))
   rots=[rotation(struct.unpack_from('<3h',b,p+12+j*6)) for j in range(joints)];trs=translations.copy();trs[0]=root;cache={}
   def resolve(j):
    if j not in cache:
     par=parents[j]
     if par<0:cache[j]=(rots[j],trs[j])
     else:
      pr,pt=resolve(par);cache[j]=(matrix_product(pr,rots[j]),pt+apply_lv(pr,trs[j]))
    return cache[j]
   poses.append([resolve(j) for j in range(joints)])
def mesh(b,base,j):
 vp,nv,np_,nn,pp,nprim,_=struct.unpack_from('<7I',b,base+12+j*28)
 verts=np.array([struct.unpack_from('<3h',b,base+12+vp+i*8) for i in range(nv)],float)
 norms=np.array([struct.unpack_from('<3h',b,base+12+np_+i*8) for i in range(nn)],float)
 points=[];normal=[];uv=[];triangles=[];p=base+12+pp
 for n in range(nprim):
  olen,ilen,flg,mode=struct.unpack_from('<4B',b,p);assert mode&0xfc in (0x34,0x3c),(j,hex(mode));num=4 if mode&8 else 3;q=p+4;clut=u16(b,q+2);page=u16(b,q+6);row=max(0,min(ch-1,(clut>>6)-cy));start=len(points)
  for k in range(num):
   u,v=struct.unpack_from('<2B',b,q+k*4);ni,vi=struct.unpack_from('<2H',b,q+num*4+k*4);points.append(verts[vi]);normal.append(norms[ni]);uv.append(((u+(page&15)*128-ix*2+0.5)/raw.shape[1],(v+((page>>4)&1)*256-iy+row*ih+0.5)/(ih*ch)))
  for tri in [(0,1,2)]+([(1,3,2)] if num==4 else []):
   indices=tuple(start+i for i in tri);triangles.extend([indices,indices[::-1]])
  p+=4+ilen*4
 return np.array(points),np.array(normal),uv,triangles
body=[mesh(emd,tmd,j) for j in range(joints)];weapon=mesh(w12,u32(w12,len(w12)-4),0);shotgun=mesh(w13,u32(w13,len(w13)-4),0)
assert not np.array_equal(body[14][0],weapon[0])
def coord(v,scale):return np.stack((v[:,0],-v[:,2],-v[:,1]),axis=1)*scale
for armed,name in [(True,'jill.md3'),(False,'jill-unarmed.md3'),(True,'jill-shotgun.md3')]:
 surfaces=[];bounds=[];nf=len(poses)
 for j in range(joints):
  points,norms,uv,triangles=(shotgun if name=="jill-shotgun.md3" else weapon) if armed and j==14 else body[j];n=len(points);nt=len(triangles);ot=108;os=ot+nt*12;ost=os+68;ox=ost+n*8;end=ox+nf*n*8
  blob=bytearray(struct.pack('<4s64s10i',b'IDP3',('joint%d'%j).encode(),0,nf,1,n,nt,ot,os,ost,ox,end));blob.extend(b''.join(struct.pack('<3i',*t) for t in triangles));blob.extend(struct.pack('<64si',b'models/jill/skin.png',0));blob.extend(b''.join(struct.pack('<2f',*t) for t in uv))
  for pose in poses:
   r,t=pose[j];v=coord(apply_vertices(r,points)+t,56/1800);norm=coord(apply_vertices(r,norms),1);norm/=np.maximum(np.linalg.norm(norm,axis=1)[:,None],1)
   yaw=np.arctan2(norm[:,1],norm[:,0]);pitch=np.arccos(np.clip(norm[:,2],-1,1));enc=((np.round(pitch*255/math.tau).astype(int)&255)<<8)|(np.round(yaw*255/math.tau).astype(int)&255)
   for xyz,normal in zip(v,enc):blob.extend(struct.pack('<3hH',*(np.clip(np.round(xyz*64),-32768,32767).astype(int)),int(normal)))
  surfaces.append(blob)
 of=108;ot=of+nf*56;os=ot;end=os+sum(map(len,surfaces));blob=bytearray(struct.pack('<4si64s9i',b'IDP3',15,b'RE1 Jill',0,nf,0,joints,0,of,ot,os,end))
 for i in range(nf):blob.extend(struct.pack('<10f16s',-64,-64,-16,64,64,80,0,0,28,100,('pose%d'%i).encode()))
 for s in surfaces:blob.extend(s)
 (OUT/name).write_bytes(blob)
(ROOT/'assets/animation-manifest.json').write_text(json.dumps(manifest,indent=2))
(ROOT/'assets/model-fidelity.json').write_text(json.dumps(dict(frames=len(poses),joints=joints,parents=parents,weapon_joint=14,weapon_vertices=len(weapon[0]),weapon_source='Players/W12.EMW',rotation='GteRotationMatrixCalc(-x,y,-z), Q14 truncations -> Q12',animation='Live source Joint_move integer angle/root blends via original rigid joint parts; baked models retained for comparison.',limitation='Host Euler rotations cannot represent Q12 nonorthogonality exactly; see logs/joint-renderer-measurement.json. Reload physics joint15 not yet rendered.'),indent=2))
print('Original skeletal banks:',len(poses),'frames; joint14 replaced with actual W12 mesh,',len(weapon[0]),'face vertices.')
from joint_renderer_assets import export
export(ROOT,body,weapon,parents,translations,frame_roots,frame_angles,shotgun)
