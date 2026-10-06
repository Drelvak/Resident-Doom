#!/usr/bin/env python3
"""Convert the six original IVM menu models; original 64-step intro rotation.
Camera basis C=(-x,-z,-y), focal length192, center112,76 are from MainMenu.
"""
from pathlib import Path
import struct,json,math
import numpy as np
from PIL import Image
from re1_model_math import rotation,apply_vertices
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'mod/models/items';OUT.mkdir(parents=True,exist_ok=True)
def md3(name,points,uv,triangles,frames,skin):
 n=len(points);nt=len(triangles);nf=len(frames);ot=108;os=ot+nt*12;ost=os+68;ox=ost+n*8;end=ox+nf*n*8
 surf=bytearray(struct.pack('<4s64s10i',b'IDP3',b'original_item',0,nf,1,n,nt,ot,os,ost,ox,end));surf.extend(b''.join(struct.pack('<3i',*t) for t in triangles));surf.extend(struct.pack('<64si',skin.encode(),0));surf.extend(b''.join(struct.pack('<2f',*t) for t in uv))
 for frame in frames:
  for v in frame:surf.extend(struct.pack('<3hH',*(np.clip(np.round(v*64),-32768,32767).astype(int)),0))
 of=108;ot=of+nf*56;end=ot+len(surf);blob=bytearray(struct.pack('<4si64s9i',b'IDP3',15,name.encode(),0,nf,0,1,0,of,ot,ot,end))
 for i in range(nf):blob.extend(struct.pack('<10f16s',-256,-256,-256,256,256,256,0,0,0,444,('step%d'%i).encode()))
 blob.extend(surf);(OUT/(name+'.md3')).write_bytes(blob)
manifest=[];defs='';zs='class REItemView : Actor { Default { +NOBLOCKMAP +NOGRAVITY +NOINTERACTION +NOTIMEFREEZE RenderStyle "Normal"; } States {\nSpawn: TNT1 A -1; Stop;\n'
for i in range(65):zs+='View%d: I%03d A -1 Bright; Stop;\n'%(i,i)
zs+='} }\n'
for item,file in [(2,'I00V'),(3,'I02V'),(47,'I56V'),(11,'I26V'),(12,'I16V'),(0x33,'I30V'),(0x44,'I64V'),(0x47,'I67V'),(0x4a,'I71V')]:
 b=(ROOT/'assets/reference/USA/Item_m2'/(file+'.IVM')).read_bytes();clen=struct.unpack_from('<I',b,8)[0];p=8+clen;w,h=struct.unpack_from('<2H',b,p+8);base=p+struct.unpack_from('<I',b,p)[0];pal=np.frombuffer(b,dtype='<u2',count=256,offset=20);raw=np.frombuffer(b,dtype=np.uint8,count=w*2*h,offset=p+12).reshape(h,w*2);v=pal[raw];rgba=np.stack(((v&31)*255//31,((v>>5)&31)*255//31,((v>>10)&31)*255//31,np.where(raw==0,0,255)),axis=-1).astype('uint8');rgba=np.concatenate((rgba,np.full((1,w*2,4),(11,11,11,255),dtype=np.uint8)));Image.fromarray(rgba).save(OUT/(file+'.png'))
 assert struct.unpack_from('<3I',b,base)==(65,0,1)
 vp,nv,np_,nn,pp,nprim,_=struct.unpack_from('<7I',b,base+12);verts=np.array([struct.unpack_from('<3h',b,base+12+vp+i*8) for i in range(nv)],float);pos=base+12+pp;points=[];uv=[];triangles=[]
 for n in range(nprim):
  _,ilen,flags,mode=struct.unpack_from('<4B',b,pos);assert mode in (0x30,0x34,0x3c);q=pos+4;start=len(points);num=4 if mode==0x3c else 3
  for j in range(num):
   u,v=struct.unpack_from('<2B',b,q+j*4) if mode!=0x30 else (0,h);vi=struct.unpack_from('<H',b,q+(num*4 if mode!=0x30 else 4)+2+j*4)[0];points.append(verts[vi]);uv.append(((u+.5)/(w*2),(v+.5)/(h+1)))

  for tri in [(0,1,2)]+([(1,3,2)] if num==4 else []):
   t=tuple(start+k for k in tri);triangles.extend([t,t[::-1]])
  pos+=4+ilen*4
 points=np.array(points);frames=[]
 for step in range(65):
  # Entry0 before the intro; entry64 reaches identity (three yaw/two roll turns).
  r=rotation((0,step*0xc0,step*0x80));v=apply_vertices(r,points);v=np.stack((-v[:,0],-v[:,2],-v[:,1]),axis=1)*56/1800;frames.append(v)
 md3(file,points,uv,triangles,frames,'models/items/'+file+'.png')
 cls='REItemView%d'%item;prefix={2:'H',3:'S',47:'B',11:'M',12:'L',51:'K',68:'G',71:'T',74:'U'}[item];zs+='class '+cls+' : REItemView { States {\n'+''.join('View%d: %s%03d A -1 Bright; Stop;\n'%(i,prefix,i) for i in range(65))+'} }\n';defs+='Model '+cls+' { Path "models/items" Model 0 "'+file+'.md3" Skin 0 "'+file+'.png" Scale 1 1 1 UseActorPitch UseActorRoll NoInterpolation\n'
 for i in range(65):defs+='FrameIndex %s%03d A 0 %d\n'%(prefix,i,i)
 defs+='}\n';manifest.append(dict(item=item,file=file,triangles=nprim,vertices=nv,intro_steps=64))
# Black backdrop is the original viewer's black rectangle, implemented as a model
# behind the isolated camera; it does not alter any E1M1 map lump.
points=np.array([(0,-256,-256),(0,256,-256),(0,256,256),(0,-256,256)],float)
md3('black',points,[(0,0)]*4,[(0,1,2),(2,1,0),(0,2,3),(3,2,0)],[points],'models/items/black.png');Image.new('RGBA',(1,1),(0,0,0,255)).save(OUT/'black.png')
zs+='class REViewBackdrop : Actor { Default { +NOBLOCKMAP +NOGRAVITY +NOINTERACTION +NOTIMEFREEZE } States { Spawn: IVBK A -1 Bright; Stop; } }\n'
defs+='Model REViewBackdrop { Path "models/items" Model 0 "black.md3" Skin 0 "black.png" Scale 16 16 16 FrameIndex IVBK A 0 0 }\n'
zs+='class REMenuCamera : Actor { Default { +NOBLOCKMAP +NOGRAVITY +NOINTERACTION +NOTIMEFREEZE RenderStyle "None"; } States { Spawn: TNT1 A -1; Stop; } }\n'
(ROOT/'mod/item_views.zs').write_text(zs);(ROOT/'mod/item_views.modeldef').write_text(defs);(ROOT/'assets/item-view-manifest.json').write_text(json.dumps(manifest,indent=2))
print('Converted six original IVM models, 65 frames each, native camera focal length192.')
